{ callPackage }:

let
  duckdb = callPackage ./main.nix {};
  R = callPackage ./R.nix { inherit duckdb; };
  python = pythonPackages: pythonPackages.callPackage ./python.nix { inherit duckdb; };
in
  duckdb // { inherit R; } // { inherit python; }

