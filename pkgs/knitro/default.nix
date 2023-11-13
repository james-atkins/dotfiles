{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  pname = "knitro";
  description = "Artelys Knitro is a commercial software package for solving large scale nonlinear mathematical optimization problems.";
  version = "13.2.0";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://jdsa3.user.srcf.net/knitro-${version}-Linux-64.tar.gz";
    hash = "sha256-6qEsGbSkakfgkU3175mgbURuGoI12OhS4unpQ/I3OV0=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall
    mkdir $out
    tar -xzf $src -C $out --strip-components=1
    rm -r $out/knitromatlab
    runHook postInstall
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc
  ];

  meta = with lib; {
    inherit description;
    homepage = "https://www.artelys.com";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}

