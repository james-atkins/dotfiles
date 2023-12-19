{ lib, config, pkgs, pkgs-unstable, ... }:

let
  cfg = config.ja.tailscale;
  inherit (lib) mkIf mkOption types;
in
{
  options.ja.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    unlock-on-boot = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
    };

    networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [ config.services.tailscale.interfaceName ];

    networking.firewall = {
      enable = true;
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    services.openssh.enable = lib.mkDefault true;
    programs.mosh.enable = lib.mkDefault true;

    # Work-around this very annoying Tailscale bug by restarting Tailscale on resume from sleep
    # https://github.com/tailscale/tailscale/issues/8223#issuecomment-1592176312
    systemd.services.tailscale-restart = {
      description = "Restart Tailscale after suspend";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "systemctl restart tailscaled.service";
      };
      # https://github.com/systemd/systemd/issues/6364#issuecomment-316647050
      wantedBy = [ "sleep.target" ];
      after = [ "systemd-suspend.service" "systemd-hybrid-sleep.service" "systemd-hibernate.service" ];
    };

    # Remote unlock over tailscale
    boot.initrd = mkIf cfg.unlock-on-boot {
      kernelModules = [ "tun" ];
      extraUtilsCommands = ''
        for BIN in ${pkgs.iproute2}/{s,}bin/*; do
          copy_bin_and_libs $BIN
        done

        for BIN in ${pkgs.iptables-legacy}/{s,}bin/*; do
          copy_bin_and_libs $BIN
        done

        copy_bin_and_libs ${config.services.tailscale.package}/bin/.tailscale-wrapped
        copy_bin_and_libs ${config.services.tailscale.package}/bin/.tailscaled-wrapped

        mkdir -p $out/secrets/etc/ssl/certs
        cp ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/secrets/etc/ssl/certs/ca-bundle.crt
      '';
      secrets = {
        "/etc/tailscale.secret" = "/persist/etc/tailscale.secret";
      };
      network.enable = true;
      network.ssh.enable = true;
      network.ssh.hostKeys = [
        "/persist/etc/secrets/initrd/ssh_host_rsa_key"
        "/persist/etc/secrets/initrd/ssh_host_ed25519_key"
      ];
      network.ssh.authorizedKeys = config.users.users.james.openssh.authorizedKeys.keys;
      network.postCommands = lib.mkBefore ''
        mkdir -p /var/lib/tailscale
        nohup /bin/.tailscaled-wrapped -verbose=1 -state=/var/lib/tailscale/tailscaled.state -no-logs-no-support -socket ./tailscaled.socket &
        /bin/.tailscale-wrapped --socket=./tailscaled.socket up --hostname=zeus-boot --auth-key=file:/etc/tailscale.secret

        echo "zpool import -a; zfs load-key -a; killall zfs; /bin/.tailscale-wrapped logout; exit" >> /root/.profile
      '';
      postMountCommands = ''
        /bin/.tailscale-wrapped logout
      '';
    };
  };
}
