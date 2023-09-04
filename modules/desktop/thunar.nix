{ config, lib, pkgs, ... }:

let
  thunar = pkgs.xfce.thunar.override { thunarPlugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ]; };
in
lib.mkIf config.ja.desktop.enable {
  services.gvfs.enable = true;

  home-manager.users.james = { pkgs, ... }: {
    home.packages = with pkgs; [
      thunar
      xarchiver
      xfce.ristretto # image viewer
      xfce.tumbler # for thunar thumbnails
      xfce.xfconf
    ];

    xfconf.settings = {
      "thunar" = {
        "last-icon-view-zoom-level" = "THUNAR_ZOOM_LEVEL_100_PERCENT";
        "last-separator-position" = 170;
        "last-view" = "ThunarIconView";
        "last-window-maximized" = true;
        "misc-highlighting-enabled" = false;
        "misc-single-click" = false;
      };
    };
  };
}
 
