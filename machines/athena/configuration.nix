{ config, lib, pkgs, ... }:

let
  lan = "enp1s0";
in
{
  imports = [
    ./cctv.nix
  ];

  # Erase on boot
  boot.initrd.postMountCommands = ''
    find /mnt-root -mindepth 1 -maxdepth 1 -not \( -name boot -o -name home -o -name persist -o -name nix -o -name var \) -exec rm -rf {} +
    find /mnt-root/var -mindepth 1 -maxdepth 1 -not \( -name empty -o -name log \) -exec rm -rf {} +
  '';

  time.timeZone = "Europe/London";

  networking.useDHCP = false;
  systemd.network.enable = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = lan;
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "routable";
  };

  services.openssh.enable = true;

  users.groups.photos.members = [
    config.users.users.james.name
    config.users.users.syncthing.name
  ];

  ja.services.syncthing = {
    enable = true;
    tailscaleReverseProxy = true;
  };

  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.permitCertUid = config.services.caddy.user;

  networking.firewall = {
    enable = true;
    rejectPackets = true;

    interfaces.${lan} = {
      allowedTCPPorts = [
        8554 # RTSP
      ];

      allowedUDPPorts = [
        53 # DNS
        config.services.tailscale.port
        8000
        8001
      ];
    };
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
