{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption;

  cfg = config.ja.programs.msmtp;
  hostname = config.networking.hostName;
  domain = with lib; concatStrings (
    reverseList [ "s" "e" "m" "a" "j" ] ++
    reverseList [ "s" "n" "i" "k" "t" "a" ] ++
    singleton "." ++
    reverseList [ "t" "e" "n" ]
  );
in
{
  options.ja.programs.msmtp = {
    enable = mkEnableOption "Enable msmtp with Fastmail SMTP settings";
  };

  config = mkIf cfg.enable {
    environment.etc."aliases".text = ''
      root: ${hostname}@${domain}
    '';

    age.secrets.fastmail.file = ../../secrets/fastmail_${hostname}.age;
    programs.msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        auth = true;
        aliases = "/etc/aliases";
        tls = true;
        tls_starttls = false;
        port = 465;
      };
      accounts.default = {
        host = "smtp.fastmail.com";
        user = with lib; concatStrings (
          reverseList [ "s" "e" "m" "a" "j" ] ++
          reverseList [ "s" "n" "i" "k" "t" "a" ] ++
          singleton "@" ++
          reverseList [ "l" "i" "a" "m" "t" "s" "a" "f" ] ++
          singleton "." ++
          reverseList [ "k" "u" "." "o" "c" ]
        );
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.fastmail.path}";
        from = "${hostname}@${domain}";
      };
    };
  };
}
