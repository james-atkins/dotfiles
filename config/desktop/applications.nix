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
      skype
      teams
      zoom-us
      keepassxc
    ];
  };
}
