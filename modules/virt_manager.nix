{ config, lib, pkgs, ... }:

{
  options.ja.virtualisation.enable = lib.mkEnableOption "Enable virtualisation";

  config = lib.mkIf config.ja.virtualisation.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu.runAsRoot = false;
    };

    users.users.james.extraGroups = [ "libvirtd" ];
    ja.persistence.directories = [ "/var/lib/libvirt" ];

    home-manager.users.james = { pkgs, ... }: {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };

      home.packages = with pkgs; [
        virtiofsd
        virt-manager
      ];
    };
  };
}

