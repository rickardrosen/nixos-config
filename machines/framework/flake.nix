# /etc/nixos/flake.nix
{
  description = "flake for framwork laptop";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    swww.url = "github:LGFae/swww";
    #ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
