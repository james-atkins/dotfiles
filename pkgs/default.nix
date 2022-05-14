{ pkgs }:

rec {
  cran = pkgs.callPackage ./cran/default.nix {};
  duckdb = pkgs.callPackage ./duckdb/default.nix { inherit cran; };
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix {};
}
