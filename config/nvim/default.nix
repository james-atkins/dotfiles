{ config, pkgs , lib, ... }:

let
  # NeoVim 0.5
  neovimOverlay =
    final: prev: { 
      neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
        version = "0.5.0";
        src = builtins.fetchTarball {
          url = https://github.com/neovim/neovim/archive/refs/tags/v0.5.0.tar.gz;
          sha256 = "0lgbf90sbachdag1zm9pmnlbn35964l3khs27qy4462qzpqyi9fi";
        };
        buildInputs = oldAttrs.buildInputs ++ [ prev.tree-sitter ];
      });
    };

  neovimConfigDirs = dirs: 
    builtins.listToAttrs (map (dir: { name = "nvim/${dir}"; value = { source = ./. + "/${dir}"; }; }) dirs);

  mkOutOfStoreSymlink = path:
    config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "/home/james/dotfiles/config/nvim/${path}";

  neovimConfigDirsOutOfStore = dirs:
    builtins.listToDirs (map (dir: { name = "nvim/${dir}"; value = { source = mkOutOfStoreSymlink dir; }; }) dirs);
in
  {
    nixpkgs.overlays = [ neovimOverlay ];

    primary-user.home-manager = {
      programs.neovim = {
        enable = true;
        vimAlias = true;
        vimdiffAlias = true;

        extraConfig = ''lua require('init')'';

        plugins = with pkgs.vimPlugins; [
          vim-commentary
          vim-surround
          vim-nix
          vim-pencil
          limelight-vim
          goyo-vim
          nvim-lspconfig
          nvim-compe
          nvim-treesitter
        ];

        extraPackages = with pkgs; [
          tree-sitter
          rust-analyzer
          pyright
        ];
      };

      xdg.configFile = neovimConfigDirs [ "after" "autoload" "colors" "ftdetect" "ftplugin" "lua" ];
    };
  }

