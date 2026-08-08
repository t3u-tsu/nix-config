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

  # conoha-vps-mcp のスキーマ修正ラッパー。
  # conoha_post ツールの inputSchema に先読み正規表現（(?=...)）が含まれており、
  # OpenAI 互換 API（deepseek 等）が 400 "is not a regex" を返すため、
  # tools/list レスポンスをインターセプトして pattern を安全化する。
  # 詳細は ./mcp/conoha-schema-fix.js を参照。
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
      pkgs.nodejs # conoha-vps-mcp の実行に必要（npm exec が PATH から node を解決する）
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
