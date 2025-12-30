{ config, pkgs, inputs, ... }:

{
  imports = [
    ./disko-config.nix
  ];

  # Use the LTS kernel for stability
  boot.kernelPackages = pkgs.linuxPackages;

  nixpkgs.config.allowUnfree = true;

  # Bootloader configuration (Using GRUB to match shosoin-tan)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Unique hostId for future ZFS support
  networking.hostId = "c0ffee01";
  networking.hostName = "kagutsuchi-sama";

  # GTX 980 Ti (Maxwell) configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # Maxwell is not supported by the 'open' kernel module
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # SSH and basic settings
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
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
