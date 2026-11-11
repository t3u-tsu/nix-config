{ lib, ... }:

{
  options.my.home.desktop.dev-tools.ai-tools = {
    enable = lib.mkEnableOption "AI development tools";
  };

  imports = [
    ./codewhale.nix
    ./pi.nix
    ./deepseek-harness.nix
    ./antigravity.nix
    ./skills.nix
    ./gcp-failover-mcp.nix
  ];
}
