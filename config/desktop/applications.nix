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
      dolphin
      evince
      gnome.nautilus
      skypeforlinux
      teams
      zoom-us
      keepassxc
      libreoffice-fresh
      xfce.thunar

      breeze-icons
      breeze-gtk
      breeze-qt5
      okular

      vlc
    ];
  };
}
