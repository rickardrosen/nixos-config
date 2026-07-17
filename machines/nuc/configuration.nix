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
  # Keep boot entries editable so we can append `systemd.debug-shell=1`
  # for recovery on headless/locked-root situations.
  boot.loader.systemd-boot.editor = true;
  # Keep several generations for easy rollback after large upgrades.
  boot.loader.systemd-boot.configurationLimit = 20;
  # Avoid getting stuck on an inaccessible sulogin prompt on this host.
  systemd.enableEmergencyMode = false;

  # Keep latest kernel on this host; stable kernel regressed disk discovery.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelParams = [
  #      "video=3440x1440@100"
  #];
  boot.tmp.useTmpfs = true;

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
  nix.settings = {
    trusted-users = [ "root" "rickard" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  location.latitude = 59.3293;
  location.longitude = 18.0686;
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
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
    typescript
    typescript-language-server
    diagnostic-languageserver
    #(python3.withPackages(ps: with ps; [ i3ipc ]))
    terraform-ls
    #go-1.18.1
  ];

  virtualisation = {
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
      nerd-fonts.meslo-lg
      nerd-fonts.hack
      corefonts		  # Microsoft free fonts
      fira	      	  # Monospace
      inconsolata     	  # Monospace
      powerline-fonts
      ubuntu-classic
      unifont		  # International languages
      source-code-pro
      font-awesome
    ];
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.matter-server = {
    enable = true;
    openFirewall = true;
    package = pkgs.python-matter-server.overridePythonAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace matter_server/server/helpers/paa_certificates.py \
          --replace-fail "except (ClientError, TimeoutError) as err:" "except (ClientError, TimeoutError, ValueError) as err:"

        python - <<'PY'
from pathlib import Path

path = Path("matter_server/server/helpers/paa_certificates.py")
source = path.read_text()

old = (
    "                if await write_paa_root_cert(\n"
    "                    paa_root_cert_dir,\n"
    "                    base_name,\n"
    "                    certificate,\n"
    "                    subject,\n"
    "                ):\n"
    "                    fetch_count += 1"
)

new = (
    "                try:\n"
    "                    if await write_paa_root_cert(\n"
    "                        paa_root_cert_dir,\n"
    "                        base_name,\n"
    "                        certificate,\n"
    "                        subject,\n"
    "                    ):\n"
    "                        fetch_count += 1\n"
    "                except ValueError as err:\n"
    "                    LOGGER.warning(\n"
    "                        \"Skipping malformed certificate from %s: %s\", url, err\n"
    "                    )"
)

if old not in source:
    raise RuntimeError("Expected certificate write block not found")

path.write_text(source.replace(old, new))
PY
      '';
    });
    extraArgs = {
      # Work around malformed certs occasionally served by DCL that crash
      # python-matter-server during PAA fetch at startup.
      paa-root-cert-dir = "/var/lib/matter-server/credentials/development/paa-root-certs";
      # Some devices still chain to certs that are only present in test-net DCL
      # or the upstream SDK cert bundle.
      enable-test-net-dcl = true;
    };
  };
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    customComponents = with pkgs.home-assistant-custom-components; [
      localtuya
    ];
    extraComponents = [
      "analytics"
      "default_config"
      "google_translate"
      "isal"
      "matter"
      "thread"
      "met"
      "shopping_list"
      "tuya"
    ];
    config = {
      default_config = { };

      homeassistant = {
        latitude = 59.322333;
        longitude = 17.989417;
        time_zone = "Europe/Stockholm";
        unit_system = "metric";
      };

      zone = [
        {
          name = "Home";
          latitude = 59.322333;
          longitude = 17.989417;
          radius = 500;
          icon = "mdi:home";
        }
      ];

      http = {
        server_host = "0.0.0.0";
      };

      input_select = {
        erv_mode = {
          name = "ERV Mode";
          options = [
            "Normal"
            "Boost"
            "Away"
            "Quiet"
          ];
          initial = "Normal";
          icon = "mdi:fan";
        };
      };

      script = {
        erv_apply_mode = {
          alias = "ERV Apply Mode";
          mode = "restart";
          sequence = [
            {
              choose = [
                {
                  conditions = [
                    {
                      condition = "state";
                      entity_id = "input_select.erv_mode";
                      state = "Boost";
                    }
                  ];
                  sequence = [
                    {
                      service = "select.select_option";
                      target = {
                        entity_id = [
                          "select.smart_erv_smart_erv_supply_air"
                          "select.smart_erv_smart_erv_exhaust_air"
                        ];
                      };
                      data.option = "Speed 8";
                    }
                  ];
                }
                {
                  conditions = [
                    {
                      condition = "state";
                      entity_id = "input_select.erv_mode";
                      state = "Normal";
                    }
                  ];
                  sequence = [
                    {
                      service = "select.select_option";
                      target = {
                        entity_id = [
                          "select.smart_erv_smart_erv_supply_air"
                          "select.smart_erv_smart_erv_exhaust_air"
                        ];
                      };
                      data.option = "Speed 10";
                    }
                  ];
                }
                {
                  conditions = [
                    {
                      condition = "state";
                      entity_id = "input_select.erv_mode";
                      state = "Quiet";
                    }
                  ];
                  sequence = [
                    {
                      service = "select.select_option";
                      target = {
                        entity_id = [
                          "select.smart_erv_smart_erv_supply_air"
                          "select.smart_erv_smart_erv_exhaust_air"
                        ];
                      };
                      data.option = "Speed 3";
                    }
                  ];
                }
              ];
              default = [
                {
                  service = "select.select_option";
                  target = {
                    entity_id = [
                      "select.smart_erv_smart_erv_supply_air"
                      "select.smart_erv_smart_erv_exhaust_air"
                    ];
                  };
                  data.option = "Speed 2";
                }
              ];
            }
          ];
        };
      };

      template = [
        {
          sensor = [
            {
              name = "ERV Indoor Reference Temperature";
              unique_id = "erv_indoor_reference_temperature";
              unit_of_measurement = "C";
              device_class = "temperature";
              availability = ''
                {{
                  has_value('sensor.alpstuga_air_quality_monitor_temperature')
                  and has_value('sensor.alpstuga_air_quality_monitor_temperature_2')
                }}
              '';
              state = ''
                {% set t1 = states('sensor.alpstuga_air_quality_monitor_temperature') | float %}
                {% set t2 = states('sensor.alpstuga_air_quality_monitor_temperature_2') | float %}
                {{ [t1, t2] | max }}
              '';
            }
          ];
        }
      ];

      sensor = [
        {
          platform = "filter";
          name = "ERV Indoor Reference Temperature Smoothed";
          unique_id = "erv_indoor_reference_temperature_smoothed";
          entity_id = "sensor.erv_indoor_reference_temperature";
          filters = [
            {
              filter = "time_simple_moving_average";
              window_size = "02:00";
              precision = 1;
            }
          ];
        }
      ];

      automation = [
        {
          id = "erv_apply_mode_on_change";
          alias = "ERV: Apply selected mode";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.erv_mode";
            }
          ];
          action = [
            {
              service = "script.turn_on";
              target.entity_id = "script.erv_apply_mode";
            }
          ];
        }
        {
          id = "erv_boost_on_poor_air";
          alias = "ERV: Boost on poor air";
          mode = "single";
          trigger = [
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide";
              above = 800;
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide_2";
              above = 800;
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5";
              above = 20;
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5_2";
              above = 20;
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity";
              above = 65;
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity_2";
              above = 65;
            }
          ];
          condition = [
            {
              condition = "not";
              conditions = [
                {
                  condition = "state";
                  entity_id = "input_select.erv_mode";
                  state = "Boost";
                }
              ];
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.erv_mode";
              data.option = "Boost";
            }
          ];
        }
        {
          id = "erv_recover_to_auto";
          alias = "ERV: Back to auto when air recovers";
          mode = "single";
          trigger = [
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide";
              below = 700;
              for = "00:15:00";
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide_2";
              below = 700;
              for = "00:15:00";
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5";
              below = 10;
              for = "00:15:00";
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5_2";
              below = 10;
              for = "00:15:00";
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity";
              below = 58;
              for = "00:15:00";
            }
            {
              platform = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity_2";
              below = 58;
              for = "00:15:00";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "input_select.erv_mode";
              state = "Boost";
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide";
              below = 700;
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_carbon_dioxide_2";
              below = 700;
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5";
              below = 10;
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_pm2_5_2";
              below = 10;
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity";
              below = 58;
            }
            {
              condition = "numeric_state";
              entity_id = "sensor.alpstuga_air_quality_monitor_humidity_2";
              below = 58;
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.erv_mode";
              data.option = "Normal";
            }
          ];
        }
        {
          id = "erv_boost_timeout";
          alias = "ERV: Boost timeout";
          mode = "single";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.erv_mode";
              to = "Boost";
              for = "00:45:00";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "input_select.erv_mode";
              state = "Boost";
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.erv_mode";
              data.option = "Normal";
            }
          ];
        }
        {
          id = "erv_away_when_empty";
          alias = "ERV: Set Away when nobody home";
          mode = "single";
          trigger = [
            {
              platform = "numeric_state";
              entity_id = "zone.home";
              below = 1;
              for = "00:15:00";
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.erv_mode";
              data.option = "Away";
            }
          ];
        }
        {
          id = "erv_normal_when_occupied";
          alias = "ERV: Return to Normal quickly when occupied";
          mode = "single";
          trigger = [
            {
              platform = "homeassistant";
              event = "start";
            }
            {
              platform = "numeric_state";
              entity_id = "zone.home";
              above = 0;
              for = "00:00:30";
            }
            {
              platform = "time_pattern";
              minutes = "/2";
            }
          ];
          condition = [
            {
              condition = "numeric_state";
              entity_id = "zone.home";
              above = 0;
            }
            {
              condition = "template";
              value_template = ''
                {{ states('input_select.erv_mode') not in ['Normal', 'Boost', 'Quiet'] }}
              '';
            }
          ];
          action = [
            {
              service = "input_select.select_option";
              target.entity_id = "input_select.erv_mode";
              data.option = "Normal";
            }
            {
              service = "script.turn_on";
              target.entity_id = "script.erv_apply_mode";
            }
          ];
        }
        {
          id = "erv_bypass_window_auto";
          alias = "ERV: Auto-set bypass window from indoor temps";
          mode = "restart";
          trigger = [
            {
              platform = "homeassistant";
              event = "start";
            }
            {
              platform = "state";
              entity_id = [
                "input_select.erv_mode"
              ];
            }
            {
              platform = "time_pattern";
              minutes = "/30";
            }
          ];
          action = [
            {
              choose = [
                {
                  conditions = [
                    {
                      condition = "state";
                      entity_id = "input_select.erv_mode";
                      state = "Away";
                    }
                  ];
                  sequence = [
                    {
                      service = "number.set_value";
                      target.entity_id = "number.smart_erv_erv_bypass_start_temp_x";
                      data.value = 30;
                    }
                    {
                      service = "number.set_value";
                      target.entity_id = "number.smart_erv_erv_bypass_range_y";
                      data.value = 2;
                    }
                  ];
                }
              ];
              default = [
                {
                  service = "number.set_value";
                  target.entity_id = "number.smart_erv_erv_bypass_start_temp_x";
                  data.value = ''
                    {% set indoor_raw = states('sensor.erv_indoor_reference_temperature') | float(21) %}
                    {% set indoor_smooth = states('sensor.erv_indoor_reference_temperature_smoothed') | float(indoor_raw) %}
                    {% set indoor = (indoor_raw * 0.3) + (indoor_smooth * 0.7) %}
                    {% set x = (indoor - 2) | round(0, 'floor') %}
                    {{ [0, [50, x] | min] | max }}
                  '';
                }
                {
                  service = "number.set_value";
                  target.entity_id = "number.smart_erv_erv_bypass_range_y";
                  data.value = 3;
                }
              ];
            }
          ];
        }
      ];
    };
  };
  #virtualisation.docker.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;
  networking.networkmanager.enable = true;
  services.pulseaudio.enable = false;
  #hardware.graphics.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libva-vdpau-driver
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
