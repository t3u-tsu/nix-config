# Host: torii-chan — SBC platform layer (Orange Pi Zero3)
#
# Everything specific to running the shared torii-chan role on the physical
# Orange Pi Zero3: SD/HDD boot chain, extlinux loader, static LAN networking,
# and the low-RAM SBC profile (swapfile, sandbox disabled, pubkey).
{
  config,
  lib,
  ...
}:

{
  imports = [
    # SBC profile: 4GB swapfile, nix sandbox off, authorizedKeys, swappiness
    ../../nixos/profiles/sbc
  ];

  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
  };

  networking = {
    # networking.networkmanager.enable = true; # Using static config below
    useDHCP = false;

    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.0.128";
          prefixLength = 24;
        }
      ];
      macAddress = "36:43:64:11:45:14";
    };

    defaultGateway = "192.168.0.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
