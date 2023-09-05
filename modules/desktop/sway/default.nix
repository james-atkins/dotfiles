{ config, lib, pkgs, pkgs-local, ... }:

let
  start-sway = pkgs.writeShellScriptBin "start-sway" ''
    # reset failed state of all user units
    systemctl --user reset-failed

    systemd-run --user --scope --slice=session.slice --collect --quiet --unit=sway ${pkgs.sway}/bin/sway

    # stop the session target and unset the variables
    systemctl --user start --job-mode=replace-irreversibly sway-session.target
    systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL
  '';
in
lib.mkIf config.ja.desktop.enable {
  fonts.fonts = with pkgs; [ fira-code font-awesome_5 noto-fonts ];

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

  services.geoclue2.enable = true;

  home-manager.users.james = { pkgs, ... }: {
    services.mako = {
      enable = true;
    };

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

    # Start sway on login on tty1
    programs.bash.profileExtra = ''
      # If not running interactively, don't do anything
      [[ $- != *i* ]] && return

      # If running from tty1 start sway
      if [[ "$(tty)" == "/dev/tty1" ]]; then
        exec ${start-sway}/bin/start-sway
      fi
    '';

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature.night = 2700;
    };

    home.packages = with pkgs; [
      pkgs-local.sway-exec-app

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
      systemdIntegration = true;
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

