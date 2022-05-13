{ lib
, duckdb
, python3
, rPackages
}:

with rPackages; buildRPackage rec {
  name = "duckdb";
  inherit (duckdb) version src;

  sourceRoot = "source/tools/rpkg";

  nativeBuildInputs = [ python3 ];
  propagatedBuildInputs = [ DBI ];
}

