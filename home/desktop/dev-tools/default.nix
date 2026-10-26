{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools;
in
{
  options.my.home.desktop.dev-tools = {
    enable = lib.mkEnableOption "Development tools category";
  };

  imports = [
    ./neovim.nix
    ./git-tools.nix
    ./nix.nix
    ./ai-tools
    ./hardware.nix
    ./ghostty.nix
    ./unity.nix
  ];

  config = lib.mkIf cfg.enable {
    my.home.desktop.dev-tools = {
      neovim.enable = lib.mkDefault true;
      git-tools.enable = lib.mkDefault true;
      ghostty.enable = lib.mkDefault true;
      nix.enable = lib.mkDefault true;
      # ai-tools / hardware / unity default to false; the desktop aggregate
      # turns them on with my.home.desktop.full.enable (they pull in heavy packages).
    };
  };
}
