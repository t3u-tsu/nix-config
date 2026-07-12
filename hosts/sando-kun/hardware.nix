# hosts/sando-kun/hardware.nix - Filesystem and boot configuration
{ config, lib, ... }:
{
  # Main HDD (250GB) - System
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part2";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part3";
    fsType = "ext4";
  };

  # Secondary HDD (80GB) - Scratch
  fileSystems."/mnt/scratch" = {
    device = "/dev/disk/by-id/ata-WDC_WD800BEVS-22RST0_WD-WXC907053724-part1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
