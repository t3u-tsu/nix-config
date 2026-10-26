{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.my.virtualisation.microvm;
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.my.virtualisation.microvm = {
    enable = lib.mkEnableOption "MicroVM guest virtualization runner";
  };

  config = lib.mkIf cfg.enable {
    microvm.host.enable = true;
  };
}
