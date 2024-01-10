{ global, ... }:

{
  networking.firewall.interfaces.eno1.allowedTCPPorts = [ 8080 ];
  services.tinyproxy = {
    enable = true;
    settings = {
      Listen = "192.168.0.2";
      Port = 8080;
      Timeout = 60;
      Allow = "192.168.0.0/24";
      Upstream = "http athena.${global.tailscaleDomain}:8080";
    };
  };
}
