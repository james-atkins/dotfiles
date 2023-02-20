{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "rtsp-simple-server";
  version = "0.21.4";

  src = fetchFromGitHub {
    owner = "aler9";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-56BHSRwiYxQHo32d0ZVKJB44GCEG6GRwrjQq6GlIHBc=";
  };

  vendorSha256 = "sha256-HYuW129TQjcG+JGO6OtweIwjcs6hmgaikDaaM4VFSd0=";

  # Tests need docker
  doCheck = false;

  ldflags = [
    "-X github.com/aler9/rtsp-simple-server/internal/core.version=v${version}"
  ];
}

