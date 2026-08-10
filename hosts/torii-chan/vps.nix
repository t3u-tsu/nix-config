# Host: torii-chan — VPS platform layer (failover, ConoHa VPS)
#
# Everything specific to running the shared torii-chan role on a VPS instead of
# the physical Orange Pi Zero3. Intended for ONE-AT-A-TIME failover: when the
# VPS is active, its Cloudflare DDNS points torii-chan.t3u.uk to the VPS public
# IP and all Nebula peers reconnect without reconfiguration.
#
# Target provider: ConoHa VPS (GMO). KVM/VirtIO, BIOS/MBR, static IP assigned
# in the control panel (no DHCP by default). Tokyo/Osaka region, hourly billing.
#
# BEFORE DEPLOY: replace the TEST-NET placeholders below (192.0.2.x) with the
# real static IPv4 / gateway shown in the ConoHa control panel.
{
  config,
  lib,
  ...
}:

let
  # RFC 5737 TEST-NET-1 addresses. These are never routed; the config will NOT
  # come up until you replace them with the panel values.
  wanIp = "192.0.2.10"; # TODO: ConoHa panel IPv4, e.g. 150.95.0.100
  wanGateway = "192.0.2.1"; # TODO: ConoHa panel default gateway
in
{
  my = {
    services = {
      # WAN interface. ConoHa VPS exposes the NIC as eth0.
      gateway.wanInterface = "eth0";

      # NOTE: auto-deploy (previously planned via comin) is deferred.
      # The comin module was dropped in the flake-parts migration and the
      # remaining option reference broke evaluation. Plan is to migrate to
      # deploy-rs instead (separate task).
    };

    # Primary user + SSH access for the operator (same key as the rest of fleet).
    user = {
      extraGroups = [ "wheel" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };
  };

  # ConoHa assigns a STATIC IPv4 (shown in the control panel). ConoHa does not
  # run DHCP for the primary NIC by default.
  networking = {
    # ConoHa NICs are eth0/eth1 in their own images; NixOS would otherwise use
    # predictable names (enp*s*). Disable them so `eth0` is guaranteed.
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

  # ---------------------------------------------------------------------------
  # Initial provisioning bootstrap
  # ---------------------------------------------------------------------------
  # The firewall hardening (restrictAccess = true) exposes SSH only via nebula0,
  # which is not reachable on the very first boot. For the FIRST deploy only,
  # uncomment the line below to open SSH on the WAN, then re-enable hardening
  # afterwards (mirrors hosts/torii-chan/sd-installer.nix).
  # my.services.gateway.restrictAccess = lib.mkForce false;
  #
  # SOPS prerequisite: the VPS decrypts the SAME secrets as the SBC
  # (secrets/hosts/torii-chan.yaml + secrets/services/ddns.yaml). Before the
  # gateway role can start, add the VPS age key (from its SSH host key via
  # ssh-to-age) to .sops.yaml and both secret files, then `sops updatekeys`.
  # See the README for the full provisioning walkthrough.
  # ---------------------------------------------------------------------------
  # 512MB plan: a swapfile keeps the low-RAM VPS buildable (mirrors the SBC
  # profile). The bootstrap keeps a single root partition /dev/vda1; NixOS
  # creates and enables the swapfile at boot. On a larger plan, drop this.
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
