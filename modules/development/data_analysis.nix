{ config, pkgs, pkgs-unstable, lib, pkgs-local, ... }:

let
  pythonWithPackages = pkgs.python3.withPackages(pp: with pp; [
    autograd
    beautifulsoup4
    cython
    cytoolz
    duckdb
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
        ARTELYS_LICENSE_NETWORK_ADDR = "localhost:8349";
        LD_LIBRARY_PATH = "\${LD_LIBRARY_PATH:+\${LD_LIBRARY_PATH}:}${pkgs-local.knitro}/lib";
      };

      home.packages = with pkgs; [
        pythonWithPackages
        pkgs-unstable.ruff

        pkgs-local.stata16

        duckdb
        jq
        pandoc
        julia
        (sqlite.override { interactive = true; })

        (pkgs.writeShellScriptBin "quest_knitro_licence" ''${pkgs.openssh}/bin/ssh -NT -L 8349:129.105.119.173:8349 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" jda3869@quest.northwestern.edu'')
      ];

      home.file.".sqliterc".text = ''
        .headers ON
        .mode box
        .changes ON
      '';
    };
  };
}

