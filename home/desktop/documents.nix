{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.documents;
in
{
  options.my.home.desktop.documents = {
    enable = lib.mkEnableOption "Document viewers and office tools (LibreOffice, Sioyek, MarkText)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.libreoffice
      pkgs.marktext
    ];

    programs.sioyek.enable = true;
  };
}
