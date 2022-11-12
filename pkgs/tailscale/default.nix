{ lib
, stdenv
, fetchzip
, makeWrapper
, iproute2
, iptables
, getent
, procps
, shadow
}:

let
  pname = "tailscale";
  version = "1.32.2";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    name = "tailscale-${version}-source";
    url = "https://pkgs.tailscale.com/stable/tailscale_${version}_amd64.tgz";
    sha256 = "sha256-/o8QoDBUjaQV10gLKF27IAJfHzpY1QluWz8mPgquYDo=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -D -m0555 $src/tailscale $out/bin/tailscale
    install -D -m0555 $src/tailscaled $out/bin/tailscaled

    wrapProgram $out/bin/tailscaled --prefix PATH : ${lib.makeBinPath [ iproute2 iptables getent shadow ]}
    wrapProgram $out/bin/tailscale --suffix PATH : ${lib.makeBinPath [ procps ]}

    mkdir -p $out/lib/systemd/system
    sed -e "s#/usr/sbin#$out/bin#" -e "/^EnvironmentFile/d" $src/systemd/tailscaled.service > $out/lib/systemd/system/tailscaled.service
    chmod 0444 $out/lib/systemd/system/tailscaled.service

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://tailscale.com";
    description = "The node agent for Tailscale, a mesh VPN built on WireGuard";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}

