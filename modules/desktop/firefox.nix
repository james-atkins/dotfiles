{ config, lib, pkgs, ... }:

let
  firefox-csshacks = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "97b9f5c3d8080c4e8417377ca16103a22a3b50d1";
    sha256 = "sha256-ZbBeWE0YDyU6nJxJQejrCI/Vho1s68rFLpor8BzNEiM=";
  };
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
      profiles.default = {
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        userChrome = ''
          @import url("${firefox-csshacks}/chrome/hide_tabs_with_one_tab.css");
          @import url("${firefox-csshacks}/chrome/privatemode_indicator_as_menu_button.css");


          /* Remove close button */
          .titlebar-buttonbox-container { display:none; }
        '';
      };
    };
  };
}
