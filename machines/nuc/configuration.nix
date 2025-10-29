# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # nixos-hardware module is imported in root flake.nix
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelParams = [
  #      "video=3440x1440@100"
  #];
  boot.tmp.useTmpfs = true;
  #systemd.additionalUpstreamSystemUnits = [ "tmp.mount" ];
  systemd.mounts = [{
    where = "/tmp";
    what = "tmpfs";
    type = "tmpfs";
    options = "mode=1777,strictatime,rw,nosuid,nodev";
  }];

  hardware.bluetooth = {
   enable = true;
   settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };
  };
  services.blueman.enable = true;

  networking.hostName = "nuc"; # Define your hostname.
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  powerManagement.enable = false;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };

  location.latitude = 59.3293;
  location.longitude = 18.0686;
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      #unstable = import <nixpkgs-unstable> {
      #  config = config.nixpkgs.config;
      #};
    };
    permittedInsecurePackages = [
      "freeimage-unstable-2021-11-01"
    ];
  };

  environment.sessionVariables = rec {
   NIXOS_OZONE_WL = "1";
  };

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
  environment.systemPackages = with pkgs; [
    gcc
    wget
    unzip
    #old.chromium
    chromium
    vanilla-dmz
    neovim
    git
    fzf
    ripgrep
    zsh
    firefox
    tmux
    alacritty
    killall
    insomnia
    kitty
    starship
    pavucontrol
    jq
    imv
    slack
    copyq
    flameshot
    podman-compose
    nodejs
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.diagnostic-languageserver
    #(python3.withPackages(ps: with ps; [ i3ipc ]))
    terraform-ls
    #go-1.18.1
  ];

  virtualisation = {
   lxd.enable = true;
   podman = {
     enable = true;
     # Create a `docker` alias for podman, to use it as a drop-in replacement
     dockerCompat = true;
   };
  };

  #nixpkgs.config.chromium.commandLineArgs = "---ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,VaapiVideoDecoder,VaapiVideoEncoder";

  nixpkgs.overlays = [
  #(self: super: {
  #  slack = super.slack.overrideAttrs (old: {
  #    installPhase = old.installPhase + ''
  #    rm $out/bin/slack

  #    makeWrapper $out/lib/slack/slack $out/bin/slack \
  #      --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
  #      --prefix PATH : ${lib.makeBinPath [pkgs.xdg-utils]} \
  #      --add-flags "---ozone-platform=wayland -enable-features=UseOzonePlatform, WebRTCPipeWireCapturer"
  #    '';
  #  });
  #})
  (self: super: {
   chromium = super.chromium.override {
     commandLineArgs =
       "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,VaapiVideoDecoder,VaapiVideoEncoder --ozone-platform=wayland";
     };
  })
  #(self: super: {
  #  insomnia = super.insomnia.overrideAttrs (old: {
  #    preFixup = old.preFixup + ''
  #      rm $out/bin/insomnia
  #      wrapProgram $out/bin/insomnia \
  #        --prefix LD_LIBRARY_PATH : ${runtimeLibs} \
  #        --add-flags "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
  #      '';
  #  });
  #})
  ];

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings = {
        screencast = {
          max_fps = 30; 
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        };
      };
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal
    ];
    #gtkUsePortal = true;
  };
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      autotiling
      #flashfocus
      grim
      slurp
      sway-contrib.grimshot
      sway-contrib.inactive-windows-transparency
      #sway-unwrapped
      swaybg
      wofi
      wl-clipboard
      dmenu
      swaylock
      swaylock-fancy
      swayidle
      swaycwd
      waybar
      mako
      wlsunset
      swappy
      pngquant
      clipman
      xdg-utils
    ];
  };
  programs.waybar.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  services.fstrim.enable = true;
  services.ratbagd.enable = true;
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    #config.pipewire = {
    #  "context.properties" = {
    #    #"link.max-buffers" = 64;
    #    "link.max-buffers" = 16; # version < 3 clients can't handle more than this
    #    "default.clock.rate" = 48000;
    #    "default.clock.quantum" = 1024;
    #    "default.clock.min-quantum" = 32;
    #    "default.clock.max-quantum" = 8192;    
    #    "core.daemon" = true;
    #    "core.name" = "pipewire-0";
    #  };
    #  "context.modules" = [
    #    {
    #      name = "libpipewire-module-rtkit";
    #      args = {
    #        "nice.level" = -15;
    #        "rt.prio" = 88;
    #        "rt.time.soft" = 200000;
    #        "rt.time.hard" = 200000;
    #      };
    #      flags = [ "ifexists" "nofail" ];
    #    }
    #    { name = "libpipewire-module-protocol-native"; }
    #    { name = "libpipewire-module-profiler"; }
    #    { name = "libpipewire-module-metadata"; }
    #    { name = "libpipewire-module-spa-device-factory"; }
    #    { name = "libpipewire-module-spa-node-factory"; }
    #    { name = "libpipewire-module-client-node"; }
    #    { name = "libpipewire-module-client-device"; }
    #    {
    #      name = "libpipewire-module-portal";
    #      flags = [ "ifexists" "nofail" ];
    #    }
    #    {
    #      name = "libpipewire-module-access";
    #      args = {};
    #    }
    #    { name = "libpipewire-module-adapter"; }
    #    { name = "libpipewire-module-link-factory"; }
    #    { name = "libpipewire-module-session-manager"; }
    #  ];
    #};
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #media-session.config.bluez-monitor.rules = [
    #  {
    #    # Matches all cards
    #    matches = [{ "device.name" = "~bluez_card.*"; }];
    #    actions = {
    #      "update-props" = {
    #        "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
    #        # mSBC is not expected to work on all headset + adapter combinations.
    #        "bluez5.msbc-support" = true;
    #        # SBC-XQ is not expected to work on all headset + adapter combinations.
    #        "bluez5.sbc-xq-support" = true;
    #      };
    #    };
    #  }
    #  {
    #    matches = [
    #      # Matches all sources
    #      { "node.name" = "~bluez_input.*"; }
    #      # Matches all outputs
    #      { "node.name" = "~bluez_output.*"; }
    #    ];
    #    actions = {
    #      "node.pause-on-idle" = false;
    #    };
    #  }
    #];
  };
  programs.zsh.enable = true;
  programs.fish.enable = false;
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "Meslo" "Hack" ]; })
      corefonts		  # Microsoft free fonts
      fira	      	  # Monospace
      inconsolata     	  # Monospace
      powerline-fonts
      ubuntu_font_family
      unifont		  # International languages
      source-code-pro
      font-awesome
    ];
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  #virtualisation.docker.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;
  networking.networkmanager.enable = true;
  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  #hardware.opengl.enable = true;
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rickard = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "lxd"]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    %wheel	ALL=(ALL)	NOPASSWD:ALL
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.05"; # Did you read the comment?

}

