{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.hardware.pc-tools;
in
{
  options.my.hardware.pc-tools = {
    enable = mkEnableOption "Hardware-specific tools for physical PCs/Servers (smartmontools, nvme-cli, etc.)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nvme-cli
      smartmontools
    ];
  };
}
