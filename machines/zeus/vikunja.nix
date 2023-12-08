{ config, lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ config.services.vikunja.database.database ];
    ensureUsers = [
      {
        name = config.services.vikunja.database.user;
        ensurePermissions = {
          "DATABASE ${config.services.vikunja.database.database}" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  ja.backups.databases.postgres = [ config.services.vikunja.database.database ];

  age.secrets.vikunja_jwt.file = ../../secrets/vikunja_jwt.age;
  services.vikunja = {
    enable = true;
    frontendScheme = "https";
    frontendHostname = "todo.jamesatkins.io";
    environmentFiles = [ config.age.secrets.vikunja_jwt.path ];
    database = {
      type = "postgres";
      host = "/run/postgresql";
      user = "vikunja";
      database = "vikunja";
    };
    settings.files.basepath = lib.mkForce "/persist/var/lib/vikunja/files";
  };
  systemd.services.vikunja-api.serviceConfig.User = "vikunja";
  systemd.services.vikunja-api.serviceConfig.Group = "vikunja";

  ja.private-services.todo.caddy-config = ''
    @paths {
      path /api/* /.well-known/* /dav/*
    }
    handle @paths {
      reverse_proxy 127.0.0.1:${toString config.services.vikunja.port}
    }

    handle {
    	encode zstd gzip
    	root * ${config.services.vikunja.package-frontend}
    	try_files {path} index.html
    	file_server
    }
  '';
}
