{ pkgs, ... }:

let
  # Force vscode to use Wayland
  # TODO: Only force wayland is running under wayland
  vscodeWayland =
    final: prev: {
      vscode = prev.vscode.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
        postInstall = oldAttrs.postInstall or "" + ''
          wrapProgram $out/bin/${prev.vscode.executableName} \
            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
        '';
      });
    };
in
  {
    primary-user.home-manager.programs.vscode = {
      enable = true;
    };

    nixpkgs.overlays = [ vscodeWayland ];
  }
