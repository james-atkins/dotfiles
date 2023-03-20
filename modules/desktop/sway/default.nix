{ config, lib, pkgs, ... }:

lib.mkIf config.ja.desktop.enable {
  fonts.fonts = with pkgs; [ font-awesome_5 noto-fonts ];

  # Use Pipewire rather for sound rather than PulseAudio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Copied from nixpkgs
  security.polkit.enable = true;
  security.pam.services.swaylock = { };
  hardware.opengl.enable = true;
  fonts.enableDefaultFonts = true;
  programs.dconf.enable = true;

  # Screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
  };

  home-manager.users.james = { pkgs, ... }: {
    programs.mako = {
      enable = true;
    };

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "Fira Code:size=11,monospace:size=11";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        colors = {
          "background" = "1a1b26";
          "foreground" = "c0caf5";
          "regular0" = "15161E";
          "regular1" = "f7768e";
          "regular2" = "9ece6a";
          "regular3" = "e0af68";
          "regular4" = "7aa2f7";
          "regular5" = "bb9af7";
          "regular6" = "7dcfff";
          "regular7" = "a9b1d6";
          "bright0" = "414868";
          "bright1" = "f7768e";
          "bright2" = "9ece6a";
          "bright3" = "e0af68";
          "bright4" = "7aa2f7";
          "bright5" = "bb9af7";
          "bright6" = "7dcfff";
          "bright7" = "c0caf5";
        };
      };
    };

    # Start sway on login on tty1
    programs.bash.profileExtra = ''
      # If not running interactively, don't do anything
      [[ $- != *i* ]] && return

      # If running from tty1 start sway
      if [[ "$(tty)" == "/dev/tty1" ]]; then
          exec systemd-cat -t sway sway
      fi
    '';

    home.packages = with pkgs; [
      brightnessctl

      swaylock
      swayidle

      (pkgs.writeShellScriptBin "xterm" "exec -a $0 ${foot}/bin/foot $@")

      pavucontrol
      pamixer

      wl-clipboard
      waybar
      wofi

      qt5.qtwayland # for QT_QPA_PLATFORM=wayland
    ];

    xdg.configFile."sway/sway.config".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/sway/sway.config";

    xdg.configFile."waybar/config".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/sway/waybar_config.json";
    xdg.configFile."waybar/style.css".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/sway/waybar_style.css";

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      xwayland = true;
      config = null;
      extraConfig = ''
        include ~/.config/sway/sway.config
      '';
      extraSessionCommands = ''
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export MOZ_ENABLE_WAYLAND=1
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
  };
}

