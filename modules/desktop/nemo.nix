{ lib, config, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  services.gvfs.enable = true;

  home-manager.users.james = { pkgs, ... }: {
    home.packages = with pkgs; [
      cinnamon.nemo-with-extensions

      gnome.file-roller
      gnome.eog
    ];

    dconf.settings = {
      "org/cinnamon/desktop/applications/terminal".exec = toString (pkgs.writeShellScript "nemo-terminal" ''
        exec-app foot "$@"
      '');
      "org/nemo/plugins".disabled-actions = [ "new-launcher.nemo_action" "change-background.nemo_action" "set-as-background.nemo_action" "add-desklets.nemo_action" ];
    };
  };
}
