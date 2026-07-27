#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_FILE="$SCRIPT_DIR/../pkgs/claude-code.nix"
readonly RELEASES_URL="https://downloads.claude.ai/claude-code-releases"
readonly SIGNING_KEY_URL="https://downloads.claude.ai/keys/claude-code.asc"
readonly SIGNING_FINGERPRINT="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
readonly NPM_LATEST_URL="https://registry.npmjs.org/@anthropic-ai%2fclaude-code/latest"
readonly PLATFORM="linux-x64"

usage() {
  cat <<'EOF'
Usage: ./scripts/update-claude-code.sh [--version VERSION]

Pin the local Claude Code package to the npm latest release, or to VERSION.
The updater verifies Anthropic's signed release manifest before changing the
version and hash in pkgs/claude-code.nix.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

version_from_npm() {
  curl -fsSL "$NPM_LATEST_URL" | jq -er '.version'
}

verify_signing_key() {
  local gnupg_home="$1"

  curl -fsSL "$SIGNING_KEY_URL" | gpg --batch --homedir "$gnupg_home" --import >/dev/null

  local fingerprint
  fingerprint="$(gpg --batch --homedir "$gnupg_home" --with-colons --fingerprint security@anthropic.com | awk -F: '$1 == "fpr" { print $10; exit }')"
  if [ "$fingerprint" != "$SIGNING_FINGERPRINT" ]; then
    printf 'Unexpected Anthropic signing-key fingerprint: %s\n' "$fingerprint" >&2
    exit 1
  fi
}

verify_manifest() {
  local gnupg_home="$1"
  local manifest="$2"
  local signature="$3"

  gpg --batch --homedir "$gnupg_home" --verify "$signature" "$manifest" >/dev/null 2>&1
}

main() {
  local version=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --version)
        [ "$#" -ge 2 ] || { printf 'Missing value for --version\n' >&2; exit 1; }
        version="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  require_command curl
  require_command gpg
  require_command jq
  require_command nix
  require_command awk
  require_command sed
  require_command sha256sum

  version="${version:-$(version_from_npm)}"
  if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+){2}([-.][0-9A-Za-z.+-]+)?$ ]]; then
    printf 'Invalid Claude Code version: %s\n' "$version" >&2
    exit 1
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap "rm -rf -- $(printf '%q' "$temp_dir")" EXIT

  local gnupg_home="$temp_dir/gnupg"
  local manifest="$temp_dir/manifest.json"
  local signature="$temp_dir/manifest.json.sig"
  local binary="$temp_dir/claude"

  mkdir -m 700 "$gnupg_home"
  verify_signing_key "$gnupg_home"
  curl -fsSL "$RELEASES_URL/$version/manifest.json" -o "$manifest"
  curl -fsSL "$RELEASES_URL/$version/manifest.json.sig" -o "$signature"
  verify_manifest "$gnupg_home" "$manifest" "$signature"

  local expected_hash actual_hash nix_hash
  expected_hash="$(jq -er ".platforms[\"$PLATFORM\"].checksum" "$manifest")"
  curl -fsSL "$RELEASES_URL/$version/$PLATFORM/claude" -o "$binary"
  actual_hash="$(sha256sum "$binary" | awk '{ print $1 }')"
  if [ "$actual_hash" != "$expected_hash" ]; then
    printf 'Claude binary checksum mismatch\nExpected: %s\nActual:   %s\n' "$expected_hash" "$actual_hash" >&2
    exit 1
  fi
  nix_hash="$(nix hash file --type sha256 --sri "$binary")"

  sed -i \
    -e "s|^  version = \".*\";|  version = \"$version\";|" \
    -e "s|^  hash = \".*\";|  hash = \"$nix_hash\";|" \
    "$PACKAGE_FILE"

  printf 'Pinned Claude Code %s in %s\n' "$version" "$PACKAGE_FILE"
  printf 'Review with: git diff -- pkgs/claude-code.nix\n'
}

main "$@"
