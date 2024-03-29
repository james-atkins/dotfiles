{ config, lib, pkgs, global, ... }:

let
  lan = "enp1s0";
in
{
  imports = [
    ./cctv.nix
    ./tinyproxy.nix
  ];

  # Erase on boot
  boot.initrd.postMountCommands = lib.mkBefore ''
    echo "Erasing your darlings"
    find /mnt-root -mindepth 1 -maxdepth 1 -not \( -name boot -o -name home -o -name persist -o -name nix -o -name var \) -exec rm -rf {} +
    find /mnt-root/var -mindepth 1 -maxdepth 1 -not \( -name empty -o -name log -o -name lib \) -exec rm -rf {} +
    find /mnt-root/var/lib -mindepth 1 -maxdepth 1 -not \( -name nixos \) -exec rm -rf {} +
  '';

  home-manager.users.james.programs.bash.initExtra = ''
    zfs mount | grep tank/enc > /dev/null || {
      echo "Unlocking encrypted volumes..."
      sudo zfs mount -la && sudo systemctl restart syncthing.service
    }
  '';

  time.timeZone = "Europe/London";

  networking.hostId = "b4bbbb9e";
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = lan;
    networkConfig = {
      DHCP = "ipv4";
      DNS = [ "1.1.1.1" "1.0.0.1" ];
    };
    linkConfig.RequiredForOnline = "routable";
  };

  services.openssh.enable = true;

  services.samba = {
    enable = true;
    enableWinbindd = false;
    openFirewall = false; # enable the firewall manually only on the lan interface
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
    "scans" = {
      path = "/tank/shares/scans";
      browseable = "yes";
      "read only" = "no";
      "create mask" = "0664";
      "force create mode" = "0664";
      "directory mask" = "0775";
      "force directory mode" = "0755";
    };
    "shared" = {
      path = "/tank/shares/shared";
      browseable = "yes";
      "read only" = "no";
      "create mask" = "0664";
      "force create mode" = "0664";
      "directory mask" = "0775";
      "force directory mode" = "0755";
    };
    "temp" = {
      path = "/tank/shares/temp";
      browseable = "yes";
      "read only" = "no";
      "create mask" = "0664";
      "force create mode" = "0664";
      "directory mask" = "0775";
      "force directory mode" = "0755";
    };
  };

  systemd.tmpfiles.rules = [
    "e /tank/shares/scans 0775 ${config.users.users.scanner.name} ${config.users.users.scanner.group} 28d"
    "e /tank/shares/temp 0775 root users 28d"
  ];

  users.users.scanner = {
    uid = 2000;
    isSystemUser = true;
    group = config.users.groups.users.name;
  };

  users.users.richard = {
    uid = 2001;
    isSystemUser = true;
    group = config.users.groups.users.name;
  };

  users.users.gilly = {
    uid = 2002;
    isSystemUser = true;
    group = config.users.groups.users.name;
  };

  users.users.annabel = {
    uid = 2003;
    isSystemUser = true;
    group = config.users.groups.users.name;
  };

  users.users.ipad = {
    uid = 2004;
    isSystemUser = true;
    group = config.users.groups.users.name;
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
    zeus = {
      path = "/tank/borg/zeus";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqQihIY2pr2qLLDUXXFCjqh54IU60wOfMlOgsijXtsQ"
      ];
    };
  };

  age.secrets.nextdns-linked-ip-url.file = ../../secrets/nextdns_bg.age;
  ja.services.nextdns-linked-ip-update = {
    enable = true;
    url-file = config.age.secrets.nextdns-linked-ip-url.path;
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
        139
        445 # samba
        5357 # samba-wsdd
        8554 # mediamtx: TCP/RTSP
      ];

      allowedUDPPorts = [
        config.services.tailscale.port
        137
        138 # samba
        3702 # samba-wsdd
        8000 # mediamtx: UDP/RTP
        8001 # mediamtx: UDP/RTCP
      ];
    };
  };

  ja.programs.msmtp.enable = true;

  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;
  };
  services.zfs.autoScrub.enable = true;

  services.zrepl = {
    enable = true;
    settings = {
      jobs = [{
        name = config.networking.hostName;
        type = "push";
        connect = {
          type = "tcp";
          address = "zeus.${global.tailscaleDomain}:8090";
        };
        filesystems = {
          "tank<" = true;
          "tank/borg" = false;
          "tank/enc/syncthing" = false;
          "tank/enc/tmp" = false;
        };
        snapshotting = {
          type = "periodic";
          prefix = "zrepl_";
          interval = "1h";
        };
        pruning = {
          keep_sender = [
            { type = "not_replicated"; }
            { type = "regex"; negate = true; regex = "^(zrepl|zfs-auto-snap)_.*"; } # keep all snapshots that were not created by zrepl
            { type = "grid"; grid = "3x1h(keep=all) | 48x1h | 14x1d"; regex = "^(zrepl|zfs-auto-snap)_.*"; }
          ];
          keep_receiver = [
            { type = "regex"; negate = true; regex = "^(zrepl|zfs-auto-snap)_.*"; } # keep all snapshots that were not created by zrepl
            { type = "grid"; grid = "3x1h(keep=all) | 48x1h | 28x1d | 6x28d"; regex = "^(zrepl|zfs-auto-snap)_.*"; }
          ];
        };
      }];
    };
  };

  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      mailer = "${pkgs.msmtp}/bin/msmtp";
    };
    # Short self-test every day between 1-2am, and an extended self test weekly on Mondays between 2-3am:
    # Ignore tracking of normalised temperature attributes - instead log temperatures of 40 degrees
    # or higher, and warn on temperatures of 45 degrees or higher.
    defaults.autodetected = "-a  -s (S/../.././01|L/../../1/02) -I 194 -W 0,40,45";
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
