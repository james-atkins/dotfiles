# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, pkgs-unstable, global, ... }:

{
  imports = [
    ../../common/users.nix

    ./fossil.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # zfs rollback -r rpool/enc/root@blank
  '';
  boot.zfs.extraPools = [ "tank" ];

  networking.hostId = "508fcc6d";
  boot.supportedFilesystems = [ "zfs" ];

  services.zfs.autoSnapshot = {
    enable = true;
    hourly = 48;
    daily = 28;
    weekly = 12;
    monthly = 24;
  };

  # Remote unlock over tailscale
  boot.initrd = {
    kernelModules = [ "e1000e" "tun" ];
    extraUtilsCommands = ''
      for BIN in ${pkgs.iproute2}/{s,}bin/*; do
        copy_bin_and_libs $BIN
      done

      for BIN in ${pkgs.iptables-legacy}/{s,}bin/*; do
        copy_bin_and_libs $BIN
      done

      copy_bin_and_libs ${pkgs-unstable.tailscale}/bin/.tailscale-wrapped
      copy_bin_and_libs ${pkgs-unstable.tailscale}/bin/.tailscaled-wrapped

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

      echo "zpool import tank; zfs load-key -a; killall zfs; exit" >> /root/.profile
    '';
    postMountCommands = ''
      /bin/.tailscale-wrapped logout
    '';
  };

  time.timeZone = "America/Chicago";

  users.groups.photos.members = [
    config.users.users.james.name
    config.users.users.syncthing.name
  ];

  services.tailscale.exitNode = true;

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  services.openssh.enable = true;

  ja.services.syncthing = {
    enable = true;
    tailscaleReverseProxy = true;
  };

  ja.backups = {
    enable = true;
    paths = [ "/tank" ];
    zfs_snapshots = [ "rpool/enc/home" "tank" ];
  };

  environment.etc."aliases".text = ''
    root: zeus@jamesatkins.net
  '';

  age.secrets.fastmail.file = ../../secrets/fastmail.age;
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      auth = true;
      aliases = "/etc/aliases";
      tls = true;
      tls_starttls = false;
      port = 465;
    };
    accounts.default = {
      host = "smtp.fastmail.com";
      user = with lib; concatStrings (
        reverseList [ "s" "e" "m" "a" "j" ] ++
        reverseList [ "s" "n" "i" "k" "t" "a" ] ++
        singleton "@" ++
        reverseList [ "l" "i" "a" "m" "t" "s" "a" "f" ] ++
        singleton "." ++
        reverseList [ "k" "u" "." "o" "c" ]
      );
      passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.fastmail.path}";
      from = "${config.networking.hostName}@jamesatkins.net";
    };
  };

  services.zfs.autoScrub.enable = true;
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;
  };

  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      mailer = "${pkgs.msmtp}/bin/msmtp";
    };
    # Short self-test every day between 1-2am, and an extended self test weekly on Mondays between 2-3am:
    # Ignore tracking of normalised temperature attributes - instead log temperatures of 40 degrees
    # or higher, and warn on temperatures of 45 degrees or higher.
    defaults.autodetected = "-a  -s (S/../.././01|L/../../1/02) -I 194 -W 0,40,45";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.jellyfin.persist.state = true;
  systemd.services.jellyfin.persist.cache = true;

  services.changedetection-io.enable = true;
  systemd.services.changedetection-io.persist.state = true;

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11"; # Did you read the comment?
}
