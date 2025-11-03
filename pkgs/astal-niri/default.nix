{ lib
, stdenv
, meson
, ninja
, pkg-config
, gobject-introspection
, vala
, glib
, json-glib
, src
}:

stdenv.mkDerivation {
  pname = "astal-niri";
  version = "unstable-2025-10-29";

  # Source from flake input, subdirectory lib/niri
  src = "${src}/lib/niri";

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gobject-introspection
    vala
  ];

  buildInputs = [
    glib
    json-glib
  ];

  meta = with lib; {
    description = "Library and CLI tool for Niri IPC sockets";
    homepage = "https://github.com/sameoldlab/astal";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
