{ lib
, stdenv
, fetchurl
, makeBinaryWrapper
, autoPatchelfHook
, procps
, ripgrep
, bubblewrap
, socat
}:

let
  version = "2.1.220";
  hash = "sha256-Z09h8g/zBvMQDPkgDkw2xLcCeLW+8ohFSYGblCqJyGM=";

  platform = {
    x86_64-linux = "linux-x64";
  }.${stdenv.hostPlatform.system} or (throw "Claude Code is only packaged locally for x86_64-linux");

  binary = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/${platform}/claude";
    inherit hash;
  };
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  dontUnpack = true;
  dontStrip = true; # Stripping corrupts Claude Code's embedded Bun trailer.

  nativeBuildInputs = [ makeBinaryWrapper ]
    ++ lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 ${binary} "$out/bin/.claude-unwrapped"
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
