{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/0.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, agenix, home-manager, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      nixosConfigurations = {
        milan = nixpkgs.lib.nixosSystem
          {
            system = "x86_64-linux";
            specialArgs = inputs;
            modules = [
              nixos-hardware.nixosModules.lenovo-thinkpad-t480
              home-manager.nixosModule
              agenix.nixosModule
              ./machines/milan/hardware-configuration.nix
              ./machines/milan/configuration.nix
              {
                age.secrets.rootPassword.file = ./secrets/password_root.age;
              }
            ];
          };
      };

      packages = with nixpkgs.lib; forAllSystems (system:
        filterAttrs (n: v: isDerivation v) (import ./pkgs/default.nix { pkgs = nixpkgs.legacyPackages.${system}; })
      );
    };
}
