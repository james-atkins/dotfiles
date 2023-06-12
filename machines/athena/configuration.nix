{ config, lib, pkgs, ... }:
let
  lan = "enp1s0";
  cctv = "enp2s0";

  cameras = [
    { ethernetAddress = "10:12:FB:79:29:5A"; hostName = "yard"; ipAddress = "192.168.200.10"; }
    { ethernetAddress = "10:12:FB:FD:94:06"; hostName = "front-gate"; ipAddress = "192.168.200.11"; }
  ];

in
{
  imports = [
    ../../common/users.nix
  ];

  # Erase on boot
  boot.initrd.postMountCommands = ''
    find /mnt-root -mindepth 1 -maxdepth 1 -not \( -name boot -o -name home -o -name persist -o -name nix -o -name var \) -exec rm -rf {} +
    find /mnt-root/var -mindepth 1 -maxdepth 1 -not \( -name empty -o -name log \) -exec rm -rf {} +
  '';

  time.timeZone = "Europe/London";
  networking.interfaces = {
    ${lan}.useDHCP = true;
    ${cctv} = {
      useDHCP = false;
      ipv4.addresses = [{ address = "192.168.200.1"; prefixLength = 24; }];
    };
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

  # TODO: tailscale DNS
  # DNS over HTTP / DNS over SSL
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "0.0.0.0" ];
        access-control = [ "127.0.0.0/8 allow" "::1/128 allow" "192.168.1.0/24 allow" ];
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
          "fd00::/8"
          "fe80::/10"
        ];
      };
    };
  };
  systemd.services.unbound.persist.state = true;

  services.chrony = {
    enable = true;
    extraConfig = ''
      allow 192.168.1.0/24
      allow 192.168.200.0/24
    '';
  };
  systemd.services.chronyd.serviceConfig.BindPaths = [ "/persist/var/lib/chrony:/var/lib/chrony" ];

  services.dhcpd4 = {
    enable = true;
    interfaces = [ cctv ];
    machines = cameras;
    extraConfig = ''
      subnet 192.168.200.0 netmask 255.255.255.0 {
        range 192.168.200.100 192.168.200.200;
      }
    '';
  };
  systemd.services.dhcpd4.serviceConfig.BindPaths = [ "/persist/var/lib/private/dhcpd4:/var/lib/private/dhcpd4" ];

  services.tailscale.useRoutingFeatures = "server";

  networking.firewall = {
    enable = true;
    rejectPackets = true;

    interfaces.${lan} = {
      allowedTCPPorts = [
        53 # DNS
        631 # cups
        8554 # RTSP
      ];

      allowedUDPPorts = [
        53 # DNS
        123 # NTP
        631 # cups
        config.services.tailscale.port
        8000
        8001
      ];
    };

    interfaces.${cctv} = {
      allowedUDPPorts = [
        67 # DHCP
        123 # NTP
      ];
    };

    extraCommands = ''
      iptables -A FORWARD -i ${cctv} -j nixos-fw-refuse
    '';

    extraStopCommands = ''
      iptables -D FORWARD -i ${cctv} -j nixos-fw-refuse || true
    '';
  };

  services.mediamtx = {
    enable = true;
    settings = {
      logLevel = "warn";
      readTimeout = "5s";
      writeTimeout = "5s";
      readBufferCount = 64 * 1024;
      paths =
        let
          mkMain = cam:
            {
              name = cam.hostName;
              value = {
                source = "rtsp://cctv:we%20can%20see%20you!@${cam.ipAddress}/Streaming/Channels/101";
                sourceOnDemand = true;
                sourceProtocol = "tcp";
              };
            };
          mkSub = cam:
            {
              name = "${cam.hostName}/substream";
              value = {
                source = "rtsp://cctv:we%20can%20see%20you!@${cam.ipAddress}/Streaming/Channels/102";
                sourceOnDemand = true;
                sourceProtocol = "tcp";
              };
            };
        in
        builtins.listToAttrs ((map mkMain cameras) ++ (map mkSub cameras));
    };
  };
  systemd.services.rtsp-simple-server.path = lib.mkForce [ ]; # Remove ffmpeg


  services.printing = {
    enable = true;
    startWhenNeeded = false;
    drivers = [ pkgs.hplipWithPlugin ];
    browsing = true;
    allowFrom = [ "localhost" "192.168.1.*" ];
    listenAddresses = [ "*:631" ];
    defaultShared = true;
  };

  services.avahi = {
    enable = true;
    interfaces = [ lan ];
    publish.enable = true;
    publish.userServices = true;
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
