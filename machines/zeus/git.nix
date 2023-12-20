{ config, pkgs, ... }:

let
  cgit-assets = pkgs.runCommand "cgit-assets" {} ''
    mkdir $out
    cp ${pkgs.cgit}/cgit/cgit.css $out
    cp ${./bug.ico} $out/logo.ico
    cp ${./bug.png} $out/logo.png
  '';
in
{
  users.users.git = {
    group = config.users.groups.git.name;
    isSystemUser = true;
    description = "git user";
    home = "/tank/code/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = config.users.users.james.openssh.authorizedKeys.keys;
  };
  users.groups.git = { };

  # cgit
  environment.etc."cgitrc".text = ''
    css=/assets/cgit.css
    favicon=/assets/logo.ico
    logo=/assets/logo.png

    clone-url=git@git.jamesatkins.io:$CGIT_REPO_URL

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
    enable-index-owner=0

    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh

    readme=:README.md
    readme=:README.txt
    readme=:README.html
    readme=:README

    root-title=James Atkins Git Repositories
    root-desc=Source code of various projects

    section-from-path=1
    scan-path=/tank/code/git
  '';

  ja.private-services.git.caddy-config = ''
    handle_path /assets/* {
      file_server {
        root ${cgit-assets}
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
