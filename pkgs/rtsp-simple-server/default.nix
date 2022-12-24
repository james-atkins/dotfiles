{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "rtsp-simple-server";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "aler9";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-iLNdl6V+px/ri9uJzOrxktxJYqAJA5JWBd18ZHSLQjQ=";
  };

  vendorSha256 = "sha256-48i0hsAho4dI79a/i24GlKAaC/yNGKt0uA+qCy5QTok=";

  # Tests need docker
  doCheck = false;

  ldflags = [
    "-X github.com/aler9/rtsp-simple-server/internal/core.version=v${version}"
  ];
}

