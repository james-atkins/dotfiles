{ pkgs, ... }:

{
  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  primary-user.home-manager = {
    gtk.enable = true;
    gtk.theme.name = "Adwaita";
    gtk.theme.package = pkgs.gnome.gnome_themes_standard;
    gtk.gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };
}
