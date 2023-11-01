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

    xdg.configFile."Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open Terminal Here</name>
          <submenu></submenu>
          <unique-id>1693772796825314-1</unique-id>
          <command>exec-app --working-directory %f foot</command>
          <description>Open foot</description>
          <range></range>
          <patterns>*</patterns>
          <startup-notify/>
          <directories/>
        </action>
      </actions>
    '';
  };
}
 
