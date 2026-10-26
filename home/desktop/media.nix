{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.home.desktop.media;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  palette = import ../../lib/palette.nix;
  nohash = s: lib.removePrefix "#" s;
in
{
  options.my.home.desktop.media = {
    enable = lib.mkEnableOption "Media players and entertainment tools";
  };

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
    # Spicetify: declaratively-patched Spotify. No dynamic theme sync with
    # Noctalia (build-time embedding), so the Vesper palette is baked in.
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.comfy;
      colorScheme = "custom";
      customColorScheme = {
        text = nohash palette.fg;
        subtext = nohash palette.fg2;
        main = nohash palette.bg;
        sidebar = nohash palette.bg;
        player = nohash palette.bg;
        card = nohash palette.card;
        shadow = nohash palette.bg;
        selected-row = nohash palette.fg;
        button = nohash palette.primary;
        button-active = nohash palette.primary;
        button-disabled = nohash palette.primary;
        tab-active = nohash palette.bg;
        notification = nohash palette.tertiary;
        notification-error = nohash palette.err;
        misc = nohash palette.bg;
      };
      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle
        hidePodcasts
        adblock
      ];
    };

    home.packages = [ pkgs.vlc ];
  };
}
