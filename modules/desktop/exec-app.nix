{ config, lib, pkgs, ... }:

let
  env-vars = (builtins.attrNames config.ja.desktop.wayland-environment) ++ (builtins.attrNames config.home-manager.users.james.home.sessionVariables);

  exec-app = pkgs.writeShellApplication {
    name = "exec-app";
    text = ''
      # Launch apps in the app.slice
      # See https://systemd.io/DESKTOP_ENVIRONMENTS/

      die() {
        printf '%s\n' "$1" >&2
        exit 1
      }

      if [ $# -eq 0 ]; then
        exe=$(basename "$0")
        die "Usage: ''${exe} <command_to_execute>"
      fi

      working_dir=$(pwd)
      app_id=

      while :; do
        case $1 in
          --working-directory)
            if [ "$2" ]; then
              working_dir=$2
              shift
            else
              die 'ERROR: "--working-directory" requires a non-empty option argument.'
            fi
            ;;

          --working-directory=?*)
            working_dir=''${1#*=}
            ;;

          --working-directory=)
            die 'ERROR: "--working-directory" requires a non-empty option argument.'
            ;;

          --app-id)
            if [ "$2" ]; then
              app_id=$2
              shift
            else
              die 'ERROR: "--app-id" requires a non-empty option argument.'
            fi
            ;;

          --app-id=?*)
            app_id=''${1#*=}
            ;;

          --app-id=)
            die 'ERROR: "--app-id" requires a non-empty option argument.'
            ;;

          --)
            shift
            break
            ;;

          --*)
            die "ERROR: unknown argument $1"
            ;;

          *)
            break
            ;;
        esac

        shift
      done

      full_path=$(which "$1")

      if [ -n "$app_id" ]; then
        app_id=$(systemd-escape "''${app_id}")
      else
        filename=$(basename "''${full_path}")
        app_id=$(systemd-escape "''${filename}")
      fi

      random=$(< /proc/sys/kernel/random/uuid tr -d '-')
      unit_name="app-''${app_id}@''${random}"

      shift

      systemd-run \
        --user \
        --slice=app.slice \
        --unit="$unit_name" \
        --collect \
        --working-directory="''${working_dir/#\~/$HOME}" \
        --property=ExitType=cgroup \
        --setenv=PATH \
        --setenv=XDG_ACTIVATION_TOKEN \
        ${lib.strings.concatStringsSep "\n  " (map (k: "--setenv=${k} \\") env-vars)}
        "''${full_path}" "$@"
    '';
  };

  packages = config.environment.systemPackages ++ config.home-manager.users.james.home.packages;

  # Patch desktop files so they run using exec-app
  desktop-files = pkgs.runCommand "desktop-files" { } ''
    mkdir -p $out/share/applications

    ${lib.toShellVar "packages" packages}

    for package in ''${packages[@]}; do
      if [ -d "$package/share/applications" ]; then
        for file in "$package/share/applications/"*.desktop; do
          if [ -f "$file" ]; then
            app_id=$(basename "$file" .desktop)
            new_file="$out/share/applications/''${app_id}.desktop"
            cp "$file" "$new_file"

            name=$(grep '^Name=' "$file" | cut -d '=' -f 2- | tr -d '\n')

            if grep -q '^Terminal=true' "$file"; then
              sed -i 's|^Terminal=true|Terminal=false|' "$new_file"
              if [ -n "$name" ]; then
                sed -i "s|^Exec=\(.*\)|Exec=exec-app --app-id=\"$app_id\" foot --title=\"$name\" \1|" "$new_file"
              else
                sed -i "s|^Exec=\(.*\)|Exec=exec-app --app-id=\"$app_id\" foot \1|" "$new_file"
              fi
            else
              sed -i "s|^Exec=\(.*\)|Exec=exec-app --app-id=\"$app_id\" \1|" "$new_file"
            fi
          fi
        done
      fi
    done
  '';

  desktop-files-and-icons = pkgs.symlinkJoin {
    name = "icons";
    paths = [ desktop-files ] ++ packages;
    postBuild = ''
      find $out/share -mindepth 1 -maxdepth 1 -not \( -name applications -o -name icons \) -exec rm -rf {} +
    '';
  };
in
lib.mkIf config.ja.desktop.enable {
  environment.etc."xdg-data".source = "${desktop-files}/share";
  # environment.etc."xdg-data".source = "${desktop-files-and-icons}/share";
  home-manager.users.james = {
    # Indirect via filesystem so apps continue to work when environment variables change
    xdg.systemDirs.data = [ "/etc/xdg-data" ];

    home.packages = [ exec-app ];
  };
}
