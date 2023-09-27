{ config, lib, pkgs, pkgs-unstable, global, ... }:

{
  boot = {
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    supportedFilesystems = [ "zfs" ];
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
      systemd-boot.enable = true;
    };
  };

  networking = {
    hostId = "508fcc6d";
    useNetworkd = true;
    useDHCP = false;
    interfaces.eno1.useDHCP = true;
  };
  services.resolved.enable = true;

  time.timeZone = "America/Chicago";
  services.tailscale.useRoutingFeatures = "server";

  ja.desktop.enable = true;
  ja.development.data_analysis = true;

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
          "rpool/enc/log" = false;
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

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    (writeTextDir "share/cups/model/IM9000.ppd" (builtins.readFile ./IM9000.ppd))
  ];
  environment.etc.cups.source = lib.mkForce "/persist/var/lib/cups";
  systemd.services.cups.serviceConfig.BindPaths = [ "/persist/var/lib/cups:/var/lib/cups" ];

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

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
