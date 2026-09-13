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

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

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

    # The USB-SATA bridge is slow to appear (rootdelay) and its UAS
    # implementation is unstable: quirks 'u' disables UAS for 152d:0583.
    kernelParams = [
      "rootdelay=10"
      "usb-storage.quirks=152d:0583:u"
      "fsck.repair=yes"
    ];

    initrd.systemd.enable = true;
  };

  # WD Scorpio Blue drives rack up Load_Cycle_Count head load/unload cycles on
  # APM's defaults, which shortens their life; 255 disables APM entirely.
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
    # autodetect would probe the USB bridge directly, which needs -d sat and may
    # misbehave, so monitor only the explicitly listed device.
    autodetect = false;
    devices = [
      {
        device = "/dev/disk/by-label/NIXOS_HDD";
        options = "-d sat -a -o on -S on -n standby,q -W 0,45,55";
      }
    ];
  };
}
