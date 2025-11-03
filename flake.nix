{
  description = "NixOS configuration for all machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Window manager / shell tools
    # swww = {
    #   url = "github:LGFae/swww";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Astal libraries (includes niri support not in nixpkgs yet)
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Astal Niri support (from community fork)
    astal-niri = {
      url = "github:sameoldlab/astal/feat/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AGS v3.0.0 for delta-shell
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Delta shell source (not a flake)
    delta-shell = {
      url = "github:Sinomor/delta-shell";
      flake = false;
    };

    # Ghostty terminal (commented out like in framework flake)
    #ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = { self, nixpkgs, nixos-hardware, astal, astal-niri, ags, delta-shell, ... }@inputs:
    let
      system = "x86_64-linux";

      # Create custom package overlay for delta-shell and astal-niri
      deltaShellOverlay = final: prev: {
        astal-niri = prev.callPackage ./pkgs/astal-niri {
          src = astal-niri;
        };

        delta-shell = prev.callPackage ./pkgs/delta-shell {
          inherit (ags.packages.${system}) ags;
          # Use astal from the flake input
          astal = astal.packages.${system};
          # Add astal-niri from our package
          astal-niri = final.astal-niri;
          src = delta-shell;
        };
      };

    in
    {
      # Package outputs (can be built with: nix build .#delta-shell)
      packages.${system} = {
        delta-shell = (import nixpkgs {
          inherit system;
          overlays = [ deltaShellOverlay ];
        }).delta-shell;
      };

      # NixOS configurations
      nixosConfigurations = {

        # Framework laptop configuration
        framework = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # Apply overlays properly via nixpkgs module
            {
              nixpkgs.overlays = [ deltaShellOverlay ];
              nixpkgs.config.allowUnfree = true;
            }
            ./machines/framework/configuration.nix
          ];
        };

      };
    };
}
