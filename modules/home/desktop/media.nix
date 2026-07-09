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
    # Spicetify-nix: Declarative Spotify theming
    programs.spicetify = {
      enable = true;
      # Use Dracula theme directly
      theme = {
        name = "Dracula";
        src = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "spicetify";
          rev = "63b2e835d8079d840277defa53651f65deee7d0c";
          sha256 = "003124pfv83ih5s36hsgig2izk83bfhkqr72221i60y825ms967z";
        };
      };

      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle # shuffle+
        hidePodcasts
        adblock
      ];
    };

    home.packages = with pkgs; [
      vlc
      libreoffice
    ];
  };
}
