{ pkgs
, lib
, stdenv
, ags
, astal
, astal-niri
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
    makeWrapper
  ];

  buildInputs = (with pkgs; [
    glib
    gtk3
    gtk4
    gtk-layer-shell
    gtk4-layer-shell
    libsoup_3  # Required for HTTP requests

    # Optional dependencies
    dart-sass            # For stylesheet compilation
    gpu-screen-recorder  # For screen recording feature
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
  ]) ++ [
    # Niri support from community fork
    astal-niri
  ];

  # mesonFlags - meson already sets prefix automatically via stdenv
  # Don't set it manually to avoid conflicts

  # Ensure runtime dependencies are in PATH
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath ([
        ags  # Required for delta-shell commands
      ] ++ (with pkgs; [
        dart-sass
        gpu-screen-recorder
        cliphist
        wl-clipboard
        brightnessctl
      ]))}
    )
  '';

  meta = with lib; {
    description = "A desktop shell based on AGS v3, supports Hyprland and Niri";
    homepage = "https://github.com/Sinomor/delta-shell";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
