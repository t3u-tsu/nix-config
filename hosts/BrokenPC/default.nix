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
    kernelPackages = pkgs.linuxPackages_cachyos;
    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    loader.efi.canTouchEfiVariables = true;
  };

  # CachyOS kernel builds its own NVIDIA driver variant.
  hardware.nvidia.package = pkgs.nvidia_cachyos;

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
    virtualisation.distrobox.enable = true;
    virtualisation.microvm.enable = true;
  };

  networking.hostName = "BrokenPC";

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
}
