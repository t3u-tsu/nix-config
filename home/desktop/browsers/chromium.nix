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
  config = mkIf (cfg.enable && cfg.chromium.enable) {
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--no-first-run"
        "--no-default-browser-check"
      ];
    };
  };
}
