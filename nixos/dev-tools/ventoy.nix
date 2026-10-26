{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.dev-tools.ventoy;
in
{
  options.my.dev-tools.ventoy = {
    enable = lib.mkEnableOption "Ventoy USB boot media creator";
  };

  config = lib.mkIf cfg.enable {
    # Ventoy ships binary blobs that cannot be trusted to be malware-free;
    # the package is marked insecure in nixpkgs (see nixpkgs#404663).
    nixpkgs.config.permittedInsecurePackages = [ pkgs.ventoy.name ];
  };
}
