{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }:
    rec {
      nixosConfigurations.milan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          home-manager.nixosModules.home-manager
          ./configuration.nix

          {
            system.configurationRevision = if self ? rev then self.rev else "dirty";

            # Point nixpkgs to the nixpkgs used to build the system
            nix = {
              registry.nixpkgs.flake = nixpkgs;
              nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
            };
          }
        ];
      };

      allPackages = 
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };

          safeLinkFarm = name: drvs:
            let mkEntryFromDrv = drv: { name = pkgs.lib.removePrefix "/nix/store/" drv; path = drv; };
            in pkgs.linkFarm name (map mkEntryFromDrv drvs);

        in
          safeLinkFarm "milan-packages" (pkgs.lib.unique (nixosConfigurations.milan.config.environment.systemPackages ++ nixosConfigurations.milan.config.primary-user.home-manager.home.packages));
    };
}
