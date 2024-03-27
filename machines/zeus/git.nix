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
      server = {
        DOMAIN = "git.jamesatkins.io";
      };
    };
  };

  ja.private-services.git.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}
  '';
}
