{ global, ... }:

{
  services.tinyproxy = {
    enable = true;
    settings = {
      Listen = "100.125.32.78";
      Port = 8080;
      Timeout = 600;
      Allow = "100.64.0.0/10";
    };
  };
}
