{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common/users.nix
  ];

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

  time.timeZone = "America/Chicago";

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
  services.power-profiles-daemon.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # ES-60W scanner
  # https://gitlab.com/utsushi/utsushi/blob/master/README
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.utsushi ];
  services.udev.packages = [ pkgs.utsushi ];
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

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.systemPackages = with pkgs; [ firefox vscode vlc ];

  ja.services.syncthing = {
    enable = true;
    user = config.users.users.james.name;
  };

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
