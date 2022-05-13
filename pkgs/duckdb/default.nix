{ pkgs }:

let
  duckdbVersion = "0.3.4";
in
  {
    cli = pkgs.callPackage ./cli.nix { inherit duckdbVersion; };
    Rpkg = pkgs.callPackage ./R.nix { inherit duckdbVersion; };
  }

