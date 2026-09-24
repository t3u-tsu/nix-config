{ lib, ... }:

with lib;

{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = mkEnableOption "AI development tools";
  };

  imports = [
    ./codewhale.nix
    ./conoha-vps-mcp.nix
  ];
}
