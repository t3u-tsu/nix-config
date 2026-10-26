{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.hardware.pc-tools;
in
{
  options.my.hardware.pc-tools = {
    enable = lib.mkEnableOption "Hardware-specific tools for physical PCs/Servers (smartmontools, nvme-cli, etc.)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nvme-cli
      smartmontools
    ];
  };
}
