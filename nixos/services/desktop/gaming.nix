{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.gaming;
in
{
  options.my.services.desktop.gaming = {
    enable = mkEnableOption "System-wide gaming services (Steam, GameMode)";
    nvidiaOffload = {
      enable = mkEnableOption "Run Steam and every game launched through it on the NVIDIA dGPU (PRIME offload)";
    };
  };

  config = mkIf cfg.enable {
    # Steam configuration
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      # Inject the PRIME offload environment into Steam itself so every game
      # (including Proton/Wine titles) uses the dGPU without per-game launch
      # options. Same variables as the `nvidia-offload` script; only valid on
      # hosts where hardware.nvidia.prime.offload is enabled.
      package = lib.mkIf cfg.nvidiaOffload.enable (
        pkgs.steam.override {
          extraEnv = {
            __NV_PRIME_RENDER_OFFLOAD = "1";
            __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            __VK_LAYER_NV_optimus = "NVIDIA_only";
          };
        }
      );
    };

    # GameMode configuration
    programs.gamemode.enable = true;

    # Move user-facing tools to Home-manager,
    # but keep performance-related libraries at the system level if needed.
    environment.systemPackages = with pkgs; [
      gperftools
    ];
  };
}
