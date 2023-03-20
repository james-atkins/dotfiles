{ config, lib, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
    };

    programs.sioyek.enable = true;

    home.packages = with pkgs; [
      libreoffice
      slack
      vlc
      vscode
    ];
  };
}
 
