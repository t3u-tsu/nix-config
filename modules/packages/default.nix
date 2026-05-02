{ config, lib, ... }:

with lib;

let
  cfg = config.my.packages;
in
{
  options.my.packages = {
    core.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable core packages and shell integration";
    };
    monitoring.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable monitoring and hardware tools";
    };
    network-tools.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable networking utilities";
    };
    data.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable data processing tools";
    };
    nix-tools.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Nix ecosystem tools";
    };
    security.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable security and encryption tools";
    };
  };

  options.my.hardware.pc-tools.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable hardware-specific tools for physical PCs/Servers (smartmontools, nvme-cli, etc.)";
  };

  imports = [
    ./base.nix
    ./monitoring.nix
    ./network-tools.nix
    ./data.nix
    ./nix-tools.nix
    ./security.nix
  ];
}
