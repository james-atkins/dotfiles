{ lib, config, pkgs, localPkgs, ... }:

let
  cfg = config.services.tailscale;
in
{
  options = {
    services.tailscale.exitNode = lib.mkEnableOption "Setup IP forwarding for Tailscale exit node";
  };

  config = {
    services.tailscale = {
      enable = true;
      package = localPkgs.tailscale;
    };

    networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [ config.services.tailscale.interfaceName ];

    networking.firewall = {
      enable = true;
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
    };

    boot.kernel.sysctl = lib.mkIf (cfg.exitNode) {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    services.openssh.enable = lib.mkDefault true;
    programs.mosh.enable = lib.mkDefault true;
  };
}
