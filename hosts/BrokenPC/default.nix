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
    kernelPackages = pkgs.linuxPackages_xanmod;
    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    loader.efi.canTouchEfiVariables = true;
  };

  # NOTE (2026-08-02): NVIDIA dGPU (RTX 3050 Ti) is FAULTY (hardware).
  # Minecraft hangs/crashes the GPU under load:
  #   - OpenGL: SIGSEGV in libnvidia-glcore.so (NULL pointer write)
  #   - Vulkan: VK semaphore timeout (GPU hang) during texture updates
  #   - glmark2 and a 90%-VRAM stress test pass; the AMD iGPU (Radeon 680M)
  #     runs Minecraft stably
  # → dGPU core fault (texture upload path), not VRAM, not driver-only.
  # Workaround: nvidiaOffload is DISABLED; run games on the AMD iGPU.
  # Re-enable nvidiaOffload after the dGPU is repaired/replaced.

  # GPU Configuration (Battery-first: PRIME offload)
  # - AMD iGPU (Radeon 680M) is the default renderer; the NVIDIA dGPU is only
  #   activated on demand via `nvidia-offload` (games/compute).
  # - `nvidia` is added to videoDrivers by the module (mkBefore).
  services.xserver.videoDrivers = [ "amdgpu" ];

  my = {
    hardware.nvidia = {
      enable = true;
      open = true;
      # systemd suspend/resume integration + Runtime D3 (RTD3) power gating.
      # finegrained requires PRIME offload (assertion in nixpkgs module).
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        enable = true;
        offload.enable = true;
        sync.enable = false;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:7:0:0";
      };
    };
    virtualisation.distrobox.enable = true;
    virtualisation.microvm.enable = true;
  };

  # Make the AMD iGPU the primary DRM renderer so the NVIDIA dGPU stays powered
  # down unless explicitly offloaded. by-path keeps this stable across boots
  # regardless of cardN numbering (AMD = 07:00.0, NVIDIA = 01:00.0).
  # This is a drop-in for the niri.service provided by the niri package
  # (via /run/current-system/sw/share/systemd/user, XDG_DATA_DIRS). Defining
  # systemd.user.services.niri here would REPLACE that unit (and lose its
  # ExecStart), and /etc/systemd/user is a symlink to the user-units package
  # (so environment.etc cannot create files inside it). We therefore place the
  # drop-in in ~/.config/systemd/user via home-manager instead.
  home-manager.users.${config.my.user.name} = {
    xdg.configFile."systemd/user/niri.service.d/wlr-drm-devices.conf".text = ''
      [Service]
      Environment="WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:07:00.0-card,/dev/dri/by-path/pci-0000:01:00.0-card"
    '';

  };

  # Laptop lid behavior: suspend on battery, lock when on AC, ignore when docked.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
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
