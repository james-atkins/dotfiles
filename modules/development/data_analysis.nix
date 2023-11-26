{ config, pkgs, pkgs-unstable, lib, pkgs-local, ... }:

let
  pythonWithPackages = (pkgs.python3.override {
    packageOverrides = pyfinal: pyprev: {
      aiohttp = pyprev.aiohttp.overrideAttrs (attrs: {
        disabledTests = attrs.disabledTests ++ [
          "test_static_file_if_none_match"
          "test_static_file_if_match"
          "test_static_file_if_modified_since_past_date"
        ];
      });
      # Fix Jupyter builds until https://nixpk.gs/pr-tracker.html?pr=267121 is merged
      urllib3 = pyprev.urllib3.overrideAttrs {
        patches = [
          (pkgs.fetchpatch {
            name = "revert-threadsafe-poolmanager.patch";
            url = "https://github.com/urllib3/urllib3/commit/710114d7810558fd7e224054a566b53bb8601494.patch";
            revert = true;
            hash = "sha256-2O0y0Tij1QF4Hx5r+WMxIHDpXTBHign61AXLzsScrGo=";
          })
        ];
      };
    };
  }).withPackages(pp: with pp; [
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
        ARTELYS_LICENSE_NETWORK_ADDR = "localhost:8349";
        LD_LIBRARY_PATH = "\${LD_LIBRARY_PATH:+\${LD_LIBRARY_PATH}:}${pkgs-local.knitro}/lib";
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

