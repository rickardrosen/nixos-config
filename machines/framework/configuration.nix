# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hibernation support
  boot.resumeDevice = "/dev/disk/by-uuid/9152d066-aff6-490f-b831-d727c26b82aa";
  boot.kernelParams = [ "resume_offset=5889077" ];

  # Swapfile configuration for hibernation (96GB for full RAM)
  swapDevices = [{
    device = "/swap/swapfile";
    size = 96 * 1024; # 96GB in MB
  }];

  networking.hostName = "framework"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    #console.keyMap = "sv-latin1";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;


  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # OR
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  services = {
    #udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;
    udev.extraRules = ''
      # Lock screen when YubiKey is removed
      ACTION=="remove", ENV{ID_VENDOR_ID}=="1050", ENV{ID_MODEL_ID}=="0407", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
    logind = {
      settings = {
        Login = {
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "lock";
        };
      };
    };
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      # Enable WirePlumber for session management
      wireplumber.enable = true;
    };
    # Disable power-profiles-daemon (pulled in by COSMIC) in favor of auto-cpufreq
    power-profiles-daemon.enable = false;
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "auto";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    gnome.gnome-keyring.enable = true;
    displayManager.ly.enable = true;
    desktopManager = {
      cosmic = {
        enable = true;
        xwayland.enable = true;
      };
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    config = {
      niri = {
        "org.freedesktop.impl.portal.FileChooser" = "cosmic-files";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security =  {
    polkit.enable = true;
    pam = {
      services = {
        swaylock = {
          u2fAuth = false;  # Disable U2F - use smart card PIN for security
          # Smart card (p11) authentication will be used (PIN-based)
        };
        ly = {
          unixAuth = lib.mkForce false;  # Disable password authentication
          u2fAuth = false;   # Disable U2F - use smart card PIN instead
          # Smart card (p11) authentication will be used (PIN-based)
        };
        sudo = {
          u2fAuth = true;  # Enable U2F touch for sudo (convenience)
        };
      };
      p11.enable = true;  # Keep smart card support (PIN-based)
      u2f = {
        enable = true;
        control = "sufficient";  # U2F or smart card works
        settings = {
          cue = true;  # Prompt to touch the YubiKey
          interactive = true;  # Wait for user before checking for authenticator
        };
      };
    };
    tpm2.enable = true;
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.rickard = {
    isNormalUser = true;
    extraGroups = [ "podman" "networkmanager" "wheel" ]; # Enable 'sudo' for the user.
    createHome = true;
    shell = pkgs.fish;
  };

  # programs.firefox.enable = true;
  programs = {
    hyprland.enable = true;
    hyprlock.enable = true;
    waybar.enable = true;
    fish.enable = true;
    starship.enable = true;
    niri.enable = true;
  };
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    helix # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    jq
    kitty
    google-chrome
    fuzzel
    swaylock
    swaynotificationcenter
    swayidle
    wlogout
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.plugin-git
    fzf
    fishPlugins.grc
    grc
    pavucontrol # PulseAudio Volume Control
    pamixer # Command-line mixer for PulseAudio
    bluez # Bluetooth support
    bluez-tools # Bluetooth tools
    bluetuith # Modern TUI Bluetooth manager
    code-cursor
    inotify-tools
    psmisc
    tpm2-tools
    tpm2-tss
    starship
    hyprshot
    hyprpaper
    hyprpanel
    hyprsunset
    sunsetr
    brightnessctl
    hyprshell
    wl-clipboard
    cliphist
    nodejs
    devenv
    # inputs.swww.packages.${pkgs.system}.swww  # Commented out - not using swww
    ghostty
    xwayland-satellite
    niriswitcher
    pwvucontrol
    pw-volume
    yubioath-flutter
    opensc
    yubico-piv-tool
    yubikey-manager
    gcalcli # Google Calendar CLI
    libnotify # Desktop notifications (provides notify-send)
    delta-shell # AGS v3 desktop shell
    #inputs.ghostty.packages.${pkgs.system}.default
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Fix headphone jack audio - disable auto-mute
  systemd.services.disable-audio-auto-mute = {
    description = "Disable audio auto-mute for headphone jack";
    wantedBy = [ "sound.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Auto-Mute Mode' 'Disabled'";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  nix = {
    settings = {
      trusted-users = [ "root" "rickard" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };
  };
  nixpkgs.config.allowUnfree = true;
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
  system.autoUpgrade = {
    enable = true;
    flake = "/home/rickard/repos/rickardrosen/nixos-config#framework";
    flags = [ "--update-input" "nixpkgs" ];
  };
}

