# VPS platform layer for the shared torii-chan role (failover, ConoHa VPS):
# ConoHa is KVM/VirtIO with BIOS/MBR and a static IP from the control panel (no
# DHCP). Only ONE gateway runs at a time; when this VPS is active, its Cloudflare
# DDNS repoints torii-chan.t3u.uk and every Nebula peer reconnects.
{
  config,
  lib,
  ...
}:

let
  # RFC 5737 TEST-NET-1 addresses: never routed, so the config will NOT come up
  # until these are replaced with the panel values.
  wanIp = "192.0.2.10"; # ConoHa panel IPv4, e.g. 150.95.0.100
  wanGateway = "192.0.2.1"; # ConoHa panel default gateway
in
{
  my = {
    services = {
      # ConoHa VPS exposes the NIC as eth0.
      gateway.wanInterface = "eth0";
    };

    # SSH access comes from the shared gateway profile, so the SBC and the
    # failover VPS get the same operator key.
    user = {
      extraGroups = [ "wheel" ];
    };
  };

  # ConoHa assigns a static IPv4 and runs no DHCP for the primary NIC.
  networking = {
    # Otherwise NixOS uses predictable names (enp*s*) instead of eth0.
    usePredictableInterfaceNames = false;
    useDHCP = false;
    defaultGateway = wanGateway;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = wanIp;
          prefixLength = 24;
        }
      ];
    };
  };

  # ConoHa disks are VirtIO block devices -> /dev/vda. BIOS/MBR boot.
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/vda"; # install GRUB to the MBR
    };
  };

  # FIRST DEPLOY ONLY: hardening (restrictAccess = true) exposes SSH only via
  # nebula0, which is unreachable before the gateway role starts, so uncomment
  # the line below to open SSH on the WAN and revert it afterwards.
  # my.services.gateway.restrictAccess = lib.mkForce false;
  #
  # SOPS: the VPS decrypts the SAME secrets as the SBC (secrets/hosts/torii-chan.yaml
  # + secrets/services/ddns.yaml), so its age key must be added to .sops.yaml and to
  # both files, then `sops updatekeys` (see the README).
  #
  # 512MB plan: the swapfile keeps the low-RAM VPS buildable (mirrors the SBC
  # profile); the bootstrap keeps a single root partition /dev/vda1.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096;
    }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };
}
