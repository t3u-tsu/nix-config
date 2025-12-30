{ ... }: {
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CT500MX500SSD1_2138E5D3C631";
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
      hdd3tb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD30EZRX-19D8PB0_WD-WCC4N1VRD00K";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/data";
              };
            };
          };
        };
      };
      hdd160gb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD1600AAJS-19M0A0_WD-WCAV3C203255";
        content = {
          type = "gpt";
          partitions = {
            scratch = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/scratch";
              };
            };
          };
        };
      };
    };
  };
}