{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  age.rekey.hostPubkey = "age1l5tjtsw70k40pzl2ndzay89zr8e475vpc2kymrpy7p67p42pggns5y2mkk";

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
      "acpi.ec_no_wakeup=1"
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

  # Prevent AMD I2C controller from autosuspending into an unrecoverable sleep state,
  # which causes i2c_designware controller timeouts and freezes the Synaptics touchpad.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="AMDI0010:03", ATTR{power/control}="on"
  '';

  # Ensure the I2C controller and touchpad are active after suspend/resume
  powerManagement.resumeCommands = ''
    if [ -d /sys/bus/platform/devices/AMDI0010:03 ]; then
      echo "on" > /sys/bus/platform/devices/AMDI0010:03/power/control || true
    fi
  '';

  # NOTE (2026-08-02): the RTX 3050 Ti dGPU is FAULTY (hardware). Minecraft hangs
  # it under load (OpenGL SIGSEGV in libnvidia-glcore.so / Vulkan GPU hang) while
  # the Radeon 680M iGPU runs it stably; glmark2 and a 90%-VRAM stress test pass,
  # so it is the dGPU texture-upload path, not VRAM or the driver alone.
  # nvidiaOffload stays DISABLED (games on the iGPU) until the dGPU is replaced.
  # CUDA inference (llama.cpp etc.) still works on the dGPU.
  nixpkgs.config.cudaCapabilities = [ "8.6" ];

  # AMD iGPU (Radeon 680M) is the default renderer; the NVIDIA dGPU is activated
  # on demand via `nvidia-offload` (compute only, see the dGPU note above).
  # `nvidia` is prepended to videoDrivers by the hardware module (mkBefore).
  services = {
    xserver.videoDrivers = [ "amdgpu" ];

    power-profiles-daemon.enable = true;

    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "ignore";
    };
  };

  my = {
    services = {
      desktop.full.enable = true;
      desktop = {
        greetd.greeterOutput = {
          name = "eDP-1";
        };
        greetd.greeterWallpaper = "/home/${config.my.user.name}/Pictures/wallpapers/PTITSA/144133008_p0.jpg";
        bluetooth.experimental = true;
      };
    };

    hardware.nvidia = {
      enable = true;
      open = true;
      # finegrained requires PRIME offload (assertion in the nixpkgs module).
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
    virtualisation.microvm.enable = true;
  };

  # Make the AMD iGPU the primary DRM renderer so the NVIDIA dGPU stays powered
  # down unless explicitly offloaded; by-path keeps this stable across boots
  # regardless of cardN numbering (AMD = 07:00.0, NVIDIA = 01:00.0).
  # This MUST be a home-manager drop-in: defining systemd.user.services.niri
  # replaces the niri package's unit and loses its ExecStart, and
  # /etc/systemd/user is a symlink into the store (environment.etc cannot write
  # inside it).
  home-manager.users.${config.my.user.name} = {
    # Home-manager secrets are decrypted with the user's SSH key, so they rekey
    # to the age pubkey derived from it rather than the host key.
    age.rekey.hostPubkey = "age1nsprt0asqmy9wmc09yffwy34hx5v2a6hvat0cnzvr8h03f8ymezqguqtmy";
    my.home.desktop.full.enable = true;
    my.home.desktop.noctalia.wallpaperPreset = "PTITSA";
    xdg.configFile."systemd/user/niri.service.d/wlr-drm-devices.conf".text = ''
      [Service]
      Environment="WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:07:00.0-card,/dev/dri/by-path/pci-0000:01:00.0-card"
    '';

  };

  networking.hostName = "BrokenPC";

  systemd.tmpfiles.rules = [
    "d /data 0755 ${config.my.user.name} users -"
  ];
}
