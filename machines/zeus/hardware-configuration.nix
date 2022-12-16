# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/8B80-74B4";
      fsType = "vfat";
    };

  fileSystems."/" =
    { device = "rpool/enc/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "rpool/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "rpool/enc/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/home" =
    { device = "rpool/enc/home";
      fsType = "zfs";
    };

  fileSystems."/var/log" =
    { device = "rpool/enc/log";
      fsType = "zfs";
    };

  swapDevices =
    [
      { device = "/dev/disk/by-uuid/527ccd2b-7a6e-4b92-ba93-6c244381d67c"; }
      { device = "/dev/disk/by-uuid/87a23681-ff15-4e02-a720-690a4491e037"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
