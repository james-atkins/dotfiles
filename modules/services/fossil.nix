{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.ja.services.fossil;
in
{
  options.ja.services.fossil = {
    enable = mkEnableOption "Enable Fossil SCM server";

    package = mkOption {
      type = types.package;
      default = pkgs.fossil;
    };

    museum = mkOption {
      type = types.path;
      default = "/var/lib/fossil";
    };

    local-auth = mkOption {
      type = types.bool;
      default = false;
    };

    localhost = mkOption {
      type = types.bool;
      default = false;
      description = "Listen only on localhost.";
    };

    base-url = mkOption {
      type = types.str;
      default = "";
    };

    port = mkOption {
      type = types.port;
      default = 61519; # spells FOS in ASCII
    };

    max-latency = mkOption {
      type = types.ints.positive;
      default = 30;
    };
  };

  config = mkIf cfg.enable {
    users.users.fossil = {
      group = config.users.groups.fossil.name;
      isSystemUser = true;
    };
    users.groups.fossil = { };

    systemd.services.fossil-tailscale = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      confinement = {
        enable = true;
        binSh = null;
      };

      serviceConfig = {
        User = config.users.users.fossil.name;
        ExecStart =
          let
            args = [ "${cfg.package}/bin/fossil" "server" ] ++
              [ "--nojail" ] ++ # the systemd service gives us the chroot jail and more!
              [ "--repolist" ] ++
              [ "--port" (toString cfg.port) ] ++
              [ "--max-latency" (toString cfg.max-latency) ] ++
              optionals cfg.localhost [ "--localhost" ] ++
              optionals cfg.local-auth [ "--localauth" ] ++
              optionals (cfg.base-url != "") [ "--baseurl" cfg.base-url ] ++
              [ cfg.museum ];
          in
          concatStringsSep " " args;

        Restart = "always";
        RestartSec = 3;

        StateDirectory = mkIf (cfg.museum == "/var/lib/fossil") "fossil";

        # Add the directory containing the fossil repos to the chroot jail
        BindPaths = mkIf (cfg.museum != "/var/lib/fossil") [ cfg.museum ];

        ProtectProc = "invisible";

        NoNewPrivileges = true;

        # No need for ProtectSystem or ProtectHome as we already have the root tmpfs
        # from confinement.enable = true
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

    environment.systemPackages = [ cfg.package ];
  };
}

