{ ... }: {
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      hdd1tb1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD10EURS-630AB1_WD-WCAV5H788217";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank-1tb";
              };
            };
          };
        };
      };
      hdd1tb2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-FSLC_MAL31000SA-T72_21B1L13JTQCF";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank-1tb";
              };
            };
          };
        };
      };
      hdd320gb1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-TOSHIBA_MK3261GSYD_Z3R7P0NTT";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank-320gb";
              };
            };
          };
        };
      };
      hdd320gb2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD3200AAJS-98B4A0_WD-WCAT19003074";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank-320gb";
              };
            };
          };
        };
      };
    };
    zpool = {
      tank-1tb = {
        type = "zpool";
        mode = "mirror";
        mountpoint = "/mnt/tank-1tb";
      };
      tank-320gb = {
        type = "zpool";
        mode = "mirror";
        mountpoint = "/mnt/tank-320gb";
      };
    };
  };
}
