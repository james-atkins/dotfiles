{ lib
, rPackages
, duckdbVersion
}:

with rPackages; buildRPackage rec {
  name = "duckdb";
  version = duckdbVersion;

  src = fetchTarball {
    url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_r_src.tar.gz";
    sha256 = "0ksfrvxihkgyahjzwhs0vdbyk0khq4cx14cawb7nh1jn1nxnfb0f";
  };

  propagatedBuildInputs = [ DBI ];

  meta = with lib; {
    homepage = "https://github.com/duckdb/duckdb";
    description = "DuckDB is an in-process SQL OLAP Database Management System";
    license = licenses.mit;
    platforms = platforms.all;
  };
}

