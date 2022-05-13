{ pkgs, ... }:

let
  localPkgs = import ../pkgs/default.nix { pkgs = pkgs; };

  r_targets = with pkgs.rPackages; buildRPackage rec {
    name = "targets";
    version = "0.12.0";

    src = fetchTarball {
      url = "https://cran.r-project.org/src/contrib/targets_${version}.tar.gz";
      sha256 = "1mpf8w7l8k1jxj62hv5fnh7ry81bgrgkchrc1ivpscqcs2jisdlc";
    };

    propagatedBuildInputs = [
      base64url
      callr
      cli
      codetools
      data_table
      digest
      igraph
      knitr
      R6
      rlang
      tibble
      tidyselect
      vctrs
      withr
      yaml
    ];
  };

  r_tarchetypes = with pkgs.rPackages; buildRPackage rec {
    name = "tarchetypes";
    version = "0.6.0";

    src = fetchTarball {
      url = "https://cran.r-project.org/src/contrib/tarchetypes_${version}.tar.gz";
      sha256 = "1bcyv26glh0gsijlchd1l70hdvgg15givi07ydyib84hw05qiyfh";
    };

    propagatedBuildInputs = [
      digest
      dplyr
      fs
      rlang
      r_targets
      tibble
      tidyselect
      vctrs
      withr
    ];
  };

  RWithPackages = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      arrow
      conflicted
      countrycode
      data_table
      devtools
      localPkgs.duckdb.R
      RSQLite
      shiny
      r_tarchetypes
      r_targets
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
