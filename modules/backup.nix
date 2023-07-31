{ config, lib, pkgs, pkgs-local, ... }:

let
  inherit (builtins) any length;
  inherit (lib) mapAttrsToList mkEnableOption mkIf mkOption optionals types;

  cfg = config.ja.backups;
  description = "borgmatic backup";
  settingsFormat = pkgs.formats.yaml { };

  fingerprints = pkgs.writeText "known_hosts" ''
    de2429.rsync.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObQN4P/deJ/k4P4kXh6a9K4Q89qdyywYetp9h3nwfPo
  '';

  zfsEnabled = (length config.boot.zfs.extraPools) > 0
    || any (fsType: fsType == "zfs") (mapAttrsToList (name: value: value.fsType) config.fileSystems);

  package = if zfsEnabled then pkgs-local.borgmatic-zfs-snapshot else pkgs.borgmatic;
  command = if zfsEnabled then "${package}/bin/borgmatic-zfs-snapshot" else "${package}/bin/borgmatic";
in
{
  options.ja.backups = {
    enable = mkEnableOption "Enables backups to rsync.net";
    zfs_snapshots = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "ZFS datasets to snapshot before backing up";
    };
    paths = mkOption {
      type = with types; listOf str;
      default = [
        "/home"
      ];
      description = "paths to backup to rsync.net";
    };
    exclude = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "paths to NOT backup to rsync.net";
    };
    password-file = mkOption {
      type = types.str;
      default = config.age.secrets.borg.path;
      description = "path to file containing password of Borg repository";
    };
    databases.mysql = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "backup mysql database";
    };
    databases.postgres = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "backup postgres database";
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [{
        assertion = !config.services.borgmatic.enable;
        message = "Cannot enable ja.backups and services.borgmatic simultaneously.";
      }];

    age.secrets.borg.file = ../secrets/borg.age;

    environment.etc."borgmatic/config.yaml".source = settingsFormat.generate "config.yaml" {
      location = {
        source_directories = cfg.paths;
        repositories = [ "ssh://de2429@de2429.rsync.net/./borg/${config.networking.hostName}" ];
        exclude_patterns = [
          "/var/lib/containers"
          "/var/lib/docker"
          "/var/lib/systemd"
          "/var/lib/libvirt"
          "**/.cache"
          "**/.nix-profile"
          "**/.elm"
          "**/.direnv"
          "**/.mozilla/firefox"
        ] ++ cfg.exclude;
        exclude_caches = true;
        exclude_if_present = [
          ".nobackup"
        ];
        borgmatic_source_directory = (lib.optionalString config.ja.persistence.enable "/persist") + "/var/lib/backups/borgmatic";
      };

      retention = {
        keep_hourly = 36;
        keep_daily = 14;
        keep_weekly = 12;
        keep_monthly = 24;
        keep_yearly = 2;
      };

      storage = {
        compression = "auto,zstd,3";
        encryption_passcommand = "${pkgs.coreutils}/bin/cat ${cfg.password-file}";
        ssh_command = "ssh -o ServerAliveInterval=120 -o PubkeyAuthentication=yes -o StrictHostKeyChecking=yes -o GlobalKnownHostsFile=${fingerprints} -i /persist/etc/secrets/id_borg_ed25519";
        borg_config_directory = (lib.optionalString config.ja.persistence.enable "/persist") + "/var/lib/backups/borg";
        borg_cache_directory = (lib.optionalString config.ja.persistence.enable "/persist") + "/var/cache/backups/borg";
      };

      consistency.checks = [
        { name = "repository"; frequency = "1 week"; }
        { name = "archives"; frequency = "1 month"; }
      ];

      hooks.mysql_databases = map (db: { name = db; }) cfg.databases.mysql;
      hooks.postgresql_databases = map (db: { name = db; username = "postgres"; }) cfg.databases.postgres;
    };

    environment.etc."borgmatic/zfs-snapshots".text = lib.concatLines cfg.zfs_snapshots;
    environment.systemPackages = [ package ];

    systemd.services.borgmatic = {
      inherit description;
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = lib.optionals zfsEnabled [ pkgs.zfs ] ++
        lib.optionals (cfg.databases.mysql != [ ]) [ config.services.mysql.package ] ++
        lib.optionals (cfg.databases.postgres != [ ]) [ config.services.postgresql.package ];

      persist.state = config.ja.persistence.enable;
      persist.cache = config.ja.persistence.enable;

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${command} -v 2";
        StateDirectory = "backups";
        StateDirectoryMode = "0700";
        CacheDirectory = "backups";
        CacheDirectoryMode = "0700";

        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = mkIf config.ja.persistence.enable [ "/persist/var/lib/backups" "/persist/var/cache/backups" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        RestrictNamespaces = [ "mnt" ];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;

        SystemCallFilter = [ "@system-service" ] ++ optionals zfsEnabled [ "@mount" "unshare" ];
        SystemCallErrorNumber = "EPERM";
        SystemCallArchitectures = "native";

        # Lower CPU and I/O priority.
        Nice = 19;
        CPUSchedulingPolicy = "batch";
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
        IOWeight = 100;

        # Prevent rate limiting of borgmatic log events.
        LogRateLimitIntervalSec = 0;
      };
    };

    systemd.timers.borgmatic = {
      inherit description;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = "hourly";
        RandomizedDelaySec = 60;
      };
    };
  };
}

