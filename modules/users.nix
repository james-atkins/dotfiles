{ config, lib, ... }:

let
  cfg = config.ja.users.james;
in
with lib; {
  options = {
    ja.users.james = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg {
    age.secrets.jamesPassword.file = ../secrets/password_james.age;
    users.users."james" = {
      isNormalUser = true;
      description = "James Atkins";
      passwordFile = config.age.secrets.jamesPassword.path;
      extraGroups = with lib; [ "wheel" ]
        ++ optionals config.networking.networkmanager.enable [ "networkmanager" ]
        ++ optionals config.services.printing.enable [ "lp" ]
        ++ optionals config.hardware.sane.enable [ "sane" ];
      openssh.authorizedKeys.keys = [
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBF2zwPXy8sRqpsHOTs0krU7RtGO0cSg5EDaGj4LOJ6/nL7wtOM8q/yxUpndMOKJFIKll9Bna4GS7Ft9UFEgmi3AAAAAEc3NoOg== Yubikey 5"
      ];
    };

    home-manager.users.james.imports = [ ./home.nix ];
  };
}
