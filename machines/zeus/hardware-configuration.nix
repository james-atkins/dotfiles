# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/efi" =
    {
      device = "/dev/disk/by-uuid/BD51-5304";
      fsType = "vfat";
      # Use automount for data safety https://0pointer.net/blog/linux-boot-partitions.html
      options = [ "x-systemd.automount" "x-systemd.idle-timeout=5s" ];
    };

  fileSystems."/" =
    {
      device = "rpool/enc/root";
      fsType = "zfs";
    };

  fileSystems."/root" =
    {
      device = "rpool/enc/roothome";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "rpool/enc/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "rpool/enc/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/nix" =
    {
      device = "rpool/enc/nix";
      fsType = "zfs";
    };

  fileSystems."/nix/store" =
    {
      device = "rpool/nixstore";
      fsType = "zfs";
    };

  fileSystems."/var/log" =
    {
      device = "rpool/enc/log";
      fsType = "zfs";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
