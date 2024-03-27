{ config, pkgs, ... }:

{
  services.gitea = {
    enable = true;
    stateDir = "/persist/var/lib/gitea";
    repositoryRoot = "/tank/code/gitea";
    database.type = "postgres";
    settings = {
      repository = {
        ENABLE_PUSH_CREATE_USER = true;
      };
      session = {
        COOKIE_SECURE = true;
      };
      server = {
        DOMAIN = "git.jamesatkins.io";
        ROOT_URL = "https://git.jamesatkins.io/";
      };
      service = {
        DISABLE_REGISTRATION = true;
        ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
        ENABLE_REVERSE_PROXY_EMAIL = true;
      };
      security = {
        REVERSE_PROXY_AUTHENTICATION_EMAIL = "Tailscale-User";
        REVERSE_PROXY_AUTHENTICATION_FULL_NAME = "Tailscale-Name";
      };
    };
  };

  ja.private-services.git.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}
  '';
}
