{
  config,
  lib,
  ...
}:

let
  cfg = config.my.services.desktop.graphics;
in
{
  options.my.services.desktop.graphics = {
    enable = lib.mkEnableOption "Desktop graphics (redistributable firmware + 32-bit GPU support)";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
