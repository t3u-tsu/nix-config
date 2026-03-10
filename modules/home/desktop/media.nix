{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.my.home.desktop.media;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  options.my.home.desktop.media = {
    enable = mkEnableOption "Media players and entertainment tools";
  };

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    # Spicetify-nix: Declarative Spotify theming
    programs.spicetify = {
      enable = true;
      # Use Dracula theme directly
      theme = spicePkgs.themes.dracula;

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
