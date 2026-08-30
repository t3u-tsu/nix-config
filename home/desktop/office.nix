{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.office;
in
{
  options.my.home.desktop.office = {
    enable = mkEnableOption "Office suite (LibreOffice)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libreoffice
    ];
  };
}
