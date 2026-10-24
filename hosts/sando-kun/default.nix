{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  age.rekey.hostPubkey = "age13cy8xpjuezt3mfkaqmtdf99r4cjywtxxwu4hrq0q875xwu62xvfq24ch6v";

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F";
  };

  networking = {
    hostId = "5a4d0001";
    hostName = "sando-kun";
    useDHCP = true;
  };
}
