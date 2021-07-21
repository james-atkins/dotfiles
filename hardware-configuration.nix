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
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/0fbb1146-582c-4454-93b9-d45225fd4b18";
      fsType = "ext4";
    };

  fileSystems."/mnt/backup" =
    { device = "/dev/disk/by-uuid/aa653ef7-df7e-4873-9a63-cf57d668a7a8";
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
