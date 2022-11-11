{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/0.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, agenix, ... }@attrs: rec {
    nixosConfigurations.milan = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = attrs // { localPkgs = import ./pkgs/default.nix { pkgs = nixpkgs.legacyPackages.${system}; }; };
      modules = [
        nixos-hardware.nixosModules.lenovo-thinkpad-t480
        agenix.nixosModule
        ./machines/milan/hardware-configuration.nix
        ./machines/milan/configuration.nix
        {
          age.secrets.rootPassword.file = ./secrets/password_root.age;
        }
      ];
    };

    githubActionsPkgs =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in import ./lib/github-actions.nix pkgs nixosConfigurations.milan;
  };
}
