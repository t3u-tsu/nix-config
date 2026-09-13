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

  # Schema-fix wrapper for conoha-vps-mcp.
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
      pkgs.nodejs # Required to run conoha-vps-mcp
      conohaMcpWrapper

      (inputs.codewhale.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        doCheck = false;
      }))
    ];

    # hush (github:ro80t/hush, MIT): external skill for codewhale's comment ruleset.
    home.file.".codewhale/skills/hush/SKILL.md".source = "${inputs.hush}/skills/hush/SKILL.md";
  };
}
