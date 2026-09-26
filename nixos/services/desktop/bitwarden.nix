{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.bitwarden;
in
{
  options.my.services.desktop.bitwarden = {
    enable = mkEnableOption "Bitwarden desktop app";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.bitwarden-desktop ];
  };
}
