{ lib, ... }:

{
  options.ja.desktop.enable = lib.mkEnableOption "Enable desktop";

  imports = [
    ./river
    ./exec-app.nix
    ./foot.nix
    ./applications.nix
    ./theme.nix
    ./thunar.nix
    ./firefox.nix
  ];
}

