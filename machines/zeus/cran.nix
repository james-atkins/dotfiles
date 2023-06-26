{ pkgs, ... }:

let
  description = "Sync CRAN to local mirror";
in
{
  ja.private-services.cran.caddy-config = ''
    root * /tank/mirror/cran
    file_server browse
  '';

  systemd.services.cran-sync = {
    inherit description;
    after = [ "network.target" ];
    requires = [ "tank-mirror-cran.mount" ];

    serviceConfig = {
      Type = "oneshot";

      ExecStart =
        let
          cran-sync = pkgs.writeShellScriptBin "cran-sync" ''
            set -euo pipefail

            ${pkgs.rsync}/bin/rsync -rptlzv --chown=root:root --delete cran.r-project.org::CRAN/src/ /tank/mirror/cran/src/
            ${pkgs.rsync}/bin/rsync -rptlzv --chown=root:root --delete cran.r-project.org::CRAN/web/ /tank/mirror/cran/web/
          '';
        in
        "${cran-sync}/bin/cran-sync";

      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      PrivateIPC = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;

      ReadWritePaths = [ "/tank/mirror/cran" ];

      SystemCallFilter = [ "@system-service" "@chown" ];
      SystemCallErrorNumber = "EPERM";
      SystemCallArchitectures = "native";
    };
  };

  systemd.timers.cran-sync = {
    inherit description;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Persistent = true;
      OnCalendar = "daily";
      RandomizedDelaySec = 60;
    };
  };
}

