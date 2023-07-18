{ lib, config, pkgs, pkgs-unstable, ... }:

{
  services.tailscale = {
    enable = lib.mkDefault true;
    package = pkgs-unstable.tailscale;
  };

  networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [ config.services.tailscale.interfaceName ];
  systemd.network.networks."10-tailscale" = lib.mkIf (config.systemd.network.enable && config.services.tailscale.interfaceName != "userspace-networking") {
    matchConfig.Name = config.services.tailscale.interfaceName;
    linkConfig.Unmanaged = true;
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.openssh.enable = lib.mkDefault true;
  programs.mosh.enable = lib.mkDefault true;

  # Work-around this very annoying Tailscale bug by restarting Tailscale on resume from sleep
  # https://github.com/tailscale/tailscale/issues/8223#issuecomment-1592176312
  systemd.services.tailscale-restart = {
    description = "Restart Tailscale after suspend";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "systemctl restart tailscaled.service";
    };
    # https://github.com/systemd/systemd/issues/6364#issuecomment-316647050
    wantedBy = [ "sleep.target" ];
    after = [ "systemd-suspend.service" "systemd-hybrid-sleep.service" "systemd-hibernate.service" ];
  };
}
