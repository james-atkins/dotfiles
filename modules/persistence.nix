{ lib, config, ... }:
with lib;

{
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
        (mkIf config.persist.state
          [ "/persist/var/lib/${config.serviceConfig.StateDirectory}:/var/lib/${config.serviceConfig.StateDirectory}" ]
        )

        (mkIf config.persist.cache
          [ "/persist/var/cache/${config.serviceConfig.CacheDirectory}:/var/cache/${config.serviceConfig.CacheDirectory}" ]
        )
      ];
    }));
  };

  config = {
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
          in
          ''
            mkdir -p /persist/var/cache
            mkdir -p /persist/var/lib

            ${concatStringsSep "\n" mkStateDirCmds}
            ${concatStringsSep "\n" mkCacheDirCmds}
          '';
      };
    };
  };
}
