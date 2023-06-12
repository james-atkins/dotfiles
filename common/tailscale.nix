{ lib, config, pkgs, pkgs-unstable, ... }:

{
  services.tailscale = {
    enable = lib.mkDefault true;
    package = pkgs-unstable.tailscale;
  };

  networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [ config.services.tailscale.interfaceName ];

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.openssh.enable = lib.mkDefault true;
  programs.mosh.enable = lib.mkDefault true;
}
