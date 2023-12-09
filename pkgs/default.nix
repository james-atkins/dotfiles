{ pkgs, pkgs-unstable }:

rec {
  borgmatic-zfs-snapshot = pkgs.callPackage ./borgmatic-zfs-snapshot/default.nix { };
  cran = pkgs.callPackage ./cran/default.nix { };
  foot-themes = pkgs.callPackage ./foot-themes/default.nix { };
  fossil-tailscale = pkgs.callPackage ./fossil-tailscale/default.nix { };
  knitro = pkgs.callPackage ./knitro/default.nix { };
  knitroR = pkgs.callPackage ./knitro/R.nix { inherit knitro; };
  nbqa = pythonPackages: pythonPackages.callPackage ./nbqa { };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix { };
  tailscale-auth = pkgs-unstable.callPackage ./tailscale-auth {
    buildGoModule = pkgs-unstable.buildGo121Module;
  };
  pyblp = pythonPackages: pythonPackages.callPackage ./pyblp.nix { };
  stata16 = pkgs.callPackage ./stata16/default.nix { };
}
