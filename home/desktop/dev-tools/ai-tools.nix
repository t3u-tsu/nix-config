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

  # Schema-fix wrapper for conoha-vps-mcp.
  # The conoha_post tool's inputSchema contains a lookahead regex ((?=...)),
  # which the OpenAI-compatible API (deepseek, etc.) rejects with 400 "is not a regex",
  # so this intercepts the tools/list response and sanitizes the pattern.
  # See ./mcp/conoha-schema-fix.js for details.
  conohaMcpWrapper = pkgs.writeScriptBin "conoha-vps-mcp-schema-fix" (
    builtins.readFile ./mcp/conoha-schema-fix.js
  );
in
{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.github-copilot-cli
      pkgs.nodejs # Required to run conoha-vps-mcp (npm exec resolves node from PATH)
      conohaMcpWrapper

      (agn-pkgs.default.override {
        useFHS = false;
        useSystemChromeProfile = false;
      })

      (agn-pkgs.google-antigravity-ide.override {
        useFHS = false;
      })

      agn-pkgs.google-antigravity-cli

      (inputs.codewhale.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        doCheck = false;
      }))
    ];
  };
}
