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

  # aagl's nixosModules.default == { imports = [ ./module ]; nixpkgs.overlays = [ self.overlays.default ]; }.
  # Import the module unconditionally so it defines the
  # programs.anime-game-launcher options, but only attach its overlay while
  # gaming is enabled, so lightweight desktops do not evaluate the aagl
  # package set. Mirrors the Chaotic-Nyx gating in the desktop profile.
  aaglModule = inputs.aagl.nixosModules.default;
in
{
  inherit (aaglModule) imports;

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
    # Attach the aagl package overlay only while gaming is enabled (see
    # aaglModule note above).
    nixpkgs.overlays = aaglModule.nixpkgs.overlays;

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
