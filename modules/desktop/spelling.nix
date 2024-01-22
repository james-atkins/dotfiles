{ config, lib, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = { pkgs, ... }: {
    home.packages = with pkgs; [
      hunspell
      hunspellDicts.en-gb-ise
      hunspellDicts.en-us
    ];
  };
}

