{
  config,
  lib,
  pkgs,
  ...
}:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_HDD";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  # Mount the SD card as /boot.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # --- USB HDD Boot Support ---
  boot = {
    initrd.availableKernelModules = [
      "usb_storage"
      "sd_mod"
      "xhci_pci"
      "ehci_pci"
      "usbcore"
      "sunxi_mmc"
      "phy_sun4i_usb"
    ];

    kernelParams = [
      "rootdelay=10"
      "usb-storage.quirks=152d:0583:u"
      "fsck.repair=yes"
    ];

    initrd.systemd.enable = true;
  };

  # --- HDD Lifespan & Monitoring ---
  # Disable HDD APM (Advanced Power Management) to stop excessive head
  # load/unload cycles (Load_Cycle_Count). WD Scorpio Blue drives are known
  # for high LCC, which shortens drive lifespan. 255 = APM fully disabled.
  systemd.services.hdd-apm = {
    description = "Disable HDD APM for root disk";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.hdparm}/bin/hdparm -B 255 /dev/disk/by-label/NIXOS_HDD";
    };
  };

  # SMART monitoring to detect disk degradation early.
  services.smartd = {
    enable = true;
    # Monitor only the explicitly listed device. autodetect would also try
    # to probe the USB bridge directly, which needs -d sat and may misbehave.
    autodetect = false;
    devices = [
      {
        device = "/dev/disk/by-label/NIXOS_HDD";
        options = "-d sat -a -o on -S on -n standby,q -W 0,45,55";
      }
    ];
  };
}
