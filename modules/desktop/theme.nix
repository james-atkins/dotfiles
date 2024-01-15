{ config, lib, pkgs, ... }:

let
  # https://github.com/riverwm/river/wiki#how-do-i-disable-gtk-decorations-eg-title-bar
  remove-decorations = ''
    /* No (default) titlebar on wayland */
    headerbar.titlebar.default-decoration {
      background: transparent;
      padding: 0;
      margin: 0 0 -19px 0;
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
  ja.desktop.wayland-environment.GTK_THEME = "Catppuccin-Latte-Compact-Blue-Light";
  home-manager.users.james = { pkgs, ... }: {
    dconf.settings."org/gnome/desktop/wm/preferences" = {
      button-layout = "";
    };

    home.pointerCursor = {
      name = "Catppuccin-Latte-Dark-Cursors";
      package = pkgs.catppuccin-cursors.latteDark;
      size = 32;
      gtk.enable = true;
    };

    gtk = {
      enable = true;

      theme = {
        name = "Catppuccin-Latte-Compact-Blue-Light";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "blue" ];
          variant = "latte";
          size = "compact";
          tweaks = [ "rimless" ];
        };
      };

      iconTheme = {
        name = "Papirus";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = "sky";
          flavor = "latte";
        };
      };

      gtk3 = {
        extraConfig = { "gtk-application-prefer-dark-theme" = 0; };
        extraCss = remove-decorations;
      };
      gtk4 = {
        extraConfig = { "gtk-application-prefer-dark-theme" = 0; };
        extraCss = remove-decorations;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };
  };
}
 
