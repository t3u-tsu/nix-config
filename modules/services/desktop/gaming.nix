{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.desktop.gaming;
in {
  options.my.services.desktop.gaming = {
    enable = mkEnableOption "System-wide gaming services (Steam, GameMode)";
  };

  config = mkIf cfg.enable {
    # Steam configuration
    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
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
