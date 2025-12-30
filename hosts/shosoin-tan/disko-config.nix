{ disks ? [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/sdf" ], ... }: {
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = builtins.elemAt disks 0; # 480GB SSD
        content = {
          type = "gpt";
          partitions = {
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
        device = builtins.elemAt disks 1;
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
        device = builtins.elemAt disks 2;
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
        device = builtins.elemAt disks 3;
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
        device = builtins.elemAt disks 4;
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
      hdd2tb = {
        type = "disk";
        device = builtins.elemAt disks 5;
        content = {
          type = "gpt";
          partitions = {
            backup = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/backup";
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
