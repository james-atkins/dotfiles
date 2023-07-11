{ config, lib, pkgs, ... }:
let
  inherit (lib) concatLines;
  inherit (pkgs) fetchFromGitHub runCommand writeShellApplication;

  lan = "enp1s0";
  cctv = "enp2s0";

  cameras = [
    { ethernetAddress = "10:12:FB:79:29:5A"; hostName = "yard"; ipAddress = "192.168.200.10"; }
    { ethernetAddress = "10:12:FB:FD:94:06"; hostName = "front-gate"; ipAddress = "192.168.200.11"; }
  ];

  simplecss = fetchFromGitHub {
    owner = "kevquirk";
    repo = "simple.css";
    rev = "v2.2.1";
    hash = "sha256-TbPL9ixlbQFYzXNO7DKZ31yyA5olQIV2vnH1bPA8I5E=";
  };

  mkCamHtml = cam: ''
    <figure>
      <img src="/image/${cam.hostName}.jpeg" alt="${cam.hostName}">
    </figure>
  '';

  index = ''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>CCTV</title>
      <link rel="stylesheet" href="/simple.css">
    </head>
    <body>
      <header>
        <h1>CCTV</h1>
      </header>
      <main>
        <h2>Live View</h2>
        ${concatLines (map mkCamHtml cameras)}

        <h2>Settings</h2>
        <ul>
          <li><b>Protocol: </b>RTSP</li>
          <li><b>Host/IP address: {{ .Host }}</b></li>
        </ul>
      </main>
    </body>
    </html>
  '';

  caddy-files = runCommand "cctv-caddy-files" { } ''
    mkdir $out

    cp ${simplecss}/simple.css $out/simple.css
    cat << EOF > $out/index.html
    ${index}
    EOF

    ${pkgs.gzip}/bin/gzip --keep $out/simple.css
  '';
in
{
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
        8554 # RTSP
      ];

      allowedUDPPorts = [
        53 # DNS
        123 # NTP
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

  age.secrets.cctv = {
    file = ../../secrets/cctv.age;
    owner = config.services.caddy.user;
    group = config.services.caddy.group;
  };

  services.mediamtx = {
    enable = true;
    settings = {
      api = true;
      logLevel = "warn";
      logDestinations = [ "stdout" ];
      readTimeout = "5s";
      writeTimeout = "5s";
      readBufferCount = 64 * 1024;
      paths =
        let
          mkMain = cam:
            {
              name = cam.hostName;
              value = {
                source = "rtsp://\${CCTV_USERNAME}:\${CCTV_PASSWORD}@${cam.ipAddress}/Streaming/Channels/101";
                sourceOnDemand = true;
                sourceProtocol = "tcp";
              };
            };
          mkSub = cam:
            {
              name = "${cam.hostName}/substream";
              value = {
                source = "rtsp://\${CCTV_USERNAME}:\${CCTV_PASSWORD}@${cam.ipAddress}/Streaming/Channels/102";
                sourceOnDemand = true;
                sourceProtocol = "tcp";
              };
            };
        in
        builtins.listToAttrs ((map mkMain cameras) ++ (map mkSub cameras));
    };
  };

  systemd.services.mediamtx = {
    path = lib.mkForce [ ]; # Remove ffmpeg

    serviceConfig = {
      LoadCredential = "cctv:${config.age.secrets.cctv.path}";
      ExecStartPre =
        let
          mediamtx-auth = writeShellApplication {
            name = "mediamtx-auth";
            runtimeInputs = with pkgs; [ gettext jq ];
            text = ''
              # Read credentials from environment file
              set -o allexport
              # shellcheck disable=SC1091
              source "''${CREDENTIALS_DIRECTORY}/cctv"
              set +o allexport

              # URL encode the username and password
              CCTV_USERNAME=$(echo "''${CCTV_USERNAME}" | jq -R -r @uri)
              CCTV_PASSWORD=$(echo "''${CCTV_PASSWORD}" | jq -R -r @uri)
              export CCTV_USERNAME
              export CCTV_PASSWORD

              # Substitute the config file with environment variables
              envsubst < /etc/mediamtx.yaml > "''${RUNTIME_DIRECTORY}/mediamtx.yaml"
            '';
          };
        in
        "${mediamtx-auth}/bin/mediamtx-auth";
      ExecStart = lib.mkForce ''${pkgs.mediamtx}/bin/mediamtx ''${RUNTIME_DIRECTORY}/mediamtx.yaml'';
      RuntimeDirectory = "mediamtx";
      RuntimeDirectoryMode = "0700";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."athena.crocodile-major.ts.net".extraConfig =
      let
        mkHandle = cam: ''
          handle /image/${cam.hostName}.jpeg {
            rewrite * /ISAPI/Streaming/channels/101/picture
            reverse_proxy http://${cam.ipAddress} {
              header_up Host {http.reverse_proxy.upstream.host}
              header_up Authorization "Basic {$CCTV_BASIC_AUTH}"
            }
          }
        '';

      in
      ''
        root * ${caddy-files}
        templates
      
        ${concatLines (map mkHandle cameras)}

        file_server {
          precompressed gzip
        }
      '';
  };
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.age.secrets.cctv.path;
  services.tailscale.permitCertUid = config.services.caddy.user;

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
