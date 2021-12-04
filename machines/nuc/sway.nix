{ config, pkgs, lib, ... }: {

  xdg.portal = {
    enable = true;
    gtkUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      autotiling
      flashfocus
      python3
      grim
      slurp
      sway-contrib.grimshot
      sway-contrib.inactive-windows-transparency
      #sway-unwrapped
      swaybg
      wofi
      wl-clipboard
      mako
      dmenu
      swaylock # lockscreen
      swayidle
      #xwayland # for legacy apps
      waybar # status bar
    ];
  };

  programs.waybar.enable = true;

}
