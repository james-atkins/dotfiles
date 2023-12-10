{ config, lib, pkgs, pkgs-local, ... }:

lib.mkIf config.ja.desktop.enable {
  fonts.packages = [ pkgs.fira-code ];

  home-manager.users.james = { pkgs, ... }: {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          include = "${pkgs-local.foot-themes}/tokyonight-storm";
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

