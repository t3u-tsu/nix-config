{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.gaming;
in
{
  imports = [
    inputs.aagl.nixosModules.default
  ];

  options.my.services.desktop.gaming = {
    enable = mkEnableOption "System-wide gaming services (Steam, GameMode, aagl)";
    aagl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "aagl game launchers (an-anime-game-launcher)";
      };
    };
    nvidiaOffload = {
      enable = mkEnableOption "Run Steam and every game launched through it on the NVIDIA dGPU (PRIME offload)";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
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
      gamemode.enable = true;
      anime-game-launcher.enable = cfg.aagl.enable;
    };
  };
}
