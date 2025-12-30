{ config, pkgs, inputs, ... }:

{
  imports = [
    ./disko-config.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # For UEFI
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS requires a unique hostId
  networking.hostId = "8425e349";
  networking.hostName = "shosoin-tan";

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Core i7 870 is x86_64
  # Quadro K2200 (Maxwell) uses standard NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # Maxwell is not supported by the 'open' kernel module
    nvidiaSettings = true;
    # Quadro K2200 is well-supported by the 'stable' or 'production' branch
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # SSH and basic settings
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users.t3u = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "render" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  system.stateVersion = "25.05";
}
