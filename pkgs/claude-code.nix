{ lib
, stdenv
, fetchurl
, makeBinaryWrapper
, gnutar
, autoPatchelfHook
, procps
, ripgrep
, bubblewrap
, socat
}:

let
  version = "2.1.229";
  hash = "sha512-YaENNcgyLJ8xjH1cdNTCAC7jLUzDTRISMQikArsvpBcEM32no6jmGgpVj61YQAOZedyUTLYxbKyq4TYGj7o2Vw==";

  platform = {
    x86_64-linux = "linux-x64";
  }.${stdenv.hostPlatform.system} or (throw "Claude Code is only packaged locally for x86_64-linux");

  binaryTarball = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${platform}/-/claude-code-${platform}-${version}.tgz";
    inherit hash;
  };
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  dontUnpack = true;
  dontStrip = true; # Stripping corrupts Claude Code's embedded Bun trailer.

  nativeBuildInputs = [ makeBinaryWrapper gnutar ]
    ++ lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    ${gnutar}/bin/tar -xzf ${binaryTarball} -C "$TMPDIR" package/claude
    install -m755 "$TMPDIR/package/claude" "$out/bin/.claude-unwrapped"
    makeBinaryWrapper "$out/bin/.claude-unwrapped" "$out/bin/claude" \
      --inherit-argv0 \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${lib.makeBinPath [ procps ripgrep bubblewrap socat ]}

    runHook postInstall
  '';

  meta = {
    description = "Claude Code AI coding assistant";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
