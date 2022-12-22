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

  networking.networkmanager.enable = true;
  systemd.services.NetworkManager.persist.state = true;
  services.resolved.enable = true;

  time.timeZone = "Europe/London";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # ES-60W scanner
  # https://gitlab.com/utsushi/utsushi/blob/master/README
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.utsushi ];
  services.udev.packages = [ pkgs.utsushi ];
  home-manager.users.james.home.packages = [ pkgs.simple-scan ];

  # TODO: promote to persistence
  systemd.services.tailscaled.serviceConfig.StateDirectory = "tailscale";
  systemd.services.tailscaled.persist.state = true;

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

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11";
}
