{ lib, buildGoModule, borgmatic }:

buildGoModule rec {
  name = "borgmatic-zfs-snapshot";
  src = ./.;
  vendorHash = "sha256-G5uPkndn7h3CTHWtwPnAqo6pxVhNxbtbEMv67gdqpTM=";
  postPatch = ''
    substituteInPlace main.go --replace '@BORGMATIC@' ${borgmatic}/bin/borgmatic
  '';
}

