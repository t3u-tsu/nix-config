{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop;
in
{
  imports = [
    ./browsers.nix
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
    enable = mkEnableOption "Desktop home-manager configuration (lightweight core)";

    full = {
      enable = mkEnableOption "Full desktop experience (gaming, creative, media, office, AI tools)";
    };
  };

  config = mkIf cfg.enable {
    my.home.desktop = {
      # Lightweight core: sane defaults for any desktop machine
      browsers.enable = mkDefault true;
      communication.enable = mkDefault true;
      theme.enable = mkDefault true;
      xdg.enable = mkDefault true;
      locales.enable = mkDefault true;
      niri.enable = mkDefault true;
      noctalia.enable = mkDefault true;
      thunar.enable = mkDefault true;
      gpg-signing.enable = mkDefault true;
      dev-tools.enable = mkDefault true;
      office.enable = mkDefault true;

      # Heavy extras: opt-in via my.home.desktop.full.enable
      creative.enable = mkDefault cfg.full.enable;
      gaming.enable = mkDefault cfg.full.enable;
      media.enable = mkDefault cfg.full.enable;
    };

    # dev-tools internals: heavy subsets opt-in via my.home.desktop.full.enable
    # (lightweight subsets default to true inside dev-tools/default.nix)
    my.home.desktop.dev-tools = {
      ai-tools.enable = mkDefault cfg.full.enable;
      hardware.enable = mkDefault cfg.full.enable;
    };
  };
}
