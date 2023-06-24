{ lib, buildGoModule, tailscale }:

buildGoModule {
  name = "tailscale-auth";
  src = tailscale.src;
  vendorHash = tailscale.vendorHash;
  subPackages = [ "cmd/nginx-auth" ];

  postInstall = ''
    mv $out/bin/nginx-auth $out/bin/tailscale-auth
  '';
}

