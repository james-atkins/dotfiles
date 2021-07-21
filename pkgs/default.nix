{ pkgs }:

{
  rstudio = pkgs.libsForQt5.callPackage ./rstudio/default.nix {};
}
