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
  palette = import ./palette.nix;
  nohash = s: removePrefix "#" s; # #ffc799 -> ffc799 (spicetify ini)
in
{
  options.my.home.desktop.media = {
    enable = mkEnableOption "Media players and entertainment tools";
  };

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    # Spicetify: declaratively-patched Spotify. No dynamic theme sync with
    # Noctalia (build-time embedding), so the Vesper palette is baked in.
    programs.spicetify = {
      enable = true;
      theme = {
        name = "Comfy";
        src = "${inputs.comfy-theme}/Comfy";
      };
      colorScheme = "custom";
      customColorScheme = with palette; {
        text = nohash fg;
        subtext = nohash fg2;
        main = nohash bg;
        sidebar = nohash bg;
        player = nohash bg;
        card = nohash card;
        shadow = nohash bg;
        selected-row = nohash fg;
        button = nohash primary;
        button-active = nohash primary;
        button-disabled = nohash primary;
        tab-active = nohash bg;
        notification = nohash tertiary;
        notification-error = nohash err;
        misc = nohash bg;
      };
      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle
        hidePodcasts
        adblock
      ];
    };

    home.packages = with pkgs; [
      vlc
    ];
  };
}
