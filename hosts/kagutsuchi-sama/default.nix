{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  # TODO: replace with /etc/ssh/ssh_host_ed25519_key.pub when booting the host.
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVL9zWhWDBJNs7J14zAD+FHK5sHOcaFSP8p8EFaY1CI";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "c0ffee01";
  networking.hostName = "kagutsuchi-sama";

  my.hardware.nvidia.enable = true;
}
