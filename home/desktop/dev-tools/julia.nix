{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.julia;
in
{
  options.my.home.desktop.dev-tools.julia = {
    enable = lib.mkEnableOption "Julia language runtime";
    package = lib.mkPackageOption pkgs "julia-bin" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
