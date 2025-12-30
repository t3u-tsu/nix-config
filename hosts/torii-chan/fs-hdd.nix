{ config, lib, pkgs, ... }:

{
  # Filesystem configuration for HDD operation.
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_HDD";
    fsType = "ext4";
    neededForBoot = true;
  };

  # Mount the original SD card root partition as /boot.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # --- USB HDD Boot Support ---
  boot.initrd.availableKernelModules = [ 
    "usb_storage" 
    "uas" 
    "sd_mod" 
    "xhci_pci" 
    "ehci_pci" 
    "usbcore"
    "sunxi_mmc" 
    "phy_sun4i_usb"
  ];

  # Give USB devices more time to spin up and be detected (Kernel level)
  boot.kernelParams = [ "rootdelay=10" ];

  # Use systemd in initrd for more robust device discovery and mounting
  boot.initrd.systemd.enable = true;
}
