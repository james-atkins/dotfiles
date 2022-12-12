{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common/users.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  # boot.loader.grub.useOSProber = true;

  boot.loader.grub.extraEntries = ''
    menuentry 'Windows 10' --class windows --class os {
      insmod part_gpt
      insmod fat
      search --no-floppy --fs-uuid --set=root CEAB-049E
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
  '';

  boot.plymouth.enable = true;

  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  time.timeZone = "America/Chicago";

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
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [ firefox vscode ];

  home-manager.users.james.home.stateVersion = "21.05";
  system.stateVersion = "21.05";
}
