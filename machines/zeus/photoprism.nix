{ config, lib, pkgs, ... }:

{
  services.mysql = {
    enable = true;
    ensureUsers = [
      { name = "photoprism"; ensurePermissions = { "photoprism.*" = "ALL PRIVILEGES"; }; }
    ];
    ensureDatabases = [ "photoprism" ];
  };

  services.photoprism = {
    enable = true;
    address = "localhost";
    originalsPath = "/tank/photos";
    settings = {
      PHOTOPRISM_AUTH_MODE = "public";
      PHOTOPRISM_ADMIN_USER = "james";
      PHOTOPRISM_DATABASE_DRIVER = "mysql";
      PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
      PHOTOPRISM_DATABASE_NAME = "photoprism";
    };
  };

  users.users.photoprism = {
    isSystemUser = true;
    group = config.users.groups.photoprism.name;
  };
  users.groups.photoprism = {};

  systemd.services.photoprism = {
    # Doesn't currently working with persistence
    serviceConfig.DynamicUser = lib.mkForce false;
    persist.state = true;
  };

  ja.private-services.photos.caddy-config = ''
    reverse_proxy localhost:${toString config.services.photoprism.port}
  '';

  ja.backups.databases.mysql = [ "photoprism" ];
}
