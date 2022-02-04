{ pkgs, ... }:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      arrow
      tidyverse
      shiny
      testthat
      RSQLite
      data_table
    ];
  };

in
  {
    # primary-user.home-manager.home.packages = [ localPkgs.rstudio RWithPackages ];
    primary-user.home-manager.home.packages = [ RWithPackages ];
  }
