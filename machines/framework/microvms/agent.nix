{ pkgs, ... }:

let
  vmName = "agent";
  sshPort = 2222;
  vmUser = "rickard";
  bridgeName = "microvm";
  vmIp = "10.0.0.2";
  vmStateDir = "/var/lib/microvms/${vmName}";
in
{
  imports = [ ../../../modules/dotfiles.nix ];

  microvm.vms.${vmName} = {
      autostart = false;

      config = {
        networking.hostName = vmName;

        microvm.hypervisor = "firecracker";
        microvm.vcpu = 4;
        microvm.mem = 16384;

        microvm.interfaces = [
          {
            type = "tap";
            id = "tap-${vmName}";
            mac = "02:00:00:00:00:02";
          }
        ];

        microvm.volumes = [
          {
            mountPoint = "/";
            image = "${vmStateDir}/rootfs.img";
            size = 20480;
          }
        ];

        networking.useNetworkd = true;
        networking.useDHCP = false;
        systemd.network = {
          enable = true;
          networks."10-uplink" = {
            matchConfig.MACAddress = "02:00:00:00:00:02";
            networkConfig = {
              Address = "${vmIp}/24";
              Gateway = "10.0.0.1";
              DNS = "1.1.1.1";
            };
          };
        };

        services.openssh.enable = true;
        services.openssh.settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
        networking.firewall.allowedTCPPorts = [ 22 ];

        services.avahi = {
          enable = true;
          nssmdns4 = true;
          publish = {
            enable = true;
            addresses = true;
            workstation = true;
          };
        };

        users.users.${vmUser} = {
          isNormalUser = true;
          home = "/home/${vmUser}";
          createHome = true;
          shell = pkgs.fish;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICjAOpKy8ieFawgvbEhw6GDFsC8e+fcWV1llJ3WlaxBx"
          ];
        };

        security.sudo.wheelNeedsPassword = false;

        programs.fish.enable = true;

        environment.systemPackages = with pkgs; [
          curl
          git
          devenv
          fish
          helix
          openssh
          tmux
        ];

        services.getty.autologinUser = null;

        system.stateVersion = "25.05";
      };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.isInGroup("wheel") &&
        action.lookup("unit") &&
        action.lookup("unit").startsWith("microvm@") &&
        action.lookup("unit").endsWith(".service") &&
        ["start", "stop", "restart"].indexOf(action.lookup("verb")) >= 0
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.network = {
    enable = true;
    netdevs."10-${bridgeName}" = {
      netdevConfig = {
        Kind = "bridge";
        Name = bridgeName;
      };
    };
    networks = {
      "10-${bridgeName}" = {
        matchConfig.Name = bridgeName;
        networkConfig = {
          Address = "10.0.0.1/24";
          DHCPServer = true;
        };
      };
      "11-${vmName}-tap" = {
        matchConfig.Name = "tap-${vmName}";
        networkConfig.Bridge = bridgeName;
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  networking.firewall.allowedTCPPorts = [ sshPort ];
  networking.firewall.allowedUDPPorts = [ 5353 ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 5353; to = 5353; }
  ];
}
