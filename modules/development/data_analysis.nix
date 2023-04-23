{ config, pkgs, pkgs-unstable, lib, localPkgs, ... }:

let
  RWithPackages = pkgs.rWrapper.override {
    packages = with localPkgs.cran; [
      localPkgs.duckdb.R

      # arrow
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
    (localPkgs.nbqa pp)
    networkx
    numba
    numexpr
    numpy
    openpyxl
    pandas
    patsy
    # pyarrow
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
  options.ja.development.data_analysis = lib.mkEnableOption "Data analysis programmes";

  config = lib.mkIf config.ja.development.data_analysis {
    age.secrets.stata16Licence = {
      file = ../../secrets/stata16_licence.age;
      owner = config.users.users.james.name;
      group = config.users.users.james.group;
    };
    environment.etc."stata16.lic".source = config.age.secrets.stata16Licence.path;

    home-manager.users.james = { pkgs, ... }: {
      home.packages = with pkgs; [
        RWithPackages
        pythonWithPackages
        pkgs-unstable.ruff

        localPkgs.duckdb
        localPkgs.stata16

        jq
        pandoc
        julia
        (sqlite.override { interactive = true; })
      ];

      home.file.".sqliterc".text = ''
        .headers ON
        .mode box
        .changes ON
      '';
    };
  };
}

