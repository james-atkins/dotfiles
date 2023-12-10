{ config, lib, pkgs, global, ... }:

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

  services.zrepl = {
    enable = true;
    settings = {
      jobs = [{
        name = config.networking.hostName;
        type = "push";
        connect = {
          type = "tcp";
          address = "zeus.${global.tailscaleDomain}:8090";
        };
        filesystems = {
          "rpool<" = true;
          "rpool/root" = false;
          "rpool/nix" = false;
        };
        snapshotting = {
          type = "periodic";
          prefix = "zrepl_";
          interval = "10m";
        };
        pruning = {
          keep_sender = [
            { type = "not_replicated"; }
            { type = "regex"; negate = true; regex = "^(zrepl|zfs-auto-snap)_.*"; } # keep all snapshots that were not created by zrepl
            { type = "grid"; grid = "3x1h(keep=all) | 48x1h | 14x1d"; regex = "^(zrepl|zfs-auto-snap)_.*"; }
          ];
          keep_receiver = [
            { type = "regex"; negate = true; regex = "^(zrepl|zfs-auto-snap)_.*"; } # keep all snapshots that were not created by zrepl
            { type = "grid"; grid = "3x1h(keep=all) | 48x1h | 28x1d | 6x28d"; regex = "^(zrepl|zfs-auto-snap)_.*"; }
          ];
        };
      }];
    };
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
    extra_repositories = [ "ssh://borg@athena.${global.tailscaleDomain}/./" ];
    zfs_snapshots = [ "rpool/home" ];
  };
  ja.desktop.enable = true;
  ja.development.data_analysis = true;
  ja.virtualisation.enable = true;

  ja.desktop.kanshi-profiles = {
    undocked.outputs = [{
      criteria = "eDP-1";
      mode = "1920x1080";
      scale = 1.25;
      # position = "0,0";
    }];
    docked.outputs = [
      {
        criteria = "eDP-1";
        status = "enable";
        mode = "1920x1080";
        scale = 1.25;
        # position = "0,0";
      }
      {
        criteria = "Dell Inc. DELL D2721H 8GTFQ23";
        mode = "1920x1080";
      }
    ];
  };
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
      (pkgs.epsonscan2.override { withNonFreePlugins = true; })
    ];
    disabledDefaultBackends = [ "epsonds" ];
  };
  home-manager.users.james.home.packages = [ pkgs.simple-scan ];

  # Wireless headphones
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    fira-code
    fira-code-symbols
    font-awesome
    corefonts
  ];

  ja.services.syncthing = {
    enable = true;
    user = "james";
    group = "users";
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
      [ "${automount_opts},credentials=${config.age.secrets.smb.path},uid=${toString config.users.users.james.uid},gid=${toString config.users.groups.users.gid}" ];
  };
  fileSystems."/mnt/athena/temp" = {
    device = "//athena.${global.tailscaleDomain}/temp";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},credentials=${config.age.secrets.smb.path},uid=${toString config.users.users.james.uid},gid=${toString config.users.groups.users.gid}" ];
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
