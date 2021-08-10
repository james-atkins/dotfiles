{ pkgs, ... }:

{
  primary-user.home-manager = {

    programs.firefox = { 
      enable = true;
    };

    home.packages = with pkgs; [ 
      evince
      skype
      teams
      zoom-us
      keepassxc
    ];
  };
}
