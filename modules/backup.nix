{ config, lib, pkgs, pkgs-local, ... }:

let
  cfg = config.ja.backups;
  fingerprints = pkgs.writeText "known_hosts" ''
    de2429.rsync.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObQN4P/deJ/k4P4kXh6a9K4Q89qdyywYetp9h3nwfPo
  '';
in
with lib; {
  options.ja.backups = {
    enable = mkEnableOption "Enables backups to rsync.net";
    zfs_snapshots = mkOption {
      type = with types; listOf str;
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
      default = [
        "/var/lib/docker"
        "/var/lib/systemd"
        "/var/lib/libvirt"
        "**/.cache"
        "**/.nix-profile"
        "**/.elm"
        "**/.direnv"
      ];
      description = "paths to NOT backup to rsync.net";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.borg.file = ../secrets/borg.age;
    services.borgmatic.enable = true;
    services.borgmatic.settings = {
      location = {
        source_directories = cfg.paths;
        repositories = [ "ssh://de2429@de2429.rsync.net/./borg/${config.networking.hostName}" ];
        exclude_patterns = cfg.exclude;
        exclude_caches = true;
        exclude_if_present = [
          ".nobackup"
        ];
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
        encryption_passcommand = "cat ${config.age.secrets.borg.path}";
        ssh_command = "ssh -o ServerAliveInterval=120 -o PubkeyAuthentication=yes -o StrictHostKeyChecking=yes -o GlobalKnownHostsFile=${fingerprints} -i /persist/etc/secrets/id_borg_ed25519";
      };

      consistency.checks = [
        { name = "repository"; frequency = "1 week"; }
        { name = "archives"; frequency = "1 month"; }
        { name = "data"; frequency = "3 months"; }
      ];
    };

    environment.etc."borgmatic/zfs-snapshots".text = lib.concatMapStrings (s: s + "\n") cfg.zfs_snapshots;
    environment.systemPackages = [ pkgs-local.borgmatic-zfs-snapshot ];
  };
}

