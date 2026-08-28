{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.dev-tools.ventoy;
in
{
  options.my.dev-tools.ventoy = {
    enable = mkEnableOption "Ventoy bootable USB tool (insecure package)";
  };

  config = mkIf cfg.enable {
    # Ventoy ships binary blobs that cannot be trusted to be malware-free;
    # the package is marked insecure in nixpkgs (see nixpkgs#404663).
    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-1.1.12"
    ];
  };
}
