{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  # TODO: replace with /etc/ssh/ssh_host_ed25519_key.pub when booting the host.
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2/G7hPzedL0Tzr35StyOaZZjwBZMFuhIeAbwFxf5HF";

  my = {
    services.minecraft.enable = true;
    nix.distributedBuilds.enable = true;
  };

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = false;
      device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A";
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  networking = {
    hostId = "8425e349";
    hostName = "shosoin-tan";
    useDHCP = true;
  };

  my.hardware.nvidia.enable = true;
}
