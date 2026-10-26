{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    ];
  };
}
