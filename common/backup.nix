{ config, lib, pkgs, ... }:

let cfg = config.ja.backups;
in with lib; {
  options.ja.backups = {
    enable = mkEnableOption "Enables backups to rsync.net";
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
        ssh_command = "ssh -o PubkeyAuthentication=yes -i /persist/etc/secrets/id_borg_ed25519";
      };

      consistency.checks = [
        { name = "repository"; frequency = "1 week"; }
        { name = "archives"; frequency = "1 month"; }
        { name = "data"; frequency = "3 months"; }
      ];
    };
  };
}

