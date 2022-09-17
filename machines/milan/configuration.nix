{ config, lib, pkgs, nixpkgs, home-manager, ... }:
let
  localPkgs = import ../../pkgs/default.nix { pkgs = pkgs; };
in
{
  imports = [
    home-manager.nixosModules.home-manager
    ../../config/minimal.nix

    # Create primary-user alias
    (lib.mkAliasOptionModule [ "primary-user" "home-manager" ] [ "home-manager" "users" "james" ])
    (lib.mkAliasOptionModule [ "primary-user" "groups" ] [ "users" "users" "james" "extraGroups" ])

    ../../config/desktop/theme.nix
    ../../config/desktop/sway/default.nix
    ../../config/desktop/applications.nix

    # Development
    ../../config/nvim/default.nix
    ../../config/vscode.nix
    ../../config/misc.nix

    ../../config/data_analysis.nix
  ];

  config = {

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

    networking.hostName = "milan";
    networking.networkmanager.enable = true;

    # Enable tailscale and configure firewall accordingly: always allow
    # traffic from my tailnet and allow tailscale's UDP port through the
    # firewall.
    services.tailscale = {
      enable = true;
      package = localPkgs.tailscale;
    };
    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
    };

    time.timeZone = "America/Chicago";

    users.users = { 
      root.initialHashedPassword = "";

      james = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/james";
        description = "James Atkins";
        extraGroups = [
          "wheel"
          "networkmanager"
          "sane"
          "lp"
        ];
      };
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # ES-60W scanner
    # https://gitlab.com/utsushi/utsushi/blob/master/README
    hardware.sane.enable = true;
    hardware.sane.extraBackends = [ pkgs.utsushi ];
    services.udev.packages = [ pkgs.utsushi ];
    primary-user.home-manager.home.packages = [ pkgs.simple-scan ];

    # Wireless headphones
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    environment.systemPackages = with pkgs; [
      lm_sensors
      git
      htop
      tree
      vim
      wget
      zip unzip
    ];

    fonts.fonts = with pkgs; [
      noto-fonts
      fira-code
      fira-code-symbols
      font-awesome
      corefonts
    ];

    primary-user.home-manager.home.stateVersion = "21.05";
    system.stateVersion = "21.05";
  };
}
