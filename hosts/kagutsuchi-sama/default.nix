{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  age.rekey.hostPubkey = "age1nyneyv489f7avxympatkrmjjngwln4e8ehvs4njrthfgyyfrme5q4ne36k";

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
