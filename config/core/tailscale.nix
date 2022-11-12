{ lib, config, pkgs, ... }:

let
  cfg = config.ja.tailscale;
  localPkgs = import ../../pkgs/default.nix { inherit pkgs; };
in
{
  options = {
    ja.tailscale.exitNode = lib.mkEnableOption "Tailscale exit node";
  };

  config = {
    services.tailscale = {
      enable = true;
      package = localPkgs.tailscale;
    };

    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
    };

    boot.kernel.sysctl = lib.mkIf (cfg.exitNode) {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    services.openssh.enable = true;
    programs.mosh.enable = true;
  };
}
