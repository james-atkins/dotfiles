{ config, lib, global, ... }:

let
  cfg = config.services.syncthing;
  guiSocket = "/run/syncthing/gui.socket";
in
{
  services.syncthing = {
    enable = true;
    configDir = "/var/lib/syncthing";
    openDefaultPorts = true;
    guiAddress = "unix://${guiSocket}";
    devices = builtins.listToAttrs (lib.mapAttrsToList
      (name: machine:
        lib.nameValuePair name {
          id = machine.syncthing;
          # TODO: support local ip addresses
          addresses = [ "tcp://${name}.${global.tailscaleDomain}" ];
        }
      )
      (lib.filterAttrs (name: system: system.syncthing != null) global.machines));
    extraOptions.options = {
      globalAnnounceEnabled = false;
      relaysEnabled = false;
      natEnabled = false;
    };
  };

  systemd.services.syncthing = {
    persist.state = lib.mkIf config.ja.persistence.enable true;

    serviceConfig = {
      StateDirectory = "syncthing";
      RuntimeDirectory = "syncthing";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."${config.networking.hostName}.${global.tailscaleDomain}:8384" = {
      extraConfig = ''
        reverse_proxy unix/${guiSocket}
      '';
    };
  };
}

