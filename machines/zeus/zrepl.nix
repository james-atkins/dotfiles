{ lib, config, ... }:

{
  services.zrepl = {
    enable = true;
    settings = {
      jobs = [
        {
          name = "snap";
          type = "snap";
          filesystems = {
            "rpool<" = true;
            "rpool/enc/log" = false;
            "rpool/enc/root" = false;
            "rpool/nix" = false;

            "tank<" = true;
            "tank/mirror/cran" = false;
            "tank/tmp" = false;
            "tank/zrepl<" = false;
          };
          snapshotting = {
            type = "periodic";
            prefix = "zrepl_";
            interval = "15m";
          };
          pruning.keep = [
            { type = "grid"; grid = "3x1h(keep=all) | 48x1h | 28x1d | 6x28d"; regex = "^(zrepl|zfs-auto-snap)_.*"; }
            { type = "regex"; negate = true; regex = "^(zrepl|zfs-auto-snap)_.*"; } # keep all snapshots that were not created by zrepl
          ];
        }
        {
          name = "sink";
          type = "sink";
          serve = {
            type = "tcp";
            listen = "100.84.223.98:8090";
            listen_freebind = true;
            clients = {
              "100.125.32.78" = "athena";
              "100.106.213.82" = "milan";
              "100.119.211.143" = "rome";
            };
          };
          root_fs = "tank/zrepl";
        }
      ];
    };
  };
}
