{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.niri;
in
{
  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "noctalia-shell ipc call lockScreen lock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "niri msg action power-off-monitors";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = "niri msg action power-off-monitors";
            on-resume = "niri msg action power-on-monitors";
          }
        ];
      };
    };
  };
}
