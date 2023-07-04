{ pkgs, pkgs-unstable }:

rec {
  borgmatic-zfs-snapshot = pkgs.callPackage ./borgmatic-zfs-snapshot/default.nix { };
  cran = pkgs.callPackage ./cran/default.nix { };
  duckdb = pkgs.callPackage ./duckdb/default.nix { inherit cran; };
  epsonscan2 = pkgs.libsForQt5.callPackage ./epsonscan2 { };
  foot-themes = pkgs.callPackage ./foot-themes/default.nix { };
  fossil-tailscale = pkgs.callPackage ./fossil-tailscale/default.nix { };
  helix = pkgs-unstable.callPackage ./helix/default.nix { };
  nbqa = pythonPackages: pythonPackages.callPackage ./nbqa { };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix { };
  tailscale-auth = pkgs-unstable.callPackage ./tailscale-auth { };
  pyblp = pythonPackages: pythonPackages.callPackage ./pyblp.nix { };
  stata16 = pkgs.callPackage ./stata16/default.nix { };
  utsushi = pkgs.callPackage ./utsushi { };
}
