{ config, pkgs, ... }:

{
  services.gitolite = {
    enable = true;
    user = "git";
    group = "git";
    dataDir = "/tank/code/git";
    adminPubkey = builtins.head config.users.users.james.openssh.authorizedKeys.keys;
  };

  # cgit
  environment.etc."cgitrc".text = ''
    css=/assets/cgit.css
    favicon=/assets/favicon.ico
    logo=/assets/cgit.png

    mimetype.gif=image/gif
    mimetype.html=text/html
    mimetype.jpg=image/jpeg
    mimetype.jpeg=image/jpeg
    mimetype.pdf=application/pdf
    mimetype.png=image/png
    mimetype.svg=image/svg+xml

    enable-commit-graph=1
    enable-log-filecount=1
    enable-log-linecount=1

    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh

    readme=:README.md
    readme=:README.txt
    readme=:README.html
    readme=:README

    scan-path /tank/code/git
  '';

  ja.private-services.git.caddy-config = ''
    handle_path /assets/* {
      file_server {
        root ${pkgs.cgit}/cgit
        hide cgit.cgi
      }
    }

    handle {
      reverse_proxy unix//run/cgit.socket {
        transport fastcgi {
          env SCRIPT_FILENAME ${pkgs.cgit}/cgit/cgit.cgi
        }
      }
    }
  '';

  systemd.sockets.cgit-fastcgi = {
    description = "cgit FastCGI socket";
    partOf = [ "cgit-fastcgi.service" ];
    listenStreams = [ "/run/cgit.socket" ];
    wantedBy = [ "sockets.target" ];
  };

  systemd.services.cgit-fastcgi = {
    after = [ "caddy.service" "cgit-fastcgi.socket" ];
    requires = [ "cgit-fastcgi.socket" ];
    wants = [ "caddy.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.fcgiwrap}/sbin/fcgiwrap -c 1";
      StandardInput = "socket";  # pass socket on FD 0
      CacheDirectory = "cgit";
      DynamicUser = true;
      ProtectHome = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
    };
  };
}
