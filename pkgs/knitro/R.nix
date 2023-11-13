{ lib
, rPackages
, knitro
}:

rPackages.buildRPackage rec {
  name = "KnitroR";
  inherit (knitro) version;

  src = "${knitro}/examples/R/KnitroR";
}
