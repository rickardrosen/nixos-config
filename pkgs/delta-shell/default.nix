{ pkgs
, lib
, stdenv
, ags
, astal
, src
}:

stdenv.mkDerivation rec {
  pname = "delta-shell";
  version = "unstable-2025-10-29";

  # src is passed from flake.nix
  inherit src;

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    ags
    gjs
    gobject-introspection
    wrapGAppsHook
  ];

  buildInputs = (with pkgs; [
    glib
    gtk3
    gtk4
    gtk-layer-shell
    gtk4-layer-shell
    dart-sass

    # Optional dependencies
    cliphist
    wl-clipboard
    brightnessctl
    bluez
    geoclue2
  ]) ++ (with astal; [
    # All astal libraries required by delta-shell from flake input
    io
    astal3
    astal4
    apps
    battery
    bluetooth
    mpris
    network
    notifd
    powerprofiles
    tray
    wireplumber
    hyprland
    river
    # Note: astal-niri doesn't exist yet in astal flake
    # Delta-shell should fall back to detecting niri via other means
  ]);

  # mesonFlags - meson already sets prefix automatically via stdenv
  # Don't set it manually to avoid conflicts

  meta = with lib; {
    description = "A desktop shell based on AGS v3, supports Hyprland and Niri";
    homepage = "https://github.com/Sinomor/delta-shell";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
