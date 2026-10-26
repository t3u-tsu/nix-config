{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMe7717AIRVTyKqmOBy3Vl7Hv+t1W8mDCPgsz48HVcj";

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
