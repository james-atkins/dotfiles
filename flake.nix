{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/0.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nuzulip = {
      url = "github:james-atkins/zulip-nu-econ";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, agenix, nuzulip }@inputs:
    let
      inherit (nixpkgs.lib) filterAttrs mapAttrs mapAttrs' mapAttrsToList mkIf nameValuePair;

      inputs' = filterAttrs (name: value: name != "self") inputs;

      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          hostPlatform = system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              mediamtx = pkgs-unstable.${system}.mediamtx;
            })
          ];
        }
      );

      pkgs-unstable = forAllSystems (system:
        import nixpkgs-unstable {
          inherit system;
          hostPlatform = system;
          config.allowUnfree = true;
        }
      );

      pkgs-local = forAllSystems (system:
        import ./pkgs/default.nix {
          pkgs = pkgs.${system};
          pkgs-unstable = pkgs-unstable.${system};
        }
      );

      mkSystems = systems:
        let
          global = {
            tailscaleDomain = "crocodile-major.ts.net";

            email = with nixpkgs.lib; concatStrings (
              [ "c" "o" "n" "t" "a" "c" "t" ] ++
              singleton "@" ++
              reverseList [ "s" "e" "m" "a" "j" ] ++
              reverseList [ "s" "n" "i" "k" "t" "a" ] ++
              singleton "." ++
              [ "n" "e" "t" ]
            );

            # Information about all the machines
            machines = builtins.listToAttrs
              (map
                (sys:
                  nameValuePair sys.name { syncthing = sys.syncthing or null; }
                )
                systems);
          };

          mkSystem = { name, system, hardware ? null, ... }:
            let
              args = {
                inherit global;
                pkgs-unstable = pkgs-unstable.${system};
                pkgs-local = pkgs-local.${system};
              };
            in
            nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = pkgs.${system};
              modules = [
                agenix.nixosModule
                home-manager.nixosModule
                nuzulip.nixosModules.default

                {
                  networking.hostName = name;

                  nix.extraOptions = "experimental-features = nix-command flakes";

                  # Don't talk to the internet every time I use the registry
                  nix.settings.flake-registry = ./flake-registry.json;

                  # Pin flakes in the system registry to the versions used to build this system
                  nix.registry = mapAttrs (name: value: { flake = value; }) inputs';

                  # Indirect NIX_PATH so it always points to the most recent version without needing to login again
                  nix.nixPath = mapAttrsToList (name: _: "${name}=/etc/nix/path/${name}") inputs';
                  environment.etc = mapAttrs' (name: value: nameValuePair "nix/path/${name}" { source = value; }) inputs';

                  system.configurationRevision = mkIf (self ? rev) self.rev;

                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    extraSpecialArgs = args;
                  };

                  _module.args = args;
                }

                ./modules
                ./machines/${name}/hardware-configuration.nix
                ./machines/${name}/configuration.nix
              ] ++ (if hardware != null then [ nixos-hardware.nixosModules.${hardware} ] else [ ]);
            };
        in
        builtins.listToAttrs (map (sys: nameValuePair sys.name (mkSystem sys)) systems);

    in
    {
      formatter = forAllSystems (system: pkgs.${system}.nixpkgs-fmt);

      nixosConfigurations = mkSystems [
        { name = "athena"; system = "x86_64-linux"; hardware = "pcengines-apu"; syncthing = "UCXAY5Y-4CGWWRL-VZVHBS4-LGLSAWZ-N6OGXZW-ZNYNH5T-XONQFTJ-FHPIGQX"; }
        { name = "milan"; system = "x86_64-linux"; hardware = "lenovo-thinkpad-t480"; syncthing = "J4QUY74-OB5QNT5-XG5M3EX-AXJWEN2-FLY6LBP-BUYJYFO-FCGZ5GR-RJ5MFQX"; }
        { name = "zeus"; system = "x86_64-linux"; syncthing = "TDZKBCW-U2DSEPN-XF2K5NP-RK3NRWB-MHMPFXB-LEKHBS6-6OT3I43-SF7JLAY"; }
      ];

      devShells = forAllSystems (system: {
        default = with pkgs.${system}; mkShellNoCC {
          nativeBuildInputs = [ agenix.packages.${system}.agenix ];
        };
      });

      packages = with nixpkgs.lib; forAllSystems (system:
        filterAttrs (n: v: isDerivation v) pkgs-local.${system}
      );

      legacyPackages = with nixpkgs.lib; forAllSystems (system:
        # There are so many CRAN packages that it would be impossible for nix flake show to display
        # them all, plus there are issues with flattening derivations. So just shove everything in
        # legacyPackages for now.
        # We can still run nix build .#cran.PKGNAME if we want to build a specific package.
        filterAttrs (n: v: !isDerivation v) pkgs-local.${system}
      );
    };
}
