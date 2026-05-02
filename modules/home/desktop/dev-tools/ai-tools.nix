{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
in
{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      unstable.gemini-cli
      unstable.antigravity
      unstable.github-copilot-cli
    ];
  };
}
