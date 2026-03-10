{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
in {
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Use unstable for gemini-cli to get latest features/fixes
      unstable.gemini-cli
      # Agentic development platform
      antigravity
    ];
  };
}
