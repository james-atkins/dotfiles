{ pkgs }:

{
  duckdb = pkgs.callPackage ./duckdb/default.nix {};
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix {};
}
