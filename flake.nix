{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, rust-overlay }: rec {

    nixosConfigurations.milan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        rust-overlay = rust-overlay.overlay;
      };

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

    githubActionsPkgs =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in import ./lib/github-actions.nix pkgs nixosConfigurations.milan;
  };
}
