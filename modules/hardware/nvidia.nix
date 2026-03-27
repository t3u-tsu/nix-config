{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.hardware.nvidia;
in {
  options.my.hardware.nvidia = {
    enable = mkEnableOption "NVIDIA driver support";
    powerManagement = {
      enable = mkOption { type = types.bool; default = false; };
      finegrained = mkOption { type = types.bool; default = false; };
    };
    prime = {
      enable = mkEnableOption "NVIDIA PRIME support (Hybrid graphics)";
      nvidiaBusId = mkOption { type = types.str; default = ""; };
      amdgpuBusId = mkOption { type = types.str; default = ""; };
      intelBusId = mkOption { type = types.str; default = ""; };
    };
    specialisation = {
      noNvidia = mkEnableOption "No-NVIDIA mode specialisation";
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = mkIf cfg.prime.enable {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        nvidiaBusId = cfg.prime.nvidiaBusId;
        amdgpuBusId = cfg.prime.amdgpuBusId;
        intelBusId = cfg.prime.intelBusId;
      };
    };

    specialisation."No-NVIDIA" = mkIf (cfg.specialisation.noNvidia) {
      configuration = {
        system.nixos.tags = [ "no-nvidia" ];
        # Disable NVIDIA drivers and prime in this specialisation
        services.xserver.videoDrivers = lib.mkForce [ "modesetting" ]; # Fallback
        hardware.nvidia.prime.offload.enable = lib.mkForce false;
        hardware.nvidia.modesetting.enable = lib.mkForce false;
        boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      };
    };
  };
}
