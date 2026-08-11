{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools;
in
{
  options.my.home.desktop.dev-tools = {
    enable = mkEnableOption "Development tools category";
  };

  imports = [
    ./neovim.nix
    ./git-tools.nix
    ./nix.nix
    ./ai-tools.nix
    ./conoha-vps-mcp.nix
    ./hardware.nix
    ./ghostty.nix
    ./unity.nix
  ];

  config = mkIf cfg.enable {
    my.home.desktop.dev-tools = {
      neovim.enable = mkDefault true;
      git-tools.enable = mkDefault true;
      ai-tools.enable = mkDefault true;
      hardware.enable = mkDefault true;
      ghostty.enable = mkDefault true;
      nix.enable = mkDefault true;
    };
  };
}
