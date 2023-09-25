{ config, lib, pkgs, pkgs-unstable, ... }:

let
  vscodeWayland = pkgs.vscode.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [ ] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/${pkgs.vscode.executableName} \
        --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
    '';
  });

  zulipWayland = with pkgs; symlinkJoin {
    name = zulip.name;
    paths = [ zulip ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zulip \
        --add-flags "--ozone-platform-hint=auto"
    '';
  };
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    programs.zathura = {
      enable = true;
    };

    programs.vscode = {
      enable = true;
      package = vscodeWayland;
      enableUpdateCheck = false;
    };

    home.packages = with pkgs; [
      keepassxc
      libreoffice
      lyx
      texlive.combined.scheme-medium
      pkgs-unstable.obsidian
      slack
      vlc
      zoom-us
      zulipWayland
    ];
  };
}
 
