{ lib
, stdenv
, fetchFromGitHub
, cmake
, duckdbVersion
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

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'set(DUCKDB_VERSION "v''${DUCKDB_MAJOR_VERSION}.''${DUCKDB_MINOR_VERSION}.''${DUCKDB_PATCH_VERSION}-dev''${DUCKDB_DEV_ITERATION}")' 'set(DUCKDB_VERSION "v${version}")'
  '';

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    homepage = "https://github.com/duckdb/duckdb";
    description = "DuckDB is an in-process SQL OLAP Database Management System";
    license = licenses.mit;
    platforms = platforms.all;
  };
}

