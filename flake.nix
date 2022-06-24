{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@attrs: rec {
    nixosConfigurations.milan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./machines/milan/configuration.nix ];
    };

    githubActionsPkgs =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in import ./lib/github-actions.nix pkgs nixosConfigurations.milan;
  };
}
