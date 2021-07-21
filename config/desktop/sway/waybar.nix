{ pkgs, ... }:

{ 
  primary-user.home-manager.programs.waybar = {
    enable = true;

    style = builtins.readFile ./waybar.css;

    settings = [{
      layer = "top";
      position = "top";
      height = 24;

      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];

      modules-center = ["sway/window" ];

      modules-right = [
        "pulseaudio"
        "tray"
        "network"
        "battery"
        "clock"
      ];

      modules = {
        "sway/workspaces" = { 
          all-outputs = false;
        };

        "sway/window" = {
          tooltip = false;
        };

        "pulseaudio" = { 
          scroll-step = 5;
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphones = "";
            handsfree = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" ];
          };
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        };

        "network" = { 
          format-wifi = "{essid} ";
          format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        "battery" = {
          format = "{capacity}% {icon}";
          full-at = 80;
          format-icons = [ "" "" "" "" "" ];
        };
        
        "clock" = { 
          format = "{:%A %e %B %Y %H:%M %p}";
        };

      };

    }];
  };
}
