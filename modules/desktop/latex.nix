{ config, lib, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    home.packages = with pkgs; [
      texlive.combined.scheme-full

      lyx
      kile
    ];
  };
}
 
