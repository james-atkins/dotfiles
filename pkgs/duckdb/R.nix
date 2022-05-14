{ lib
, duckdb
, python3
, cran
}:

cran.buildRPackage rec {
  name = "duckdb";
  inherit (duckdb) version src;

  sourceRoot = "source/tools/rpkg";

  nativeBuildInputs = [ python3 ];
  propagatedBuildInputs = with cran; [ DBI ];
}

