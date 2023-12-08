{ config, pkgs, lib, ... }:

let
  cfg = config.ja.services.nextdns-linked-ip-update;
  inherit (lib) mkIf mkEnableOption mkOption types;
in
{
  options.ja.services.nextdns-linked-ip-update = {
    enable = mkEnableOption "Enable NextDNS linked IP address updater";

    url-file = mkOption {
      type = types.path;
    };
  };
  config = mkIf cfg.enable {
    systemd.services.nextdns-linked-ip-update = {
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        LoadCredential = "url:${cfg.url-file}";
        ExecStart =
          let
            script = pkgs.writeShellScript "nextdns-linked-ip-update" ''
              ${pkgs.curl}/bin/curl --silent --show-error --fail-with-body $(cat $CREDENTIALS_DIRECTORY/url)
            '';
          in
          "${script}";
        DynamicUser = true;
      };
    };
    systemd.timers.nextdns-linked-ip-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = "hourly";
        RandomizedDelaySec = 60;
      };
    };
  };
}

