{ callPackage
, cran
}:

let
  duckdb = callPackage ./main.nix { };
  python = pythonPackages: pythonPackages.callPackage ./python.nix { inherit duckdb; };
in
duckdb // { inherit python; }

