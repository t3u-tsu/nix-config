{ config, pkgs, lib, inputs, ... }:

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

  # GT 210 / GT 710 configuration
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

  sops.secrets.shosoin_tan_t3u_password_hash = {
    neededForUsers = true;
  };
  sops.secrets.shosoin_tan_root_password_hash = {
    neededForUsers = true;
  };

  sops.secrets.restic_password = {};
  sops.secrets.restic_shosoin_ssh_key = {};

  my.backup = {
    enable = true;
    paths = [ "/srv/minecraft" ];
    passwordFile = config.sops.secrets.restic_password.path;
    localRepo = "/mnt/tank-1tb/backups/minecraft";
    remoteRepo = "sftp:restic-shosoin@10.0.1.3:/mnt/data/backups/shosoin-tan";
    sshKeyFile = config.sops.secrets.restic_shosoin_ssh_key.path;
  };

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  # ZFS requires a unique hostId
  networking.hostId = "8425e349";
  networking.hostName = "shosoin-tan";
  networking.useDHCP = true;

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  my.localNetwork.enable = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "tank-1tb" ];

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
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.mutableUsers = false;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "render" ];
    hashedPasswordFile = config.sops.secrets.shosoin_tan_t3u_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.shosoin_tan_root_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  my.autoUpdate = {
    enable = true;
    user = username;
    pushChanges = true;
  };

  system.stateVersion = "25.05";
}
