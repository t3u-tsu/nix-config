# Host: torii-chan — VPS platform layer (failover)
#
# Everything specific to running the shared torii-chan role on a VPS instead of
# the physical Orange Pi Zero3. Intended for ONE-AT-A-TIME failover: when the
# VPS is active, its Cloudflare DDNS points torii-chan.t3u.uk to the VPS public
# IP and all WireGuard peers reconnect without reconfiguration.
#
# NOTE: adjust the network/boot/root placeholders below to your provider before deploy.
{
  config,
  lib,
  ...
}:

{
  my = {
    # The WAN interface the VPS uses for NAT. Typical names: eth0 (most),
    # enp1s0, ens3 (OpenStack), eno1. Local cloud-init images may rename it.
    services = {
      gateway.wanInterface = "eth0"; # TODO: set to your VPS interface
      # Auto-deploy from this repo (failover needs the VPS to track main too).
      deployment.comin.enable = lib.mkDefault true;
    };

    # Primary user + SSH access for the operator (same key as the rest of fleet).
    user = {
      extraGroups = [ "wheel" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };
  };

  # Root filesystem. Provider-dependent: adjust the device name to your VPS
  # (e.g. /dev/vda1 on KVM, /dev/nvme0n1p1 on NVMe cloud disks).
  fileSystems."/" = {
    device = "/dev/sda1"; # TODO: set to your provider's root device
    fsType = "ext4";
  };

  networking = {
    # Assume the provider gives the address via DHCP (standard for x86_64 VPS).
    # If cloud-init/static addressing is used, your provider image already
    # configures it and you can leave networking unmanaged.
    useDHCP = true;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  boot.loader = {
    grub = {
      enable = true;
      # Provider-dependent: most x86_64 VPS use GRUB on /dev/sda; some (KVM
      # clouds) use /dev/vda or prefer systemd-boot/EFI. Adjust before flashing.
      device = "/dev/sda"; # TODO: set to your provider's boot device
    };
  };

  # VPS typically has ample RAM; add swap here only for small instances.
  swapDevices = [ ];
}
