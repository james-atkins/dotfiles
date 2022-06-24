{ self, config, pkgs, nixpkgs, ... }:
let overlaysCompat = pkgs.writeTextDir "overlays-compat.nix" ''
  final: prev:
  with prev.lib;
  let
    flake = builtins.getFlake (toString ${./.});
    overlays = flake.nixosConfigurations.${config.networking.hostName}.config.nixpkgs.overlays;
  in
    # Apply all overlays to the input of the current "main" overlay
    foldl' (flip extends) (_: prev) overlays final
  '';
in
  {
    system.configurationRevision = if self ? rev then self.rev else "dirty";

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = "experimental-features = nix-command flakes";
      registry.nixpkgs.flake = nixpkgs;
      nixPath = [
        "nixpkgs=${nixpkgs.outPath}"
        "nixpkgs-overlays=${overlaysCompat}"
      ];

      binaryCaches = [ "https://james-atkins.cachix.org" ];
      binaryCachePublicKeys = [ "james-atkins.cachix.org-1:Ljm14bKUUSXidZleVQejHDjDp1lrI7Rh/2WsY5ax280="];
    };

    nixpkgs.config.allowUnfree = true;

    i18n.defaultLocale = "en_GB.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };
  }
