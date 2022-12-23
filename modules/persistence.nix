{ lib, config, ... }:
with lib;

let
  cfg = config.ja.persistence;
in
{
  options.ja.persistence = {
    enable = mkOption {
      default = true;
      type = types.bool;
    };

    directories = mkOption {
      type = types.listOf types.path;
    };
  };
  options.systemd.services = mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      options = {
        persist = {
          state = mkOption {
            default = false;
            type = types.bool;
            description =
              "Persist service state located in the StateDirectory directory.";
          };

          cache = mkOption {
            default = false;
            type = types.bool;
            description =
              "Persist service cache located in the CacheDirectory directory.";
          };
        };
      };

      config.serviceConfig.BindPaths = mkMerge [
        (mkIf (cfg.enable && config.persist.state)
          [ "/persist/var/lib/${config.serviceConfig.StateDirectory}:/var/lib/${config.serviceConfig.StateDirectory}" ]
        )

        (mkIf (cfg.enable && config.persist.cache)
          [ "/persist/var/cache/${config.serviceConfig.CacheDirectory}:/var/cache/${config.serviceConfig.CacheDirectory}" ]
        )
      ];
    }));
  };

  config =
    let
      bindMounts = builtins.listToAttrs (
        map
          (dir: lib.nameValuePair dir {
            device = strings.normalizePath "/persist/${dir}";
            options = [ "bind" "x-gvfs-hide" ];
          })
          cfg.directories
      );
    in
    mkIf cfg.enable (mkMerge [
      {
        # TODO: Check for relative paths, not containing .. etc,
        assertions = builtins.concatLists (mapAttrsToList
          (name: service: [
            {
              assertion = service.persist.state -> service.serviceConfig ? StateDirectory;
              message = "Cannot persist state of ${name} service as serviceConfig.StateDirectory is not set.";
            }
            {
              assertion = service.persist.cache -> service.serviceConfig ? CacheDirectory;
              message = "Cannot persist cache of ${name} service as serviceConfig.CacheDirectory is not set.";
            }
            {
              assertion = service.persist.state -> (builtins.typeOf service.serviceConfig.StateDirectory == "string");
              message = "StateDirectory must be a string.";
            }
            {
              assertion = service.persist.cache -> (builtins.typeOf service.serviceConfig.CacheDirectory == "string");
              message = "CacheDirectory must be a string.";
            }
          ])
          config.systemd.services);

        ja.persistence.directories = [
          "/var/lib/nixos" # to persist user/group ids dynamically allocated by NixOS
          "/var/lib/systemd"
        ];

        fileSystems = bindMounts // { "/persist".neededForBoot = true; };

        services.openssh = {
          hostKeys = [
            { path = "/persist/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
            { path = "/persist/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
          ];
        };

        system.activationScripts = {
          "create_persistent_dirs" = {
            deps = [ "users" "groups" ];
            text =
              let
                stateDirs = concatLists (mapAttrsToList
                  (name: service: optionals service.persist.state (
                    map
                      (stateDir: rec {
                        directory = "/persist/var/lib/${stateDir}";
                        user = service.serviceConfig.User or "root";
                        group = config.users.users.${user}.group;
                        mode = service.serviceConfig.StateDirectoryMode or "0755";
                      }) [ service.serviceConfig.StateDirectory ]
                  ))
                  config.systemd.services);

                cacheDirs = concatLists (mapAttrsToList
                  (name: service: optionals service.persist.cache (
                    map
                      (cacheDir: rec {
                        directory = "/persist/var/cache/${cacheDir}";
                        user = service.serviceConfig.User or "root";
                        group = config.users.users.${user}.group;
                        mode = service.serviceConfig.CacheDirectoryMode or "0755";
                      }) [ service.serviceConfig.CacheDirectory ]
                  ))
                  config.systemd.services);

                escape = x: escapeShellArg [ x ];

                # TODO: be more careful in making directories, checking they are in the right place etc.
                mkStateDirCmds = map
                  (stateDir:
                    with stateDir; "install -d -m ${escape mode} -o ${escape user} -g ${escape group} ${escape directory}"
                  )
                  stateDirs;

                mkCacheDirCmds = map
                  (cacheDir:
                    with cacheDir; "install -d -m ${escape mode} -o ${escape user} -g ${escape group} ${escape directory}"
                  )
                  cacheDirs;

                mkBindMountDirCmds = lib.mapAttrsToList
                  (
                    dir: bm: "mkdir -p ${bm.device}"
                  )
                  bindMounts;
              in
              ''
                mkdir -p /persist/var/cache
                mkdir -p /persist/var/lib

                # Make directories for bind mounts
                ${concatStringsSep "\n" mkBindMountDirCmds}

                # Make directories for persisted services
                ${concatStringsSep "\n" mkStateDirCmds}
                ${concatStringsSep "\n" mkCacheDirCmds}
              '';
          };
        };
      }
      (mkIf config.networking.networkmanager.enable
        {
          environment.etc."NetworkManager/system-connections" = {
            source = "/persist/etc/NetworkManager/system-connections/";
          };
          system.activationScripts."create_persistent_dirs".text = ''
            mkdir -p /persist/etc/NetworkManager/system-connections
          '';
        })
      (mkIf config.services.tailscale.enable
        {
          systemd.services.tailscaled.serviceConfig.StateDirectory = "tailscale";
          systemd.services.tailscaled.persist.state = true;
        })
    ]);
}

