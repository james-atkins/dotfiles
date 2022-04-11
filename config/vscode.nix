{ pkgs, lib, ... }:

let
  # Force vscode to use Wayland
  vscodeWayland = pkgs.vscode.overrideAttrs (oldAttrs: rec {
    # 1.66 is currently currently broken so use previous version
    # https://github.com/microsoft/vscode/issues/146349
    version = "1.65.2";
    src = pkgs.fetchurl {
      name = "VSCode_${version}_linux-x64.tar.gz";
      url = "https://update.code.visualstudio.com/${version}/linux-x64/stable";
      sha256 = "sha256-RNkbiZL07YSUHQZvRgN8BVLYIZgFiciPObYOJJ9hG3U=";
    };

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
