{ config, pkgs, pkgs-local, ... }:

let
  lan = "enp1s0";
  nextdns-config = pkgs.writeText "nextdns.config" ''
    control ''${RUNTIME_DIRECTORY}/control.socket
    listen 192.168.1.1:53
    report-client-info yes
    use-hosts yes
    mdns disabled
    profile ''${NEXTDNS_PROFILE}
    cache-size 10MB
    max-ttl 60s
  '';
in
{
  age.secrets.nextdns-bg.file = ../../secrets/nextdns_bg.age;

  services.nextdns = {
    enable = true;
    arguments = [ "-config-file" "\${RUNTIME_DIRECTORY}/config" ];
  };

  systemd.services.nextdns.serviceConfig = {
    ExecStartPre =
      let
        script = pkgs.writeShellScript "nextdns-create-config" ''
          profile=$(<''${CREDENTIALS_DIRECTORY}/profile)
          export NEXTDNS_PROFILE="$profile"
          ${pkgs.gettext}/bin/envsubst < "${nextdns-config}" > "''${RUNTIME_DIRECTORY}/config"
        '';
      in
        "${script}";
    DynamicUser = true;
    RuntimeDirectory = "nextdns";
    RuntimeDirectoryMode = "0750";
    LoadCredential = "profile:${config.age.secrets.nextdns-bg.path}";
    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
  };

  networking.firewall.interfaces.${lan} = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  systemd.services.bthomehub-hosts = {
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          script = pkgs.writeShellScript "hosts-update" ''
            ${pkgs-local.bthomehub-hosts}/bin/generate_hosts > $RUNTIME_DIRECTORY/hosts.dnsmasq
          '';
        in
          [
            "${script}"
            "+${pkgs.coreutils}/bin/cp \${RUNTIME_DIRECTORY}/hosts.dnsmasq /etc"
          ];

      DynamicUser = true;
      RuntimeDirectory = "bthomehub-hosts";
    };
  };
  systemd.timers.bthomehub-hosts = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Persistent = true;
      OnCalendar = "minutely";
      RandomizedDelaySec = 60;
    };
  };
}
