{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  # TODO: replace with /etc/ssh/ssh_host_ed25519_key.pub when booting the host.
  # age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
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
