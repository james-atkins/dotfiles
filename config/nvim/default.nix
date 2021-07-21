{ pkgs, ... }:

let
  # NeoVim 0.5
  neovimOverlay =
    final: prev: { 
      neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
        version = "master";
        src = builtins.fetchTarball {
          url = https://github.com/neovim/neovim/archive/refs/tags/v0.5.0.tar.gz;
          sha256 = "0lgbf90sbachdag1zm9pmnlbn35964l3khs27qy4462qzpqyi9fi";
        };
        buildInputs = oldAttrs.buildInputs ++ [ prev.tree-sitter ];
      });
    };
in
  {
    primary-user.home-manager.programs.neovim = {
      enable = true;
      # vimAlias = true;
      vimdiffAlias = true;
    };

    nixpkgs.overlays = [ neovimOverlay ];
  }

