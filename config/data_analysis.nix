{ pkgs
, ...
}:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  RWithPackages = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      arrow
      data_table
      devtools
      localPkgs.duckdb.Rpkg
      RSQLite
      shiny
      testthat
      tidyverse
      usethis
    ];
  };

  pythonWithPackages = pkgs.python3.withPackages (p: with p; [
    beautifulsoup4
    cython
    cytoolz
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
        localPkgs.duckdb.cli
        localPkgs.rstudio
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
