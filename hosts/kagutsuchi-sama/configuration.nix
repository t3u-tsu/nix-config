{ config, pkgs, inputs, ... }:

let
  username = "t3u";
in
{
  imports = [
    ./disko-config.nix
    ./services
    ./production-security.nix
    ../../services/minecraft
    ../../common
  ];

  sops.secrets.minecraft_forwarding_secret = {
    owner = "minecraft"; # nix-minecraft のユーザー
    group = "minecraft";
    mode = "0400";
  };

  # Use the LTS kernel for stability
  boot.kernelPackages = pkgs.linuxPackages;

  nixpkgs.config.allowUnfree = true;

  # SOPS configuration
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.sshKeyPaths = [ ];
  sops.age.generateKey = false;

  environment.variables = {
    SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";
  };

  sops.secrets.kagutsuchi_sama_t3u_password_hash = {
    neededForUsers = true;
  };
  sops.secrets.kagutsuchi_sama_root_password_hash = {
    neededForUsers = true;
  };

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

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  my.localNetwork.enable = true;

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

  users.mutableUsers = false;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "render" ];
    hashedPasswordFile = config.sops.secrets.kagutsuchi_sama_t3u_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.kagutsuchi_sama_root_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  nix.settings.trusted-users = [ "root" "t3u" ];

  my.autoUpdate = {
    enable = true;
    user = username;
  };

  system.stateVersion = "25.05";
}
