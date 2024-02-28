{ pkgs, pkgs-unstable }:

rec {
  cran = pkgs.callPackage ./cran/default.nix { };
  fossil-tailscale = pkgs.callPackage ./fossil-tailscale/default.nix { };
  knitro = pkgs.callPackage ./knitro/default.nix { };
  knitroR = pkgs.callPackage ./knitro/R.nix { inherit knitro; };
  nbqa = pythonPackages: pythonPackages.callPackage ./nbqa { };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix { };
  tailscale-auth = pkgs-unstable.callPackage ./tailscale-auth {
    buildGoModule = pkgs-unstable.buildGo122Module;
  };
  probe-rs-udev = pkgs.callPackage ./probe-rs-udev { };
  pyblp = pythonPackages: pythonPackages.callPackage ./pyblp.nix { };
  stata16 = pkgs.callPackage ./stata16/default.nix { };
}
