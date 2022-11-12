{ self, pkgs, nixpkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    # package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    registry.nixpkgs.flake = nixpkgs;
    nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 28d";
    };

    settings = {
      auto-optimise-store = true;
      substituters = [ "https://james-atkins.cachix.org" ];
      trusted-public-keys = [ "james-atkins.cachix.org-1:Ljm14bKUUSXidZleVQejHDjDp1lrI7Rh/2WsY5ax280="];
    };
  };

  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };
}

