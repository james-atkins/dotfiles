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

  # TODO: everything managed by home-manager where possible?
  programs.sway.enable = true;
  programs.sway.extraPackages = [];

  primary-user.home-manager = {
    wayland.windowManager.sway = {
      enable = true;
      package = null;
      wrapperFeatures.gtk = true;
      config = null;
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

    # Force Firefox is use wayland
    programs.firefox.package = pkgs.firefox-wayland;

    services.gammastep = {
      enable = true;
      latitude = 50.9488;
      longitude = -0.510671;
    };
  };
}

