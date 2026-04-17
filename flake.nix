{
  description = "NixOS configuration for all machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Window manager / shell tools
    # swww = {
    #   url = "github:LGFae/swww";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # # Astal libraries (includes niri support not in nixpkgs yet)
    # astal = {
    #   url = "github:aylur/astal";
    #  inputs.nixpkgs.follows = "nixpkgs";
    # };

    # # Astal Niri support (from community fork)
    # astal-niri = {
    #   url = "github:sameoldlab/astal/feat/niri";
    #  inputs.nixpkgs.follows = "nixpkgs";
    # };

    # # AGS v3.0.0 for delta-shell
    # ags = {
    #   url = "github:aylur/ags";
    #  inputs.nixpkgs.follows = "nixpkgs";
    # };

    # # Delta shell source (not a flake)
    # delta-shell = {
    #   url = "github:Sinomor/delta-shell";
    #  flake = false;
    # };

    # Noctalia shell for niri
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Matugen - Material You color generation tool
    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ghostty terminal (commented out like in framework flake)
    #ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = { self, nixpkgs, nixos-hardware, noctalia, matugen, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      # NixOS configurations
      nixosConfigurations = {

        # Framework laptop configuration
        framework = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            # Apply overlays properly via nixpkgs module
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.config.allowUnfree = true;
            }
            inputs.microvm.nixosModules.host
            ./machines/framework/configuration.nix
          ];
        };

      };
    };
}
