{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop;
in
{
  imports = [
    ./bitwarden.nix
    ./browsers
    ./communication.nix
    ./creative.nix
    ./dev-tools
    ./gaming.nix
    ./gpg-signing.nix
    ./media.nix
    ./niri
    ./noctalia
    ./theme.nix
    ./xdg.nix
    ./locales.nix
    ./thunar.nix
    ./office.nix
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "Desktop home-manager configuration (lightweight core)";

    full = {
      enable = lib.mkEnableOption "Full desktop experience (gaming, creative, media, AI and hardware development tools)";
    };
  };

  config = lib.mkIf cfg.enable {
    my.home.desktop = {
      bitwarden.enable = lib.mkDefault true;
      browsers.enable = lib.mkDefault true;
      communication.enable = lib.mkDefault true;
      theme.enable = lib.mkDefault true;
      xdg.enable = lib.mkDefault true;
      locales.enable = lib.mkDefault true;
      niri.enable = lib.mkDefault true;
      noctalia.enable = lib.mkDefault true;
      thunar.enable = lib.mkDefault true;
      gpg-signing.enable = lib.mkDefault true;
      dev-tools.enable = lib.mkDefault true;
      office.enable = lib.mkDefault true;

      creative.enable = lib.mkDefault cfg.full.enable;
      gaming.enable = lib.mkDefault cfg.full.enable;
      media.enable = lib.mkDefault cfg.full.enable;
    };

    my.home.desktop.dev-tools = {
      ai-tools.enable = lib.mkDefault cfg.full.enable;
      hardware.enable = lib.mkDefault cfg.full.enable;
      unity.enable = lib.mkDefault cfg.full.enable;
    };
  };
}
