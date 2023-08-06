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

  networking.hostId = "b4bbbb9e";
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = lan;
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "routable";
  };

  services.openssh.enable = true;

  services.samba = {
    enable = true;
    enableWinbindd = false;
    openFirewall = false;  # enable the firewall manually only on the lan interface
    extraConfig = ''
      workgroup = WORKGROUP
      map to guest = bad user
      private dir = /persist/var/lib/samba/private

      # Only listen on localhost (required for smbpasswd) and lan
      # For some reason, Samba does not work on the tailscale interface
      # https://github.com/tailscale/tailscale/issues/6856#issuecomment-1485385748
      # Need to run tailscale serve tcp:445 tcp://localhost:445
      bind interfaces only = yes
      interfaces = lo ${lan}
    '';
  };
  services.samba-wsdd = {
    enable = true;
    interface = lan;
  };

  services.samba.shares = {
    "backups" = {
      path = "/tank/shares/backups";
      browseable = "yes";
      "read only" = "no";
    };
    "shared" = {
      path = "/tank/shares/shared";
      browseable = "yes";
      "read only" = "no";
      "create mask" = "0775";
      "directory mask" = "0775";
    };
  };

  users.users.richard = {
    isNormalUser = true;
  };

  users.groups.photos.members = [
    config.users.users.james.name
    config.users.users.syncthing.name
  ];

  services.borgbackup.repos = {
    milan = {
      path = "/tank/borg/milan";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEDBSisFxn2nC794UIPHOQDbNUlBDau9FVAJ8gM4VcL"
      ];
    };
  };

  age.secrets.borg_athena.file = ../../secrets/borg_athena.age;
  ja.backups = {
    enable = true;
    paths = [
      "/tank/shares"
    ];
    password-file = config.age.secrets.borg_athena.path;
  };

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
        139 445 # samba
        5357 # samba-wsdd
        8554 # mediamtx: TCP/RTSP
      ];

      allowedUDPPorts = [
        config.services.tailscale.port
        137 138 # samba
        3702 # samba-wsdd
        8000 # mediamtx: UDP/RTP
        8001 # mediamtx: UDP/RTCP
      ];
    };
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
