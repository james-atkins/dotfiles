# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common/users.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/enc/root@blank
  '';
  boot.zfs.extraPools = [ "tank" ];

  networking.hostId = "508fcc6d";
  boot.supportedFilesystems = [ "zfs" ];

  time.timeZone = "America/Chicago";

  services.tailscale.exitNode = true;
  systemd.services.tailscaled.serviceConfig.BindPaths = lib.mkForce "/persist/var/lib/tailscale:/var/lib/tailscale";

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # THIS IS VERY IMPORTANT ELSE AGENIX CANNOT DECRYPT PASSWORD FILES AT LOGIN.
  services.openssh = {
    enable = true;
    hostKeys = [
      { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
      { path = "/persist/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
    ];
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
      user = "jamesatkins@fastmail.co.uk";
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
    # Short self-test every day between 1-2am, and an extended self test weekly on Sundays between 2-3am: 
    # Ignore tracking of normalised temperature attributes - instead log temperatures of 40 degrees
    # or higher, and warn on temperatures of 45 degrees or higher.
    defaults.autodetected = "-a  -s (S/../.././01|L/../../7/02) -I 194 -W 0,40,45";
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11"; # Did you read the comment?
}
