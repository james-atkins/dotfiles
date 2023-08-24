{ config, lib, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    gtk = {
      enable = true;

      theme = {
        name = "Pop";
        package = pkgs.pop-gtk-theme;
      };

      iconTheme = {
        name = "Pop";
        package = pkgs.pop-icon-theme;
      };

      cursorTheme = {
        name = "Pop";
        package = pkgs.pop-icon-theme;
      };
    };

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
 
