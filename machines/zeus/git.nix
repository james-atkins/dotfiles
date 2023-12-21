{ config, pkgs, ... }:

let
  git-root = "/tank/code/git";

  cgit-assets = pkgs.runCommand "cgit-assets" {} ''
    mkdir $out
    cp ${pkgs.cgit}/cgit/cgit.css $out
    cp ${./bug.ico} $out/logo.ico
    cp ${./bug.png} $out/logo.png
  '';
in
{
  users.users.git = {
    uid = config.ids.uids.git;
    group = config.users.groups.git.name;
    isSystemUser = true;
    description = "git user";
    home = git-root;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = config.users.users.james.openssh.authorizedKeys.keys;
  };
  users.groups.git = {
    gid = config.ids.gids.git;
  };

  # cgit
  environment.etc."cgitrc".text = ''
    css=/assets/cgit.css
    favicon=/assets/logo.ico
    logo=/assets/logo.png

    clone-url=https://git.jamesatkins.io/$CGIT_REPO_URL git@git.jamesatkins.io:$CGIT_REPO_URL

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
    max-stats=year
    enable-http-clone=0

    source-filter=${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py
    about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh

    readme=:README.md
    readme=:README.txt
    readme=:README.html
    readme=:README

    root-title=Git Repositories
    root-desc=Source code of various projects

    section-from-path=1
    scan-path=${git-root}
  '';

  ja.private-services.git.caddy-config = ''
    handle_path /assets/* {
      file_server {
        root ${cgit-assets}
      }
    }

    @git_cgi path_regexp "^.*/(HEAD|info/refs|objects/info/[^/]+|git-upload-pack)$"
    @git_static path_regexp "^.*/objects/([0-9a-f]{2}/[0-9a-f]{38}|pack/pack-[0-9a-f]{40}\.(pack|idx))$"

    handle @git_cgi {
      reverse_proxy unix//run/cgit.socket {
        transport fastcgi {
          env SCRIPT_FILENAME "${pkgs.git}/libexec/git-core/git-http-backend"
          env GIT_HTTP_EXPORT_ALL "1"
          env GIT_PROJECT_ROOT "${git-root}"
        }
      }
    }

    handle @git_static {
      file_server {
        root ${git-root}
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
