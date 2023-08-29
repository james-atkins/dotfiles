{ config, lib, pkgs, global, ... }:

let
  inherit (lib) concatLines;
  inherit (pkgs) fetchFromGitHub runCommand writeShellApplication writeText;

  cctv = "enp2s0";

  cameras = [
    { name = "yard"; mac = "10:12:FB:79:29:5A"; ip = "192.168.200.10"; }
    { name = "front-gate"; mac = "10:12:FB:FD:94:06"; ip = "192.168.200.11"; }
  ];
in
{
  systemd.network.networks."10-cctv" = {
    matchConfig.Name = cctv;
    # linkConfig.RequiredForOnline = "routable";
    networkConfig = {
      Address = "192.168.200.1/24";
      DHCPServer = true;
    };

    dhcpServerConfig = {
      EmitDNS = false;
      EmitRouter = false;
      EmitNTP = true;
      NTP = [ "_server_address" ];
    };

    dhcpServerStaticLeases = map (cam: { dhcpServerStaticLeaseConfig = { Address = cam.ip; MACAddress = cam.mac; }; }) cameras;
  };

  # Chrony provides an NTP server so the cameras know the time
  services.chrony = {
    enable = true;
    extraConfig = ''
      allow 192.168.200.0/24
    '';
  };
  systemd.services.chronyd.serviceConfig.BindPaths = [ "/persist/var/lib/chrony:/var/lib/chrony" ];


  networking.firewall = {
    enable = true;
    rejectPackets = true;

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

  age.secrets.cctv.file = ../../secrets/cctv.age;

  services.mediamtx = {
    enable = true;
    settings = {
      api = true;
      logLevel = "warn";
      logDestinations = [ "stdout" ];
      readTimeout = "5s";
      writeTimeout = "5s";
      readBufferCount = 1024 * 1024;
      paths =
        let
          mkMain = cam:
            {
              name = cam.name;
              value = {
                source = "rtsp://\${CCTV_USERNAME}:\${CCTV_PASSWORD}@${cam.ip}/Streaming/Channels/101";
                sourceOnDemand = true;
                sourceProtocol = "tcp";
              };
            };
          mkSub = cam:
            {
              name = "${cam.name}/substream";
              value = {
                source = "rtsp://\${CCTV_USERNAME}:\${CCTV_PASSWORD}@${cam.ip}/Streaming/Channels/102";
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
    virtualHosts."${config.networking.hostName}.${global.tailscaleDomain}".extraConfig =
      let
        mkHandle = cam: ''
          handle /image/${cam.name}.jpeg {
            rewrite * /ISAPI/Streaming/channels/101/picture
            reverse_proxy http://${cam.ip} {
              header_up Host {http.reverse_proxy.upstream.host}
              header_up Authorization "Basic {$CCTV_BASIC_AUTH}"
            }
          }
        '';

        simplecss = fetchFromGitHub {
          owner = "kevquirk";
          repo = "simple.css";
          rev = "v2.2.1";
          hash = "sha256-TbPL9ixlbQFYzXNO7DKZ31yyA5olQIV2vnH1bPA8I5E=";
        };

        mkCamHtml = cam: ''
          <figure>
            <img src="/image/${cam.name}.jpeg" alt="${cam.name}">
          </figure>
        '';

        index = writeText "index.html" ''
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
              cp ${index} $out/index.html

              ${pkgs.gzip}/bin/gzip --keep $out/simple.css
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

  systemd.services.cctv-snapshot = {
    unitConfig.RequiresMountsFor = [ "/sdcard" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          mkNetrc = cam: ''
            {
              echo "machine ${cam.ip}"
              echo "login ''${CCTV_USERNAME}"
              echo "password \"''${CCTV_PASSWORD}\""
              echo ""
            } >> "''${RUNTIME_DIRECTORY}/netrc"
          '';

          mkDownload = cam: ''
            curl --silent --show-error --fail-with-body --netrc-file "''${RUNTIME_DIRECTORY}/netrc" -o "''${output_dir}/${cam.name}_$(date +'%H%M%S').jpeg" "http://${cam.ip}/ISAPI/Streaming/channels/101/picture" &
          '';

          script = writeShellApplication {
            name = "cctv-snapshot";
            runtimeInputs = with pkgs; [ coreutils curl ];
            text = ''
              # Read credentials from environment file
              set -o allexport
              # shellcheck disable=SC1091
              source "''${CREDENTIALS_DIRECTORY}/cctv"
              set +o allexport

              # Make netrc file
              ${concatLines (map mkNetrc cameras)}

              output_dir="/sdcard/cctv/$(date +'%Y/%m/%d')"
              mkdir -p "''${output_dir}"

              ${concatLines (map mkDownload cameras)}

              wait
            '';
          };
        in
        "${script}/bin/cctv-snapshot";
      LoadCredential = "cctv:${config.age.secrets.cctv.path}";
      RuntimeDirectory = "cctv-snapshot";
    };
  };

  systemd.timers.cctv-snapshot = {
    timerConfig.OnCalendar = "minutely";
    wantedBy = [ "timers.target" ];
  };
}
