{ lib, config, ... }:

{
  services.zrepl = {
    enable = true;
    settings = {
      jobs = [{
        name = "sink";
        type = "sink";
        serve = {
          type = "tcp";
          listen = "100.84.223.98:8090";
          listen_freebind = true;
          clients = {
            "100.125.32.78" = "athena";
            "100.106.213.82" = "milan";
          };
        };
        root_fs = "tank/zrepl";
      }];
    };
  };
}
