{ config, lib, pkgs, ... }:

{
  age.secrets.rootPassword.file = ../secrets/password_root.age;
  users = {
    mutableUsers = false;
    users."root".passwordFile = config.age.secrets.rootPassword.path;
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "uk";
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    jq
    lm_sensors
    nmap
    pciutils
    ripgrep
    rsync
    smartmontools
    tmux
    tree
    unzip
    usbutils
    vim
    wget
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 28d";
    };

    settings = {
      auto-optimise-store = true;
      substituters = [ "https://james-atkins.cachix.org" ];
      trusted-public-keys = [ "james-atkins.cachix.org-1:Ljm14bKUUSXidZleVQejHDjDp1lrI7Rh/2WsY5ax280=" ];
    };
  };
}
