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
    # Spicetify: declaratively-patched Spotify. No dynamic theme sync with
    # Noctalia (build-time embedding), so the Vesper palette is baked in.
    programs.spicetify = {
      enable = true;
      theme = {
        name = "Comfy";
        src = "${inputs.comfy-theme}/Comfy";
      };
      colorScheme = "custom";
      customColorScheme = {
        text = "ffffff";
        subtext = "a0a0a0";
        main = "0c0c0c";
        sidebar = "0c0c0c";
        player = "0c0c0c";
        card = "141414";
        shadow = "0c0c0c";
        selected-row = "ffffff";
        button = "ffc799";
        button-active = "ffc799";
        button-disabled = "ffc799";
        tab-active = "0c0c0c";
        notification = "fbadff";
        notification-error = "ff8080";
        misc = "0c0c0c";
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
