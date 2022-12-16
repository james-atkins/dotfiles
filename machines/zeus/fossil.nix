{ pkgs, localPkgs, config, lib, ... }:

with lib;

let
  cfg = config.ja.fossil;

  museum = "/tank/fossil";
  port = 8080;
  fossilPort = 61519;  # spells FOS
  maxLatency = 30;
in {
  users.users.fossil = {
    group = config.users.groups.fossil.name;
    isSystemUser = true;
  };
  users.groups.fossil = {};

  # Allow Caddy to get HTTPS certificates from tailscale
  services.tailscale.permitCertUid = config.services.caddy.user;

  services.caddy = {
    enable = true;
    virtualHosts."${config.networking.hostName}.crocodile-major.ts.net" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString fossilPort}
      '';
    };
  };

  systemd.services.fossil-tailscale = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ]; 

    confinement = {
      enable = true;
      binSh = null;
    };
    
    serviceConfig = {
      User = config.users.users.fossil.name;
      # TODO: --errorlog
      ExecStart = "${localPkgs.fossil-tailscale}/bin/fossil ui --nobrowser --baseurl https://${config.networking.hostName}.crocodile-major.ts.net --port ${toString fossilPort} --max-latency ${toString maxLatency} ${museum}";
      Restart = "always";
      RestartSec = 3;

      # Add the directory containing the fossil repos to the chroot jail
      BindPaths = [ museum ];

      ProtectProc = "invisible";

      NoNewPrivileges = true;

      # No need for ProtectSystem or ProtectHome as we already have the root tmpfs
      PrivateIPC = true;
      PrivateUsers = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      
      SystemCallFilter = [ "@system-service" "~@privileged" "~@mount" "~@resources" ];
      SystemCallErrorNumber = "EPERM";
      SystemCallArchitectures = "native";

      CapabilityBoundingSet = "";
    };
  };

  environment.systemPackages = with pkgs; [ fossil ];
}
