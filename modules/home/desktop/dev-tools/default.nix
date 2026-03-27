{ config, lib, ... }:

with lib;
let
  cfg = config.my.home.desktop.dev-tools;
in {
  options.my.home.desktop.dev-tools = {
    enable = mkEnableOption "Development tools category";
  };

  imports = [
    ./neovim.nix
    ./vscode.nix
    ./git-tools.nix
    ./ai-tools.nix
    ./hardware.nix
    ./wezterm.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific tools by default when the category is enabled
    my.home.desktop.dev-tools = {
      neovim.enable = mkDefault true;
      vscode.enable = mkDefault false; # Use Neovim by default
      git-tools.enable = mkDefault true;
      ai-tools.enable = mkDefault true;
      hardware.enable = mkDefault true;
      wezterm.enable = mkDefault true;
    };
  };
}
