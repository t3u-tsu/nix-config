{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  username = "t3u";
in
{
  nixpkgs.overlays = [
  ];

  imports = [
    ./services
    ../../nixos
  ];

  # Disable Nix sandboxing and seccomp filtering for legacy kernels lacking namespace/BPF support
  nix.settings = {
    sandbox = false;
    filter-syscalls = false;
  };

  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
  };

  networking = {
    hostName = "torii-chan";
    # networking.networkmanager.enable = true; # Using static config below
    useDHCP = false;

    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.0.128";
          prefixLength = 24;
        }
      ];
      macAddress = "36:43:64:11:45:14";
    };

    defaultGateway = "192.168.0.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      logRefusedConnections = false;
      logReversePathDrops = false;
    };
  };

  users = {
    mutableUsers = false;
    users.${config.my.user.name} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets.torii_chan_t3u_password_hash.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };
    users.root = {
      hashedPasswordFile = config.sops.secrets.torii_chan_root_password_hash.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };
  };

  # Request password for sudo by default (Production Security)
  # This is disabled only during initial SD image creation in sd-image-installer.nix (mkForce false)
  security.sudo.wheelNeedsPassword = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Swap configuration for stable builds on low-RAM device
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # 4GB
    }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Use swap only when necessary to protect storage
  };

  system.stateVersion = "26.05";
}
