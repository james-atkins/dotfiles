{ config, ... }:

let
  stateDir = "/persist/var/lib/gollum";
in
{
  services.gollum = {
    enable = true;
    mathjax = true;
    stateDir = stateDir;
    address = "127.0.0.1";
    port = 65501;
    extraConfig = ''
      module Precious
        class App
          private

          def commit_message
            return commit_options
          end

          def commit_options
            name = request.env['HTTP_TAILSCALE_NAME']
            email = request.env['HTTP_TAILSCALE_USER']

            msg = (params[:message].nil? or params[:message].empty?) ? "[no message]" : params[:message]

            commit_message = {
              message: msg,
              name: name,
              email: email
            }

            return commit_message
          end
        end
      end
    '';
  };

  ja.private-services.wiki.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.gollum.port} {
      header_up Host localhost
    }
  '';

  ja.backups.paths = [ stateDir ];
}
