{ config, lib, pkgs, ... }:

let
  vscodeWayland = pkgs.vscode.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/${pkgs.vscode.executableName} \
        --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
    '';
  });
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
    };

    programs.sioyek.enable = true;

    programs.vscode = {
      enable = true;
      package = vscodeWayland;
      enableUpdateCheck = false;
    };

    home.packages = with pkgs; [
      libreoffice
      slack
      vlc
    ];
  };
}
 
