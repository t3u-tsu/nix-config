{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    ../../nixos
    ../../nixos/profiles/desktop
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Hardware settings (AMD CPU + HP Victus specifics)
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "sdhci_pci"
      "amdgpu"
    ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "i8042.nopnp"
    ];
    extraModulePackages = [ ];
    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    loader.efi.canTouchEfiVariables = true;
  };

  # Firmware management (Crucial for Wi-Fi, BT, and GPU)
  hardware.enableRedistributableFirmware = true;

  # Graphics (OpenGL/Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # GPU Configuration (Super-Conservative NVIDIA + AMD Hybrid)
  services.xserver.videoDrivers = [ "amdgpu" ]; # "nvidia" is added by the module
  my = {
    hardware.nvidia = {
      enable = true;
      prime = {
        enable = true;
        offload.enable = false;
        sync.enable = true;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:7:0:0";
      };
    };
    hardware.pc-tools.enable = true;
    virtualisation.distrobox.enable = true;
    virtualisation.microvm.enable = true;
    services.desktop.gaming.enable = true;
  };

  networking = {
    hostName = "BrokenPC";
    networkmanager.enable = true;
  };

  users = {
    mutableUsers = false;
    users.${config.my.user.name} = {
      isNormalUser = true;
      description = config.my.user.name;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
        "dialout"
      ];
      shell = pkgs.zsh;
      hashedPasswordFile = config.sops.secrets.brokenpc_t3u_password_hash.path;
    };
    users.root.hashedPasswordFile = config.sops.secrets.brokenpc_root_password_hash.path;
  };

  # Ensure /data exists and is owned by the user
  systemd.tmpfiles.rules = [
    "d /data 0755 ${config.my.user.name} users -"
  ];

  # SSH Key for the user (Managed by SOPS)
  sops.secrets.brokenpc_ssh_private_key = {
    path = "/home/${config.my.user.name}/.ssh/id_ed25519";
    owner = config.my.user.name;
    group = "users";
    mode = "0600";
  };

  system.stateVersion = "26.05";
}
