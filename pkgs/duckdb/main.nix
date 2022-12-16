{ lib
, cmake
, fetchFromGitHub
, ninja
, openssl
, stdenv
}:

stdenv.mkDerivation rec {
  pname = "duckdb";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-no4fcukEpzKmh2i41sdXGDljGhEDkzk3rYBATqlq6Gw=";
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

