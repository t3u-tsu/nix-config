{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
in
{
  config = mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
    ];
  };
}
