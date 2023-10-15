{ config, lib, pkgs, ... }:

let
  # https://github.com/riverwm/river/wiki#how-do-i-disable-gtk-decorations-eg-title-bar
  remove-decorations = ''
    /* No (default) titlebar on wayland */
    headerbar.titlebar.default-decoration {
      background: transparent;
      padding: 0;
      margin: 0 0 -17px 0;
      border: 0;
      min-height: 0;
      font-size: 0;
      box-shadow: none;
    }

    /* rm -rf window shadows */
    window.csd,             /* gtk4? */
    window.csd decoration { /* gtk3 */
      box-shadow: none;
    }
  '';
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    dconf.settings."org/gnome/desktop/wm/preferences" = {
      button-layout = "";
    };

    gtk = {
      enable = true;

      theme = {
        name = "Pop";
        package = pkgs.pop-gtk-theme;
        # TODO: Set GTK_THEME too?
      };

      iconTheme = {
        name = "Pop";
        package = pkgs.pop-icon-theme;
      };

      cursorTheme = {
        name = "Pop";
        package = pkgs.pop-icon-theme;
      };

      gtk3.extraCss = remove-decorations;
    };

    # TODO: change to gtk4.extraCss when upgrading from 23.05
    xdg.configFile."gtk-4.0/gtk.css" = { text = remove-decorations; };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    home.pointerCursor = {
      name = "Pop";
      package = pkgs.pop-icon-theme;
    };
  };
}
 
