{ lib, ... }:

{
  options.ja.desktop.enable = lib.mkEnableOption "Enable desktop";

  imports = [
    ./river
    ./exec-app.nix
    ./foot.nix
    ./applications.nix
    ./theme.nix
    ./spelling.nix
    ./nemo.nix
    ./firefox.nix
    ./latex.nix
  ];
}

