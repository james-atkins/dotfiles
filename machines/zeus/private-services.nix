{ lib, config, pkgs-local, ... }:
with lib;

let
  cfg = config.ja.private-services;
in
{
  options.ja.private-services = mkOption {
    type = types.attrsOf (types.submodule ({ name, conf, ... }: {
      options = {
        caddy-config = mkOption {
          type = types.lines;
        };
      };
    }));
  };

  config = {
    systemd.sockets.tailscale-auth = {
      description = "Tailscale Authentication socket";
      partOf = [ "tailscale-auth.service" ];
      listenStreams = [ "/run/tailscale-auth.socket" ];
      wantedBy = [ "sockets.target" ];
    };

    systemd.services.tailscale-auth = {
      description = "Tailscale Authentication service";
      after = [ "caddy.service" ];
      wants = [ "caddy.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs-local.tailscale-auth}/bin/tailscale-auth";
        DynamicUser = true;
      };
    };

    services.tinydns = {
      enable = true;
      data =
        let
          zeus = "100.84.223.98";
          ttl = 300;
          aliases = mapAttrsToList (name: conf: "+${name}.jamesatkins.io:${zeus}:${toString ttl}") cfg;
        in
        concatLines ([ ".jamesatkins.io:${zeus}:ns:${toString ttl}" ] ++ aliases);
    };

    services.caddy = {
      enable = true;
      virtualHosts = mapAttrs'
        (name: conf: nameValuePair "${name}.jamesatkins.io" {
          extraConfig = ''
            					tls /persist/var/lib/acme/jamesatkins.io/cert.pem /persist/var/lib/acme/jamesatkins.io/key.pem

            					forward_auth unix/${builtins.head config.systemd.sockets.tailscale-auth.listenStreams} {
            					  uri /auth
            					  header_up Expected-Tailnet crocodile-major.ts.net. # Not sure about the dot at the end?
            					  header_up Remote-Addr {remote_host}
            					  header_up Remote-Port {remote_port}
            					  header_up Original-URI {uri}
            					  copy_headers Tailscale-User Tailscale-Name Tailscale-Login Tailscale-Tailnet Tailscale-Profile-Picture

            						@needs-auth status 4xx
            						handle_response @needs-auth {
            							error {http.reverse_proxy.status_text} {http.reverse_proxy.status_code}
            						}

            						@bad status 5xx
            						handle_response @bad {
            							error {http.reverse_proxy.status_text} {http.reverse_proxy.status_code}
            						}
            					}

            					${conf.caddy-config}
            				'';
        })
        cfg;
    };
  };
}
