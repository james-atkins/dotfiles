{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager }: rec {

    nixosConfigurations.milan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules =
        let
          # Inject unstable packages into the package set
          overlay-unstable = final: prev: rec {
            unstable = import nixpkgs-unstable { system = final.system; };
          };
        in [
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          home-manager.nixosModules.home-manager
          ./configuration.nix

          {
            system.configurationRevision = if self ? rev then self.rev else "dirty";

            nixpkgs.overlays = [overlay-unstable ];

            # Point nixpkgs to the nixpkgs used to build the system
            nix = {
              registry.nixpkgs.flake = nixpkgs;
              nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
            };
          }
        ];
    };

    githubActionsPkgs =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in import ./lib/github-actions.nix pkgs nixosConfigurations.milan;
  };
}
