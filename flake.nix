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

  outputs = { self, nixpkgs, nixos-hardware, agenix, home-manager }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          hostPlatform = system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              rtsp-simple-server = prev.callPackage ./pkgs/rtsp-simple-server { };
            })
          ];
        }
      );

      localPkgs = forAllSystems (system:
        import ./pkgs/default.nix { pkgs = pkgs.${system}; }
      );

      localModules.persistence = import ./modules/persistence.nix;

      mkSystems = systems:
        let
          global = {
            tailscaleDomain = "crocodile-major.ts.net";

            # Information about all the machines
            machines = builtins.listToAttrs
              (map
                (sys:
                  nixpkgs.lib.nameValuePair sys.name { syncthing = sys.syncthing or null; }
                )
                systems);
          };

          mkSystem = { name, system, hardware ? null, ... }:
            let
              args = {
                inherit global;
                localPkgs = localPkgs.${system};
              };
            in
            nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = pkgs.${system};
              modules = [
                agenix.nixosModule
                home-manager.nixosModule
                localModules.persistence

                {
                  networking.hostName = name;

                  nix = {
                    extraOptions = "experimental-features = nix-command flakes";
                    registry.nixpkgs.flake = nixpkgs;
                    nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
                  };

                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    extraSpecialArgs = args;
                  };

                  _module.args = args;
                }

                ./common/core.nix
                ./common/tailscale.nix
                ./common/syncthing.nix

                ./modules

                ./machines/${name}/hardware-configuration.nix
                ./machines/${name}/configuration.nix
              ] ++ (if hardware != null then [ nixos-hardware.nixosModules.${hardware} ] else [ ]);
            };
        in
        builtins.listToAttrs (map (sys: nixpkgs.lib.nameValuePair sys.name (mkSystem sys)) systems);

    in
    {
      formatter = forAllSystems (system: pkgs.${system}.nixpkgs-fmt);

      nixosModules = localModules;

      nixosConfigurations = mkSystems [
        { name = "athena"; system = "x86_64-linux"; hardware = "pcengines-apu"; syncthing = "UCXAY5Y-4CGWWRL-VZVHBS4-LGLSAWZ-N6OGXZW-ZNYNH5T-XONQFTJ-FHPIGQX"; }
        { name = "milan"; system = "x86_64-linux"; hardware = "lenovo-thinkpad-t480"; syncthing = "J4QUY74-OB5QNT5-XG5M3EX-AXJWEN2-FLY6LBP-BUYJYFO-FCGZ5GR-RJ5MFQX"; }
        { name = "zeus"; system = "x86_64-linux"; syncthing = "HFBRTRE-N2GEJCZ-5BSF36N-XNKNKXY-YDBKXYW-IVAWZRQ-TKKY7OI-M27EEQO"; }
      ];

      devShells = forAllSystems (system: {
        default = with pkgs.${system}; mkShellNoCC {
          nativeBuildInputs = [ agenix.packages.${system}.agenix ];
        };
      });

      packages = with nixpkgs.lib; forAllSystems (system:
        filterAttrs (n: v: isDerivation v) localPkgs.${system}
      );

      legacyPackages = with nixpkgs.lib; forAllSystems (system:
        # There are so many CRAN packages that it would be impossible for nix flake show to display
        # them all, plus there are issues with flattening derivations. So just shove everything in
        # legacyPackages for now.
        # We can still run nix build .#cran.PKGNAME if we want to build a specific package.
        filterAttrs (n: v: !isDerivation v) localPkgs.${system}
      );
    };
}
