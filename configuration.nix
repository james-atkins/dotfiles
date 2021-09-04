{ config, pkgs, options, lib, ... }:

with lib.mkOption;

{
  imports =
    [
      ./hardware-configuration.nix

      # Create primary-user alias
      (lib.mkAliasOptionModule [ "primary-user" "home-manager" ] [ "home-manager" "users" "james" ])
      (lib.mkAliasOptionModule [ "primary-user" "groups" ] [ "users" "users" "james" "extraGroups" ])

      ./config/desktop/theme.nix
      ./config/desktop/sway/default.nix
      ./config/desktop/applications.nix

      # Development
      ./config/nvim/default.nix
      ./config/vscode.nix
      ./config/misc.nix
      ./config/rust.nix

      ./config/r.nix
      ./config/sqlite.nix
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

    time.timeZone = "Europe/London";

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

    home-manager.useUserPackages = true;
    home-manager.useGlobalPkgs = true;

    # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # ES-60W scanner
    # https://gitlab.com/utsushi/utsushi/blob/master/README
    hardware.sane.enable = true;
    hardware.sane.extraBackends = [ pkgs.utsushi ];
    services.udev.packages = [ pkgs.utsushi ];
    primary-user.home-manager.home.packages = [ pkgs.simple-scan ];

    environment.systemPackages = with pkgs; [
      git
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

    nix = { 
      package = pkgs.nixFlakes;
      # nixPath = [ "nixpkgs-overlays=${overlaysCompat}" ];
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      binaryCaches = [ "https://james-atkins.cachix.org" ];
      binaryCachePublicKeys = [ "james-atkins.cachix.org-1:Ljm14bKUUSXidZleVQejHDjDp1lrI7Rh/2WsY5ax280="];
    };

    nixpkgs.config.allowUnfree = true;

    primary-user.home-manager.home.stateVersion = "21.05";
    system.stateVersion = "21.05";
  };

}

