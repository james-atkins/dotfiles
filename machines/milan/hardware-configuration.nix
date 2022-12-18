{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4bffd80d-5f7a-4dc9-ae29-f8820f59b9ff";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/CEAB-049E";
      fsType = "vfat";
      # Use automount for data safety https://0pointer.net/blog/linux-boot-partitions.html
      options = [ "x-systemd.automount" "x-systemd.idle-timeout=5s" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/0fbb1146-582c-4454-93b9-d45225fd4b18";
      fsType = "ext4";
    };

  fileSystems."/nix/store" =
    { device = "/dev/disk/by-uuid/84adbd6f-68a8-4fe4-873d-1f066bc81704";
      fsType = "ext4";
    };

  fileSystems."/mnt/shared" =
    { device = "/dev/disk/by-uuid/DC86A63086A60ADA";
      fsType = "ntfs";
      options = [ "rw" "windows_names" "uid=1000" "gid=100" "dmask=022" "fmask=133" ];
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
