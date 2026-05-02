{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX";
        content = {
          type = "gpt";
          partitions = {
            # Matching shosoin-tan's naming convention
            ESP = {
              priority = 1;
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            swap = {
              priority = 2;
              size = "32G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
            root = {
              priority = 3;
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
      # Extra 1TB SSD for data/games
      extra = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-FIKWOT_FN500_1TB_AA000000000000000188";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data";
                mountOptions = [ "nofail" ];
              };
            };
          };
        };
      };
    };
  };
}
