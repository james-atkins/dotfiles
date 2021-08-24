{ pkgs, ... }:

let
  # Force vscode to use Wayland
  vscodeWayland = pkgs.vscode.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/${pkgs.vscode.executableName} \
        --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
    '';
  });
in
  {
    primary-user.home-manager.programs.vscode = {
      enable = true;
      package = vscodeWayland;
    };
  }
