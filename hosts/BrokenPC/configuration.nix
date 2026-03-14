{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./disko-config.nix
    ./services
    ../../modules
    ../../modules/profiles/desktop
  ];



  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Hardware settings (AMD CPU + HP Victus specifics)
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Firmware management (Crucial for Wi-Fi, BT, and GPU)
  hardware.enableRedistributableFirmware = true;

  # Graphics (OpenGL/Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # CRITICAL: Prevent Nouveau and force amdgpu
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [ 
    "nouveau.modeset=0" 
    "amdgpu.modeset=1"
    "nvidia-drm.modeset=1"
    "modprobe.blacklist=nouveau"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # GPU Configuration (Super-Conservative NVIDIA + AMD Hybrid)
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; 
    powerManagement.finegrained = false;

    open = false; 
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Bus IDs for HP Victus 16
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:7:0:0";
    };
  };

  # Specialisation: No-NVIDIA Mode (Safety/Power Save)
  specialisation."No-NVIDIA".configuration = {
    system.nixos.tags = [ "no-nvidia" ];
    services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];
    hardware.nvidia.prime.offload.enable = lib.mkForce false;
    hardware.nvidia.modesetting.enable = lib.mkForce false;
    boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  };

  # Hostname
  networking.hostName = "BrokenPC";

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basic networking
  networking.networkmanager.enable = true;

  # User account
  users.mutableUsers = false;
  users.users.${config.my.user.name} = {
    isNormalUser = true;
    description = config.my.user.name;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "dialout" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.brokenpc_t3u_password_hash.path;
  };

  # Ensure /data exists and is owned by the user
  systemd.tmpfiles.rules = [
    "d /data 0755 ${config.my.user.name} users -"
  ];

  # Root account password
  users.users.root.hashedPasswordFile = config.sops.secrets.brokenpc_root_password_hash.path;

  # SSH Key for the user (Managed by SOPS)
  sops.secrets.brokenpc_ssh_private_key = {
    path = "/home/${config.my.user.name}/.ssh/id_ed25519";
    owner = config.my.user.name;
    group = "users";
    mode = "0600";
  };

  # Local network tools
  my.hardware.pc-tools.enable = true;

  # Update Hub Client integration
  my.updateHub.client = {
    enable = true;
  };

  # State version
  system.stateVersion = "25.11";
}
