{ lib, pkgs, ... }:

{
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
    ripgrep
    vim
    wget
  ];

  systemd.services.NetworkManager-wait-online.enable = false;
}

