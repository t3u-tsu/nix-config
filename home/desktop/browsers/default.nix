{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.browsers;
in
{
  imports = [
    ./chromium.nix
    ./userscripts.nix
    ./zen.nix
  ];

  options.my.home.desktop.browsers = {
    enable = mkEnableOption "Web browsers";
    zen.enable = mkOption {
      type = types.bool;
      default = true;
    };
    chromium.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.zen.enable) {
    my.home.desktop.browsers.userscripts.enable = mkDefault true;
  };
}
