{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.media;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.home.desktop.media = {
    enable = mkEnableOption "Media players and entertainment tools";
  };

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    # Spicetify-nix: declarative Spotify customisation; theme color is
    # supplied by the Noctalia spicetify template (palette stays in sync).
    programs.spicetify = {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle # shuffle+
        hidePodcasts
        adblock
      ];
    };

    home.packages = with pkgs; [
      vlc
    ];
  };
}
