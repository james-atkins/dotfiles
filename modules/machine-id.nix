{ config, lib, ... }:

lib.mkIf config.ja.persistence.enable {
  boot.initrd = {
    secrets."/etc/machine-id" = "/persist/etc/machine-id";
    postMountCommands = lib.mkAfter ''
      mkdir -p /mnt-root/etc
      cp /etc/machine-id /mnt-root/etc/machine-id
    '';
  };
}
