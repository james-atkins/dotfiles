{ config, lib, pkgs, pkgs-local, global, ... }:

let
  inherit (builtins) any length;
  inherit (lib) mapAttrsToList mkEnableOption mkIf mkOption optionals types;

  cfg = config.ja.backups;
  description = "borgmatic backup";
  settingsFormat = pkgs.formats.yaml { };

  fingerprints = pkgs.writeText "known_hosts" ''
    de2429.rsync.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObQN4P/deJ/k4P4kXh6a9K4Q89qdyywYetp9h3nwfPo
    athena.${global.tailscaleDomain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRNxVS63eSd0mLphv+/zax+1cxnOXW7RoNLgCiV4Uf8
  '';

  zfsEnabled = (length config.boot.zfs.extraPools) > 0
    || any (fsType: fsType == "zfs") (mapAttrsToList (name: value: value.fsType) config.fileSystems);

  # Python script that sets up the mounts for the ZFS snapshots before running borgmatic
  # This requires that the systemd unit has private mount namespaces so that they don't interfere
  # with the mounts for the main system. This is why PrivateMounts=true.
  zfsMounts = pkgs.substituteAll {
    src = ./zfs_mounts.py;
    shell = "${pkgs.python3}/bin/python3";
    isExecutable = true;

    stateDir = (lib.optionalString config.ja.persistence.enable "/persist") + "/var/lib/backups";
    cacheDir = (lib.optionalString config.ja.persistence.enable "/persist") + "/var/cache/backups";
  };

  commonConfig = {
    source_directories = cfg.paths;
    repositories = map (repo: { path = repo; }) repositories;

    borgmatic_source_directory = "/run/backups/state/borgmatic";
    borg_config_directory = "/run/backups/state/borg";
    borg_cache_directory = "/run/backups/cache/borg";

    keep_hourly = 36;
    keep_daily = 14;
    keep_weekly = 12;
    keep_monthly = 24;
    keep_yearly = 2;

    compression = "auto,zstd,3";
    encryption_passcommand = "${pkgs.coreutils}/bin/cat ${cfg.password-file}";
    ssh_command = "ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=6 -o PubkeyAuthentication=yes -o StrictHostKeyChecking=yes -o GlobalKnownHostsFile=${fingerprints} -i /persist/etc/secrets/id_borg_ed25519";

    checks = [
      { name = "repository"; frequency = "1 week"; }
      { name = "archives"; frequency = "1 month"; }
    ];
  };

  hasDatabases = length (cfg.databases.postgres ++ cfg.databases.mysql) > 0;

  command =
    if zfsEnabled then
      ''${pkgs.bash}/bin/sh -c "${zfsMounts} && ${pkgs.borgmatic}/bin/borgmatic -v 2"''
    else
      "${pkgs.borgmatic}/bin/borgmatic -v 2";

  repositories = [ "ssh://de2429@de2429.rsync.net/./borg/${config.networking.hostName}" ] ++ cfg.extra_repositories;
in
{
  options.ja.backups = {
    enable = mkEnableOption "Enables backups to rsync.net";
    extra_repositories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Extra Borg repositories to backup to";
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

    age.secrets.borg.file = ../../secrets/borg.age;

    environment.etc."borgmatic.d/data.yaml".source = settingsFormat.generate "data.yaml" (commonConfig // {
      source_directories = cfg.paths;
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
      one_file_system = false;
    });

    environment.etc."borgmatic.d/databases.yaml".source = mkIf hasDatabases (settingsFormat.generate "databases.yaml" (commonConfig // {
      mysql_databases = map (db: { name = db; }) cfg.databases.mysql;
      postgresql_databases = map (db: { name = db; username = "postgres"; }) cfg.databases.postgres;
    }));

    environment.systemPackages = [ pkgs.borgmatic ];

    systemd.services.borgmatic = {
      inherit description;
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = lib.optionals zfsEnabled [ config.boot.zfs.package ] ++
        lib.optionals (cfg.databases.mysql != [ ]) [ config.services.mysql.package ] ++
        lib.optionals (cfg.databases.postgres != [ ]) [ config.services.postgresql.package ];

      persist.state = config.ja.persistence.enable;
      persist.cache = config.ja.persistence.enable;

      serviceConfig = {
        Type = "oneshot";
        ExecStart = command;
        StateDirectory = "backups";
        StateDirectoryMode = "0700";
        CacheDirectory = "backups";
        CacheDirectoryMode = "0700";

        PrivateMounts = true;

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

        SystemCallFilter = [ "@system-service" ] ++ optionals zfsEnabled [ "@mount" ];
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

