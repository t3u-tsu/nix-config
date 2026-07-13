{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.virtualisation.microvm;
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.my.virtualisation.microvm = {
    enable = mkEnableOption "MicroVM guest virtualization runner";
  };

  config = mkIf cfg.enable {
    microvm.host.enable = true;
  };
}
