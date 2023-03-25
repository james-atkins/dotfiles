{ pkgs }:

rec {
  borgmatic-zfs-snapshot = pkgs.callPackage ./borgmatic-zfs-snapshot/default.nix { };
  cran = pkgs.callPackage ./cran/default.nix { };
  duckdb = pkgs.callPackage ./duckdb/default.nix { inherit cran; };
  foot-themes = pkgs.callPackage ./foot-themes/default.nix { };
  fossil-tailscale = pkgs.callPackage ./fossil-tailscale/default.nix { };
  helix = pkgs.callPackage ./helix/default.nix { };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix { };
  pyblp = pythonPackages: pythonPackages.callPackage ./pyblp.nix { };
  rtsp-simple-server = pkgs.callPackage ./rtsp-simple-server/default.nix { };
  tailscale = pkgs.callPackage ./tailscale/default.nix { };
  stata16 = pkgs.callPackage ./stata16/default.nix { };
}
