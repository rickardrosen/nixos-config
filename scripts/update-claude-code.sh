#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_FILE="$SCRIPT_DIR/../pkgs/claude-code.nix"
readonly WRAPPER_LATEST_URL="https://registry.npmjs.org/@anthropic-ai%2fclaude-code/latest"
readonly PLATFORM_PACKAGE="@anthropic-ai/claude-code-linux-x64"
readonly PLATFORM_PACKAGE_URL_PREFIX="https://registry.npmjs.org/@anthropic-ai%2fclaude-code-linux-x64"

usage() {
  cat <<'EOF'
Usage: ./scripts/update-claude-code.sh [--version VERSION]

Pin the local Claude Code package to the npm latest release, or to VERSION.
The updater fetches the linux-x64 npm tarball metadata, verifies its integrity,
and then updates version and hash in pkgs/claude-code.nix.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

version_from_npm() {
  curl -fsSL "$WRAPPER_LATEST_URL" | jq -er '.version'
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
  require_command jq
  require_command nix
  require_command sed

  version="${version:-$(version_from_npm)}"
  if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+){2}([-.][0-9A-Za-z.+-]+)?$ ]]; then
    printf 'Invalid Claude Code version: %s\n' "$version" >&2
    exit 1
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap "rm -rf -- $(printf '%q' "$temp_dir")" EXIT

  local metadata="$temp_dir/platform-metadata.json"
  local tarball="$temp_dir/claude-code-linux-x64.tgz"

  curl -fsSL "$PLATFORM_PACKAGE_URL_PREFIX/$version" -o "$metadata"

  local metadata_version tarball_url expected_integrity
  metadata_version="$(jq -er '.version' "$metadata")"
  if [ "$metadata_version" != "$version" ]; then
    printf 'Unexpected %s version metadata: expected %s, got %s\n' "$PLATFORM_PACKAGE" "$version" "$metadata_version" >&2
    exit 1
  fi

  tarball_url="$(jq -er '.dist.tarball' "$metadata")"
  expected_integrity="$(jq -er '.dist.integrity' "$metadata")"

  local hash_algorithm actual_integrity
  hash_algorithm="${expected_integrity%%-*}"
  case "$hash_algorithm" in
    sha256|sha512) ;;
    *)
      printf 'Unsupported integrity algorithm in npm metadata: %s\n' "$hash_algorithm" >&2
      exit 1
      ;;
  esac

  curl -fsSL "$tarball_url" -o "$tarball"
  actual_integrity="$(nix hash file --type "$hash_algorithm" --sri "$tarball")"
  if [ "$actual_integrity" != "$expected_integrity" ]; then
    printf 'Claude npm tarball integrity mismatch\nExpected: %s\nActual:   %s\n' "$expected_integrity" "$actual_integrity" >&2
    exit 1
  fi

  sed -i \
    -e "s|^  version = \".*\";|  version = \"$version\";|" \
    -e "s|^  hash = \".*\";|  hash = \"$expected_integrity\";|" \
    "$PACKAGE_FILE"

  printf 'Pinned Claude Code %s in %s\n' "$version" "$PACKAGE_FILE"
  printf 'Tarball source: %s\n' "$tarball_url"
  printf 'Review with: git diff -- pkgs/claude-code.nix scripts/update-claude-code.sh\n'
}

main "$@"
