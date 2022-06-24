{ pkgs, ... }:

{
  primary-user.home-manager = {
    programs.firefox = { 
      enable = true;
    };

    home.sessionVariables = {
      ANKI_WAYLAND = 1;
    };

    home.packages = with pkgs; [ 
      anki
      evince
      skypeforlinux
      teams
      zoom-us
      keepassxc
      libreoffice-fresh
      xfce.thunar

      breeze-icons
      breeze-gtk
      breeze-qt5

      vlc
    ];
  };
}
