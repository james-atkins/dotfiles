{ config, pkgs, ... }:

let
  localPkgs = import ../pkgs { inherit pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with localPkgs.cran; [
      localPkgs.duckdb.R

      arrow
      conflicted
      countrycode
      data_table
      devtools
      markdown
      reticulate
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
    (localPkgs.pyblp pp)
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
    age.secrets.stataLicence = {
     file = ../secrets/stata_licence.age;
     owner = config.users.users.james.name;
     group = config.users.users.james.group;
    };
    environment.etc."stata.lic".source = config.age.secrets.stataLicence.path;

    primary-user.home-manager = {
      home.packages = with pkgs; [
        localPkgs.duckdb
        localPkgs.rstudio
        jq
        RWithPackages
        pandoc
        pythonWithPackages
        julia-bin
        (sqlite.override { interactive = true; })
        localPkgs.stata16
      ];

      home.file.".sqliterc".text = ''
        .headers ON
        .mode box
        .changes ON
      '';
    };
  }
