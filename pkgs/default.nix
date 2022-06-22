{ pkgs }:

rec {
  cran = pkgs.callPackage ./cran/default.nix {};
  duckdb = pkgs.callPackage ./duckdb/default.nix { inherit cran; };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix {};
  pyblp = pythonPackages: pythonPackages.callPackage ./pyblp.nix {};
  tailscale = pkgs.callPackage ./tailscale/default.nix {};
}
