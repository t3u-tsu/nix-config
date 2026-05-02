{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.my.home.desktop.niri;
in
{
  imports = [
    inputs.noctalia-shell.homeModules.default
    ./theme.nix
    ./ui.nix
  ];

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      settings.settingsVersion = 0;
    };
  };
}
