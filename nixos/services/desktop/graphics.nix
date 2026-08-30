{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.graphics;
in
{
  options.my.services.desktop.graphics = {
    enable = mkEnableOption "Desktop graphics (redistributable firmware + 32-bit GPU support)";
  };

  config = mkIf cfg.enable {
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
