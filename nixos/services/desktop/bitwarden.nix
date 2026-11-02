{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.desktop.bitwarden;
in
{
  options.my.services.desktop.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden desktop app (system-wide for polkit policy)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.bitwarden-desktop ];
  };
}
