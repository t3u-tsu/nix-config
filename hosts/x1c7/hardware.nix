{
  config,
  lib,
  ...
}:

{
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # Arch Wiki's zram tuning; the NixOS reclaim defaults are late enough that
    # rustc/nix builds drove this 16 GiB machine into OOM.
    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6957b865-8bf2-49bf-97a7-9b6ccc27d015";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7709-E704";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # size is in MiB; matches RAM so a hibernation image fits (zram cannot hold
  # one, being volatile).
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16384;
    }
  ];

  # memoryPercent caps uncompressed data, not the memory actually used.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    # Above the swapfile's negative kernel priority, so zram fills first while
    # systemd skips it when picking a hibernation target.
    priority = 100;
  };
}
