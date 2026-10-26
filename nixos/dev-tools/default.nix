{
  config,
  lib,
  ...
}:

let
  cfg = config.my.dev-tools;
in
{
  options.my.dev-tools = {
    enable = lib.mkEnableOption "Development tools (WCH-LinkE udev rules)";
  };

  imports = [
    ./wch-linke.nix
    ./ventoy.nix
  ];

  config = lib.mkIf cfg.enable {
    my = {
      dev-tools.wch-linke.enable = lib.mkDefault true;
      dev-tools.ventoy.enable = lib.mkDefault true;
      user.extraGroups = lib.mkIf cfg.wch-linke.enable [ "dialout" ];
    };
  };
}
