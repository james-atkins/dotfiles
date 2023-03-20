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

      kitty
      (pkgs.writeShellScriptBin "xterm" "exec -a $0 ${kitty}/bin/kitty $@")

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

