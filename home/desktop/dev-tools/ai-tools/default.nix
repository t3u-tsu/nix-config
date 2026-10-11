{ lib, ... }:

with lib;

{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  imports = [
    ./codewhale.nix
    ./pi.nix
    ./deepseek-harness.nix
    ./conoha-vps-mcp.nix
    ./antigravity.nix
    ./skills.nix
  ];
}
