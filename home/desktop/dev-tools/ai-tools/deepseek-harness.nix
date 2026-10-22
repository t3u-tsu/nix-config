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
  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;

  deepseek-harness-alias = pkgs.runCommand "deepseek-harness-alias" { } ''
    mkdir -p "$out/bin"
    ln -s "${dsh}/bin/dsh" "$out/bin/deepseek-harness"
  '';
in
{
  config = mkIf cfg.enable {
    home.packages = [
      dsh
      deepseek-harness-alias
    ];
  };
}
