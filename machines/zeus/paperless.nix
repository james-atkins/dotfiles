{ config, pkgs, ... }:

{
  age.secrets.paperless.file = ../../secrets/paperless.age;

  services.paperless = {
    enable = true;
    dataDir = "/persist/var/lib/paperless";
    address = "localhost";
    passwordFile = config.age.secrets.paperless.path;
    extraConfig = {
      PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
    };
  };

  ja.private-services.paperless.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.paperless.port}
  '';
}
