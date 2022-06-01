{ pkgs, ... }:

{
  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ dconf ];

  primary-user.home-manager = {
    gtk.enable = true;
    gtk.theme.name = "Adwaita";
    gtk.theme.package = pkgs.gnome.gnome-themes-extra;
    gtk.gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };
}
