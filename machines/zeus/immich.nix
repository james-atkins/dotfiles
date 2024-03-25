{ config, lib, pkgs, pkgs-unstable, ... }:

let
  inherit (builtins) toString;
  inherit (lib) mkAfter mkBefore;

  version = "1.99.0";

  data-dir = "/persist/var/lib/immich";
  photos-dir = "/tank/immich";
  external-dir = "/tank/photos";

  environment = {
    PUID = toString config.users.users.immich.uid;
    PGID = toString config.users.groups.immich.gid;
    DB_URL = "socket://immich:@/run/postgresql?db=immich";
    REDIS_SOCKET = config.services.redis.servers.immich.unixSocket;
    REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
  };
in
{
  users = {
    users = {
      immich = {
        isSystemUser = true;
        group = "photos";
        description = "Immich daemon user";
        home = data-dir;
        createHome = true;
        uid = 911;
      };
    };

    groups.immich = { gid = 911; };
  };

  services.postgresql = {
    ensureDatabases = [ "immich" ];
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];

    # Allow connections from any docker IP addresses
    authentication = mkBefore "host immich immich 172.16.0.0/12 md5";

    # Postgres extension pgvecto.rs required since Immich 1.91.0
    extraPlugins = [
      (pkgs-unstable.postgresqlPackages.pgvecto-rs.override rec {
        postgresql = config.services.postgresql.package;
        stdenv = postgresql.stdenv;
      })
    ];
    settings.shared_preload_libraries = "vectors.so";
  };

  # This isn't great but I struggled to get immich working without making immich a superuser...
  systemd.services.postgresql.postStart = mkAfter ''
    $PSQL -tAc 'ALTER USER immich WITH SUPERUSER;'
  '';

  services.redis.servers.immich = {
    enable = true;
    user = "immich";
  };

  systemd.services.immich-network = {
    description = "Create the network bridge for immich.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    requiredBy =
      let
        mkContainerService = name: "${config.virtualisation.oci-containers.backend}-immich-${name}.service";
      in
      map mkContainerService [ "server" "microservices" "machine-learning" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create --ignore immich";
      ExecStop = "${pkgs.podman}/bin/podman network rm immich";
    };
    path = [ config.boot.zfs.package ];
  };

  virtualisation.oci-containers.containers =
    let
      volumes = [
        "/run/postgresql:/run/postgresql"
        "${config.services.redis.servers.immich.unixSocket}:${config.services.redis.servers.immich.unixSocket}"
      ] ++ [
        "${data-dir}:/usr/src/app/upload"
        "${photos-dir}/library:/usr/src/app/upload/library"
        "${photos-dir}/upload:/usr/src/app/upload/upload"
        "${external-dir}:/usr/src/app/external:ro"
      ];
    in
    {
      immich-server = {
        image = "ghcr.io/immich-app/immich-server:v${version}";
        cmd = [ "./start-server.sh" ];

        user = "${environment.PUID}:${environment.PGID}";
        inherit environment volumes;
        extraOptions = [ "--network=immich" ];
        ports = [ "127.0.0.1:2283:3001" ];
      };

      immich-microservices = {
        image = "ghcr.io/immich-app/immich-server:v${version}";
        cmd = [ "./start-microservices.sh" ];

        user = "${environment.PUID}:${environment.PGID}";
        inherit environment volumes;
        dependsOn = [ "immich-server" ];
        extraOptions = [ "--network=immich" "--device=/dev/dri:/dev/dri" ];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v${version}";

        volumes = [
          "immich-machine-learning:/cache"
        ];

        extraOptions = [
          "--network=immich"
        ];
      };
    };

  systemd.services."${config.virtualisation.oci-containers.backend}-immich-server".serviceConfig = {
    After = [ "postgresql.service" "redis-immich.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${photos-dir}/library 0750 immich immich"
    "d ${photos-dir}/upload 0750 immich immich"
  ];

  ja.private-services.photos.caddy-config = ''
    reverse_proxy http://127.0.0.1:2283
  '';

  ja.backups.databases.postgres = [ "immich" ];
  ja.backups.paths = [ "${data-dir}/profile" photos-dir external-dir ];
}
