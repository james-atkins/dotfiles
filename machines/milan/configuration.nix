{ config, lib, pkgs, pkgs-unstable, global, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/root@blank
  '';

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "013802bf";

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 12;
    hourly = 48;
    daily = 14;
    weekly = 4;
    monthly = 6;
  };

  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  services.automatic-timezoned.enable = true;

  # Enable TLP for power management
  services.tlp = {
    enable = true;
    settings = {
      TLP_ENABLE = 1;
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
      CPU_HWP_ON_BAT = "balance_power";
      CPU_HWP_ON_AC = "performance";
    };
  };

  services.tailscale.useRoutingFeatures = "client";

  ja.backups = {
    enable = true;
    zfs_snapshots = [ "rpool/home" ];
  };
  ja.desktop.enable = true;
  ja.development.data_analysis = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    (writeTextDir "share/cups/model/IM9000.ppd" (builtins.readFile ./IM9000.ppd))
  ];
  environment.etc.cups.source = lib.mkForce "/persist/var/lib/cups";
  systemd.services.cups.serviceConfig.BindPaths = [ "/persist/var/lib/cups:/var/lib/cups" ];

  # ES-60W scanner
  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.hplipWithPlugin
      (pkgs-unstable.epsonscan2.override { withNonFreePlugins = true; })
    ];
    disabledDefaultBackends = [ "epsonds" ];
  };
  home-manager.users.james.home.packages = [ pkgs.simple-scan ];

  # Wireless headphones
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    fira-code
    fira-code-symbols
    font-awesome
    corefonts
  ];

  ja.services.syncthing = {
    enable = true;
    user = config.users.users.james.name;
  };

  # For mount.cifs, required for domain name resolution.
  environment.systemPackages = [ pkgs.cifs-utils ];
  age.secrets.smb.file = ../../secrets/james_smb.age;
  fileSystems."/mnt/athena/shared" = {
    device = "//athena.${global.tailscaleDomain}/shared";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
        ["${automount_opts},credentials=${config.age.secrets.smb.path},uid=${toString config.users.users.james.uid},gid=${toString config.users.groups.users.gid}"];
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
