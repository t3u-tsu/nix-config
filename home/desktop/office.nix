{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.office;
in
{
  options.my.home.desktop.office = {
    enable = lib.mkEnableOption "Office suite (LibreOffice)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.libreoffice ];
  };
}
