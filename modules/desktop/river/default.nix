{ config, lib, pkgs, pkgs-unstable, ... }:

let
  inherit (lib) mkOption mapAttrsToList;
  inherit (lib.strings) concatLines concatStringsSep toShellVar;

  cfg = config.ja.desktop;

  # systemd environment variables to set when running a wayland session
  exported-env-vars = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_SESSION_TYPE" ];

  start-river = pkgs.writeShellScriptBin "start-river" ''
    # reset failed state of all user units
    systemctl --user reset-failed

    ${concatLines (lib.mapAttrsToList (k: v: "export ${lib.strings.toShellVar k v}") cfg.wayland-environment)}

    systemd-run --user --scope --slice=session.slice --collect --quiet --unit=river ${pkgs.river}/bin/river

    # stop the session target and unset the variables
    systemctl --user start --job-mode=replace-irreversibly river-session-shutdown.target
    systemctl --user unset-environment ${concatStringsSep " " exported-env-vars}
  '';

  init-river = pkgs.writeShellScriptBin "init-river" ''
    dbus-update-activation-environment --systemd ${concatStringsSep " " exported-env-vars}
    systemctl --user start river-session.target

    . "$HOME/.config/river/init.sh"
  '';

  wofi-catppuccin = pkgs.fetchFromGitHub {
    owner = "xlce";
    repo = "wofi";
    rev = "cdaa582a1d8e9e8fcbd6e159ee337a72b0059a61";
    hash = "sha256-qG7gie09S4wXKFCRayDJnXQyOXsawkTx1xOAX2c8zJ8=";
  };

  wofi-power = pkgs.writeShellApplication {
    name = "wofi-power";
    text = ''
      entries="⮾ Lock\n⇠ Logout\n⏾ Suspend\n⭮ Reboot\n⏻ Power Off"

      selected=$(echo -e "$entries" | wofi --dmenu --insensitive --prompt Power --lines 6 --cache-file /dev/null | cut -f 2- -d ' ')

      case $selected in
        "Lock")
          ${pkgs.swaylock}/bin/swaylock -f
          ;;
        "Logout")
          riverctl exit
          ;;
        "Suspend")
          systemctl suspend
          ;;
        "Reboot")
          systemctl reboot
          ;;
        "Power Off")
          systemctl poweroff -i
          ;;
      esac
    '';
  };

  kanshi14 = pkgs-unstable.kanshi.override {
    inherit (pkgs) wayland wayland-scanner;
  };
in
{
  options.ja.desktop = {
    wallpaper = mkOption {
      type = lib.types.path;
      default = ./wallpaper.jpg;
    };

    kanshi-profiles = mkOption {
      type = lib.types.attrs;
    };

    wayland-environment = mkOption {
      type = with lib.types; attrsOf (oneOf [ str path ]);
    };
  };

  config = lib.mkIf config.ja.desktop.enable {
    fonts.packages = with pkgs; [ fira-code font-awesome_5 noto-fonts ];

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
    fonts.enableDefaultPackages = true;
    programs.dconf.enable = true;

    # Screen sharing
    xdg.portal = {
      enable = true;
      config.river.default = [ "wlr" "gtk" ];
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
    };

    services.geoclue2.enable = true;

    ja.desktop.wayland-environment = {
      XDG_CURRENT_DESKTOP = "river";

      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      CLUTTER_BACKEND = "wayland";

      # Needs qt5.qtwayland
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      # Fix for some Java AWT applications
      _JAVA_AWT_WM_NONREPARENTING = "1";

      NIXOS_OZONE_WL = "1";
    };

    home-manager.users.james = { pkgs, ... }: {
      home.packages = with pkgs; [
        river
        kanshi14
        wofi

        wofi-power

        brightnessctl
        pamixer
        pavucontrol
        qt5.qtwayland # for QT_QPA_PLATFORM=wayland
        wl-clipboard

        # todo: use exec-app?
        (pkgs.writeShellScriptBin "xterm" "exec -a $0 ${foot}/bin/foot $@")
      ];

      # Start river on login on tty1
      programs.bash.profileExtra = ''
        # If not running interactively, don't do anything
        [[ $- != *i* ]] && return

        if [[ "$(tty)" == "/dev/tty1" ]]; then
          exec ${start-river}/bin/start-river
        fi
      '';
      xdg.configFile."river/init".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${init-river}/bin/init-river";
      xdg.configFile."river/init.sh".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/river/init.sh";

      # SYSTEMD TARGETS
      # Define a river-session.target and a river-session-shutdown.target.
      # river-session-shutdown.target conflicts with river-session.target so starting the former
      # will cleanly shutdown the latter.

      systemd.user.targets.river-session = {
        Unit = {
          Description = "river compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" "xdg-desktop-autostart.target" ];
          After = [ "graphical-session-pre.target" ];
          Before = [ "xdg-desktop-autostart.target" ];
        };
      };

      systemd.user.targets.river-session-shutdown = {
        Unit = {
          Description = "shutdown running river session";
          DefaultDependencies = false;
          StopWhenUnneeded = true;
          After = [
            "graphical-session.target"
            "graphical-session-pre.target"
            "river-session.target"
          ];
          Conflicts = [
            "graphical-session.target"
            "graphical-session-pre.target"
            "river-session.target"
          ];
        };
      };

      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      services.kanshi = {
        enable = true;
        package = kanshi14;
        systemdTarget = "river-session.target";
        profiles = cfg.kanshi-profiles;
      };
      systemd.user.services.kanshi.Service.Slice = "session.slice";

      programs.swaylock = {
        enable = true;
        settings = {
          image = "${cfg.wallpaper}";
        };
      };

      services.swayidle = {
        enable = true;
        systemdTarget = "river-session.target";
        events = [
          { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
        ];
        timeouts = [
          { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
          { timeout = 600; command = "${pkgs.wlopm}/bin/wlopm --off '*'"; resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'"; }
        ];
      };
      systemd.user.services.swayidle.Service.Slice = "session.slice";

      systemd.user.services.swaybg = {
        Unit = {
          Description = "swaybg";
          Documentation = [ "man:swaybg(1)" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.swaybg}/bin/swaybg -o * -i ${cfg.wallpaper} -m fill";
          Slice = "session.slice";
        };
        Install = { WantedBy = [ "river-session.target" ]; };
      };

      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
          target = "river-session.target";
        };
      };
      systemd.user.services.waybar.Service.Slice = "session.slice";
      xdg.configFile."waybar/config".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/river/waybar_config.json";
      xdg.configFile."waybar/style.css".source = config.home-manager.users.james.lib.file.mkOutOfStoreSymlink "${config.home-manager.users.james.home.homeDirectory}/dotfiles/modules/desktop/river/waybar_style.css";

      services.mako = {
        enable = true;
      };

      services.copyq.enable = true;

      services.gammastep = {
        enable = true;
        provider = "geoclue2";
        temperature.night = 2700;
      };

      xdg.configFile."wofi/config".text = ''
        width=750
        height=400
      '';
      xdg.configFile."wofi/style.css".source = "${wofi-catppuccin}/src/latte/blue/style.css";
    };
  };
}

