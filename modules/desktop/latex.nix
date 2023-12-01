{ config, lib, pkgs, ... }:

let
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium chngcntr enumitem xpatch;
  };
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    home.packages = with pkgs; [
      tex

      lyx
      kile
    ];
  };
}
 
