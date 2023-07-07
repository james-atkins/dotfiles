{ config, lib, ... }:

{
  # Allow root to login as postgres
  services.postgresql = {
    authentication = ''
      local  all  postgres  peer  map=root
    '';
    identMap = ''
      root  postgres  postgres
      root  root  postgres
    '';
  };

  systemd.services.postgresql = lib.mkIf config.ja.persistence.enable {
    # nixpkgs has StateDirectory set to "postgresql postgresql/VERSION" which doesn't work well
    # with persistence
    serviceConfig.StateDirectory = lib.mkForce "postgresql/${config.services.postgresql.package.psqlSchema}";
    persist.state = true;
  };
}
