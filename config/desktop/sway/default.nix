{ config, pkgs, lib, ... }:

{
  imports = [ ./waybar.nix ];

  primary-user.groups = [ "audio" "video" ];

  # Use Pipewire rather for sound rather than PulseAudio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Things copied from nixpkgs/sway.nix
  security.pam.services.swaylock = {};
  hardware.opengl.enable = true;
  fonts.enableDefaultFonts = true;
  programs.dconf.enable = true;

  # programs.xwayland.enable = true;

  # Screen sharing
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

  primary-user.home-manager = {
    wayland.windowManager.sway = {
      enable = true;
      # package = null;
      wrapperFeatures.gtk = true;
      config = null;
      extraSessionCommands =
        ''
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        '';
      extraConfig = builtins.readFile ./sway.config;
    };

    # Start sway on login on tty1
    programs.bash.profileExtra =
      ''
      # If not running interactively, don't do anything
      [[ $- != *i* ]] && return

      # If running from tty1 start sway
      if [[ "$(tty)" == "/dev/tty1" ]]; then
          exec systemd-cat -t sway sway
      fi
      '';

    home.packages = with pkgs; [
      qt5.qtwayland  # for QT_QPA_PLATFORM=wayland
      swaylock
      swayidle
      waybar
      wl-clipboard
      kitty
      (pkgs.writeShellScriptBin "xterm" "exec -a $0 ${kitty}/bin/kitty $@")
      wofi
      brightnessctl
      xdg-desktop-portal-wlr
      pamixer # for sound up and down
    ];

    services.gammastep = {
      enable = true;
      temperature.night = 3000;
      latitude = 42.029870;
      longitude = -87.683280;
    };
  };
}

