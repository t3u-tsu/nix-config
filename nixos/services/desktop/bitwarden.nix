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
    enable = mkEnableOption "Bitwarden desktop app and CLI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bitwarden-desktop
      pkgs.bitwarden-cli
    ];
  };
}
