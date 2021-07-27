{ pkgs, ... }:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with pkgs.unstable.rPackages; [
      tidyverse
      shiny
      RSQLite
      data_table
      targets
    ];
  };

in
  {
    primary-user.home-manager.home.packages = [ localPkgs.rstudio RWithPackages ];
  }
