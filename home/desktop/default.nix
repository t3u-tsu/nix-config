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
    ./theme.nix
    ./xdg.nix
    ./locales.nix
    ./thunar.nix
  ];

  options.my.home.desktop = {
    enable = mkEnableOption "Desktop home-manager configuration (aggregate)";
  };

  config = mkIf cfg.enable {
    my.home.desktop = {
      browsers.enable = mkDefault true;
      communication.enable = mkDefault true;
      creative.enable = mkDefault true;
      dev-tools.enable = mkDefault true;
      gaming.enable = mkDefault true;
      gpg-signing.enable = mkDefault true;
      media.enable = mkDefault true;
      theme.enable = mkDefault true;
      xdg.enable = mkDefault true;
      locales.enable = mkDefault true;
      niri.enable = mkDefault true;
      thunar.enable = mkDefault true;
    };
  };
}
