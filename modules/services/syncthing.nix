{ config, lib, global, ... }:

with lib;

let
  cfg = config.ja.services.syncthing;
  privatePort = 61925; # for reverse proxy. 6 as high port, then s=19 and y=25
  homeDir = if cfg.user == "syncthing" then "/var/lib/syncthing" else strings.normalizePath (config.users.users.${cfg.user}.home + "/.config/syncthing");
in
{
  options.ja.services.syncthing = {
    enable = mkEnableOption "syncthing";
    user = mkOption {
      default = "syncthing";
      type = types.str;
    };
    group = mkOption {
      default = "syncthing";
      type = types.str;
    };
    port = mkOption {
      default = 8384;
      type = types.port;
    };
    tailscaleReverseProxy = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      configDir = homeDir;
      dataDir = homeDir;
      user = cfg.user;
      group = cfg.group;
      openDefaultPorts = true;
      guiAddress = if cfg.tailscaleReverseProxy then "127.0.0.1:${toString privatePort}" else "127.0.0.1:${toString cfg.port}";
      overrideFolders = false;
      overrideDevices = true;
      settings = {
        devices = builtins.listToAttrs (lib.mapAttrsToList
          (name: machine:
            lib.nameValuePair name {
              id = machine.syncthing;
              addresses = [ "dynamic" "tcp://${name}.${global.tailscaleDomain}" ];
            }
          )
          (lib.filterAttrs (name: system: name != config.networking.hostName && system.syncthing != null) global.machines));

        globalAnnounceEnabled = false;
        relaysEnabled = false;
        natEnabled = false;
      };
    };

    systemd.services.syncthing.serviceConfig = {
      BindPaths = mkIf (cfg.user == "syncthing" && config.ja.persistence.enable) [
        "/persist/var/lib/syncthing:/var/lib/syncthing"
      ];
      # Grant extra capabilities https://docs.syncthing.net/v1.23.4/advanced/folder-sync-ownership#elevated-permissions
      AmbientCapabilities = [ "CAP_CHOWN" "CAP_FOWNER" ];
    };

    systemd.services.syncthing-init.serviceConfig = {
      BindPaths = mkIf (cfg.user == "syncthing" && config.ja.persistence.enable) [
        "/persist/var/lib/syncthing:/var/lib/syncthing"
      ];
    };

    services.caddy = mkIf cfg.tailscaleReverseProxy {
      enable = true;
      virtualHosts."http://${config.networking.hostName}.${global.tailscaleDomain}:${toString cfg.port}" = {
        # https://docs.syncthing.net/users/faq.html#why-do-i-get-host-check-error-in-the-gui-api
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString privatePort} {
            header_up Host localhost:${toString privatePort}
          }
        '';
      };
    };
  };
}

