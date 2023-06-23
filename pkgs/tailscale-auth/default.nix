{ lib, buildGoModule, tailscale }:

buildGoModule {
  name = "tailscale-auth";
  src = tailscale.src;
  vendorHash = "sha256-7L+dvS++UNfMVcPUCbK/xuBPwtrzW4RpZTtcl7VCwQs=";
  subPackages = [ "cmd/nginx-auth" ];

  postInstall = ''
    mv $out/bin/nginx-auth $out/bin/tailscale-auth
  '';
}

