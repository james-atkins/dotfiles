{ config, lib, pkgs, ... }:

let
  catppuccin-foot = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "foot";
    rev = "009cd57bd3491c65bb718a269951719f94224eb7";
    hash = "sha256-gO+ZfG2Btehp8uG+h4JE7MSFsic+Qvfzio8Um0lDGTg=";
  };
in
lib.mkIf config.ja.desktop.enable {
  fonts.packages = [ pkgs.fira-code ];

  home-manager.users.james = { pkgs, ... }: {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          include = "${catppuccin-foot}/catppuccin-latte.conf";
          font = "Fira Code:monospace:size=12";
          shell = "/usr/bin/env SHELL=fish ${pkgs.fish}/bin/fish";
        };
        mouse = {
          hide-when-typing = "yes";
        };
      };
    };

    # Jumping between prompts for fish
    # https://codeberg.org/dnkl/foot/wiki#user-content-jumping-between-prompts
    programs.fish.interactiveShellInit = ''
      function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
      end
    '';
  };
}

