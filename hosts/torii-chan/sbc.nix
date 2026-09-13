# SBC platform layer (Orange Pi Zero3): SD/HDD boot chain, extlinux loader and
# static LAN networking for the shared torii-chan role.
{
  config,
  lib,
  ...
}:

{
  imports = [
    ../../nixos/profiles/sbc
  ];

  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
  };

  networking = {
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
