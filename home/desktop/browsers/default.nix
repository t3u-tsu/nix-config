{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.browsers;
in
{
  imports = [
    ./chromium.nix
    ./userscripts.nix
    ./zen.nix
    ./bitwarden.nix
  ];

  options.my.home.desktop.browsers = {
    enable = lib.mkEnableOption "Web browsers";
    zen.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zen Browser.";
    };
    chromium.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Chromium.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.zen.enable) {
    my.home.desktop.browsers.userscripts.enable = lib.mkDefault true;
    my.home.desktop.browsers.bitwarden.enable = lib.mkDefault true;
  };
}
