{ pkgs, ... }:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      tidyverse
      shiny
      RSQLite
    ];
  };

in
  {
    primary-user.home-manager.home.packages = [ localPkgs.rstudio RWithPackages ];
  }
