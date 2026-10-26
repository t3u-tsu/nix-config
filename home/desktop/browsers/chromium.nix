{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.browsers;
in
{
  config = lib.mkIf (cfg.enable && cfg.chromium.enable) {
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--no-first-run"
        "--no-default-browser-check"
      ];
    };
  };
}
