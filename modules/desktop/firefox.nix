{ config, lib, pkgs, ... }:

let
  firefox-csshacks = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "0f1571231e73eba84ea9949584e517acbc55c1c8";
    sha256 = "sha256-v85UwA0dpkonh7PF6FNF2Q8DqZKNmGEEbVzND3JueTY=";
  };
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
      policies = {
        DontCheckDefaultBrowser = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        FirefoxHome = {
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
        };
        OfferToSaveLogins = false;
        UserMessaging = { SkipOnboarding = true; ExtensionRecommendations = false; };
      };
      profiles.default = {
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          "browser.newtabpage.pinned" = [{
            title = "Google";
            url = "https://www.google.co.uk";
          }];

          # Do not show titlebar
          "browser.tabs.inTitlebar" = 1;
          "extensions.activeThemeID" = "firefox-compact-light@mozilla.org";
        };
        userChrome = ''
          @import url("${firefox-csshacks}/chrome/linux_gtk_window_control_patch.css");
          @import url("${firefox-csshacks}/chrome/hide_tabs_with_one_tab.css");
          @import url("${firefox-csshacks}/chrome/privatemode_indicator_as_menu_button.css");
        '';
      };
    };

    xdg.mimeApps =
      let
        mimes = [
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/chrome"
          "text/html"
          "application/x-extension-htm"
          "application/x-extension-html"
          "application/x-extension-shtml"
          "application/xhtml+xml"
          "application/x-extension-xhtml"
          "application/x-extension-xht"
        ];
      in
      {
        associations.added = builtins.listToAttrs (map (m: lib.attrsets.nameValuePair m [ "firefox.desktop" ]) mimes);
        defaultApplications = builtins.listToAttrs (map (m: lib.attrsets.nameValuePair m [ "firefox.desktop" ]) mimes);
      };

  };
}
