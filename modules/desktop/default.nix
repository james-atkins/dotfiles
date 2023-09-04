{ lib, ... }:

{
  options.ja.desktop.enable = lib.mkEnableOption "Enable desktop";

  imports = [
    ./sway
    ./applications.nix
    ./theme.nix
    ./thunar.nix
    ./firefox.nix
  ];
}

