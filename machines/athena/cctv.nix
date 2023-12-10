{ config, lib, pkgs, pkgs-unstable, global, ... }:

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
    package = pkgs-unstable.mediamtx;
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
}
