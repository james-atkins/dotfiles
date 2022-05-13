{ lib
, stdenv
, fetchFromGitHub
, cmake
, duckdbVersion
, openssl
, ninja
}:

stdenv.mkDerivation rec {
  pname = "duckdb";
  version = duckdbVersion;

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-2PBc5qe2md87u2nvMTx/XZVzLsr8QrvUkw46/6VTlGs=";
  };

  patches = [ ./version.patch ];
  postPatch = ''
    substituteInPlace CMakeLists.txt --subst-var-by DUCKDB_VERSION "v${version}"
  '';

  cmakeFlags = [
    "-DBUILD_FTS_EXTENSION=ON"
    "-DBUILD_HTTPFS_EXTENSION=ON"
    "-DBUILD_ICU_EXTENSION=ON"
    "-DBUILD_PARQUET_EXTENSION=ON"
    "-DBUILD_REST_EXTENSION=ON"
    "-DBUILD_TPCDS_EXTENSION=ON"
    "-DBUILD_TPCH_EXTENSION=ON"
    "-DBUILD_VISUALIZER_EXTENSION=ON"
  ];

  buildInputs = [ openssl ]; # For HTTPFS
  nativeBuildInputs = [ cmake ninja ];

  meta = with lib; {
    homepage = "https://github.com/duckdb/duckdb";
    description = "DuckDB is an in-process SQL OLAP Database Management System";
    license = licenses.mit;
    platforms = platforms.all;
  };
}

