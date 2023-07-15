{ fetchFromGitHub, runCommand }:

let
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "5d8dc3eb692809ffd9a2f22cdb8015aa11972905";
    hash = "sha256-g1Nn0sgH/hR/gEAQ1q6bloU+Q+V+Y4HlBBH6CBxC0HM=";
  };
in
runCommand "flake-registry.json" { } ''
  cp ${src}/flake-registry.json $out
''

