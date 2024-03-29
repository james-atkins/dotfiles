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
      full_path=$(readlink -f "$full_path")

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
        --setenv=XDG_SESSION_ID \
        --setenv=XDG_VTNR \
        --setenv=XDG_ACTIVATION_TOKEN \
        --setenv=__HM_SESS_VARS_SOURCED \
        ${lib.strings.concatStringsSep "\n  " (map (k: "--setenv=${k} \\") env-vars)}
        "''${full_path}" "$@"
    '';
  };

  packages = config.environment.systemPackages ++ config.home-manager.users.james.home.packages;

  # Patch desktop files so they run using exec-app
  desktop-files = pkgs.runCommand "desktop-files" { } ''
    mkdir $out

    ${lib.toShellVar "packages" packages}

    for package in ''${packages[@]}; do
      if [ -d "$package/share/applications" ]; then
        for file in "$package/share/applications/"*.desktop; do
          if [ -f "$file" ]; then
            app_id=$(basename "$file" .desktop)
            new_file="$out/''${app_id}.desktop"
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

    ${pkgs.desktop-file-utils}/bin/update-desktop-database $out

    ln -s ${config.home-manager.users.james.xdg.configFile."mimeapps.list".source} $out/mimeapps.list
  '';
in
lib.mkIf config.ja.desktop.enable {
  home-manager.users.james = {
    xdg.dataFile."applications".source = desktop-files;
    # The whole local applications directory is managed by us now so tell home-manager not to
    # create this file. It is symlinked in desktop-files already.
    xdg.dataFile."applications/mimeapps.list".enable = false;

    home.packages = [ exec-app ];
  };
}
