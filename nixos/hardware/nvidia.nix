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
    # Ensure nvidia is in videoDrivers
    # Note: If AMD is also used, the host configuration should handle the order if necessary
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
      open = false;
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
