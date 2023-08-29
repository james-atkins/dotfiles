{ lib
, stdenv
, python3
}:

stdenv.mkDerivation {
  name = "bthomehub-hosts";
  src = ./.;
  dontUnpack = true;
  propagatedBuildInputs = [ (python3.withPackages (ps: with ps; [ requests ])) ];
  installPhase = ''
    mkdir $out
    cp $src/*.py $out
    mkdir $out/bin
    ln -s $out/generate_hosts.py $out/bin/generate_hosts
  '';
}




