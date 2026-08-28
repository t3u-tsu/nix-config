{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.dev-tools;
in
{
  options.my.dev-tools = {
    enable = mkEnableOption "Development tools (WCH-LinkE udev rules, Ventoy approval)";
  };

  imports = [
    ./wch-linke.nix
    ./ventoy.nix
  ];

  config = mkIf cfg.enable {
    my.dev-tools = {
      wch-linke.enable = mkDefault true;
      ventoy.enable = mkDefault true;
    };
  };
}
