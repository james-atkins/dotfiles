{ pkgs, ... }:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with localPkgs.cran; [
      localPkgs.duckdb.R

      # arrow
      conflicted
      countrycode
      data_table
      devtools
      RSQLite
      shiny
      targets
      tarchetypes
      testthat
      tidyverse
      usethis
    ];
  };

  pythonWithPackages = pkgs.python3.withPackages (pp: with pp; [
    beautifulsoup4
    cython
    cytoolz
    (localPkgs.duckdb.python pp)
    flake8
    ipython
    jupyter
    lxml
    matplotlib
    networkx
    numba
    numexpr
    numpy
    openpyxl
    pandas
    patsy
    pyarrow
    pytest
    requests
    scipy
    sphinx
    sqlalchemy
    statsmodels
    sympy
    toolz
    xarray
    xlrd
  ]);

in
  {
    primary-user.home-manager = {
      home.packages = with pkgs; [
        localPkgs.duckdb
        localPkgs.rstudio
        jq
        RWithPackages
        pythonWithPackages
        (sqlite.override { interactive = true; })
      ];

      home.file.".sqliterc".text = ''
        .headers ON
        .mode columns
        .changes ON
      '';
    };
  }
