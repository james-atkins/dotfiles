{ lib, buildGoModule }:

buildGoModule rec {
  name = "sway-exec-app";
  src = ./.;
  vendorSha256 = "sha256-yzvfllJTpFt+MBLOspw2xLHTqOWxv+9m8VA6MeCHRM4=";
  ldflags = [ "-s -w" ];
}

