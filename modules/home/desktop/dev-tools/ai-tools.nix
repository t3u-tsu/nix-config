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
  agn-pkgs = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.github-copilot-cli

      (agn-pkgs.default.override {
        useFHS = false;
        useSystemChromeProfile = false;
      })

      (agn-pkgs.google-antigravity-ide.override {
        useFHS = false;
      })

      agn-pkgs.google-antigravity-cli
    ];
  };
}
