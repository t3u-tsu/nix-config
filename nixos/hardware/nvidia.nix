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
      };
      finegrained = mkOption {
        type = types.bool;
        default = false;
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
      };
      amdgpuBusId = mkOption {
        type = types.str;
        default = "";
      };
      intelBusId = mkOption {
        type = types.str;
        default = "";
      };
    };
  };

  config = mkIf cfg.enable {
    # Note: If AMD is also used, the host configuration should handle the order if necessary.
    # With PRIME offload the iGPU driver should come first; with sync mode the dGPU is primary.
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
