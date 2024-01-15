{ pkgs, pkgs-unstable, ... }:

let
  inherit (pkgs) fetchFromGitHub;
  catppuccin-fish = fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
    hash = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
  };
in
{
  programs.bash.enable = true;

  programs.dircolors.enable = true;

  xdg.configFile."fish/themes/Catppuccin Latte.theme".source = "${catppuccin-fish}/themes/Catppuccin Latte.theme";
  programs.fish = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "James Atkins";
    userEmail = "code@jamesatkins.net";
    extraConfig = {
      init = {
        defaultBranch = "master";
      };
    };
  };

  programs.helix = {
    enable = true;
    package = pkgs-unstable.helix;
    settings = {
      theme = "catppuccin_latte";
      editor = {
        color-modes = true;
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
      };
    };
  };

  home.packages = with pkgs; [
    fossil
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };
}
