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
      ghostty.enable = mkDefault true;
      nix.enable = mkDefault true;
      # ai-tools / hardware default to false; the desktop aggregate turns them
      # on with my.home.desktop.full.enable (they pull in heavy packages).
    };
  };
}
