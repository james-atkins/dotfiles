{ pkgs, ... }:

pkgs.fossil.overrideAttrs (attrs: {
  pname = "fossil-tailscale";
  patches = [ ./tailscale.patch ];
})
