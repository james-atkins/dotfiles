{ config, ... }:

{
  age.secrets.miniflux.file = ../../secrets/miniflux.age;

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.age.secrets.miniflux.path;
    config.LISTEN_ADDR = "localhost:65502";
    config.AUTH_PROXY_HEADER = "X-Webauth-User";
  };

  ja.backups.databases.postgres = [ "miniflux" ];

  ja.private-services.feeds.caddy-config = ''
    reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR} {
      header_up +X-Webauth-User "james"
    }
  '';
}
