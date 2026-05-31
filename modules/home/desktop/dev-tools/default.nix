{ config, lib, ... }:

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
    ./ai-tools.nix
    ./hardware.nix
    ./ghostty.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific tools by default when the category is enabled
    my.home.desktop.dev-tools = {
      neovim.enable = mkDefault true;
      git-tools.enable = mkDefault true;
      ai-tools.enable = mkDefault true;
      hardware.enable = mkDefault true;
      ghostty.enable = mkDefault true;
    };
  };
}
