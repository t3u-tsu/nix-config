{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.hardware.nvidia;
in
{
  options.my.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA driver support";
    open = mkOption {
      type = types.bool;
      default = false;
      description = "Use the open-source NVIDIA kernel modules (Turing or newer).";
    };
    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (systemd suspend/resume hooks).";
      };
      finegrained = mkOption {
        type = types.bool;
        default = false;
        description = "Fine-grained power management (Runtime D3); requires PRIME offload.";
      };
    };
    prime = {
      enable = mkEnableOption "NVIDIA PRIME support (Hybrid graphics)";
      offload = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable PRIME offload mode";
        };
      };
      sync = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable PRIME sync mode";
        };
      };
      nvidiaBusId = mkOption {
        type = types.str;
        default = "";
        description = "PCI bus ID of the NVIDIA GPU, e.g. \"PCI:1:0:0\".";
      };
      amdgpuBusId = mkOption {
        type = types.str;
        default = "";
        description = "PCI bus ID of the AMD GPU, e.g. \"PCI:7:0:0\".";
      };
      intelBusId = mkOption {
        type = types.str;
        default = "";
        description = "PCI bus ID of the Intel GPU, e.g. \"PCI:0:2:0\".";
      };
    };
  };

  config = mkIf cfg.enable {
    # mkBefore (mkOrder 500, ahead of the default 1000) keeps "nvidia" first so
    # BrokenPC's [ "amdgpu" ] follows; a host needing the iGPU first must
    # mkForce [ "amdgpu" "nvidia" ] — mkForce drops this module's entry.
    services.xserver.videoDrivers = mkBefore [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    };

    boot.blacklistedKernelModules = [ "nouveau" ];
    boot.kernelParams = [
      "nouveau.modeset=0"
      "nvidia-drm.modeset=1"
      "modprobe.blacklist=nouveau"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = cfg.powerManagement.enable;
      powerManagement.finegrained = cfg.powerManagement.finegrained;
      inherit (cfg) open;
      nvidiaSettings = true;
      package = mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

      prime = mkIf cfg.prime.enable {
        offload = {
          enable = cfg.prime.offload.enable;
          enableOffloadCmd = cfg.prime.offload.enable;
        };
        sync = {
          enable = cfg.prime.sync.enable;
        };
        nvidiaBusId = cfg.prime.nvidiaBusId;
        amdgpuBusId = cfg.prime.amdgpuBusId;
        intelBusId = cfg.prime.intelBusId;
      };
    };
  };
}
