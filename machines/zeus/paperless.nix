{ config, pkgs, ... }:

let
  dataDir = "/persist/var/lib/paperless";
  mediaDir = "/tank/paperless";
in
{
  age.secrets.paperless.file = ../../secrets/paperless.age;

  services.postgresql = {
    ensureDatabases = [ "paperless" ];
    ensureUsers = [
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
    ];
  };

  services.paperless = {
    inherit dataDir mediaDir;
    enable = true;
    address = "localhost";
    passwordFile = config.age.secrets.paperless.path;
    extraConfig = {
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
    };
  };

  systemd.services.paperless-scheduler.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.paperless-task-queue.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.paperless-download-nltk-data.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.paperless-consumer.unitConfig.RequiresMountsFor = [ mediaDir ];
  systemd.services.paperless-web.unitConfig.RequiresMountsFor = [ mediaDir ];

  ja.private-services.paperless.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.paperless.port}
  '';

  ja.backups = {
    paths = [ dataDir mediaDir ];
    databases.postgres = [ "paperless" ];
  };
}
