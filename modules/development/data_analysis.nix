{ config, pkgs, pkgs-unstable, lib, pkgs-local, ... }:

let
  pythonWithPackages = pkgs.python3.withPackages (pp: with pp; [
    beautifulsoup4
    cython
    cytoolz
    (pkgs-local.duckdb.python pp)
    flake8
    ipython
    jupyter
    lxml
    matplotlib
    (pkgs-local.nbqa pp)
    networkx
    numba
    numexpr
    numpy
    openpyxl
    pandas
    patsy
    # pyarrow
    (pkgs-local.pyblp pp)
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
      home.sessionVariables = {
        KNITRODIR = pkgs-local.knitro;
        LD_LIBRARY_PATH = "${pkgs-local.knitro}/lib:$LD_LIBRARY_PATH";
      };

      home.packages = with pkgs; [
        pythonWithPackages
        pkgs-unstable.ruff

        pkgs-local.duckdb
        pkgs-local.stata16

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

