{ config, lib, ... }:

with lib;

let
  cfg = config.my.packages;
in
{
  options.my.packages = {
    core.enable = mkEnableOption "Core packages and shell integration" // {
      default = true;
    };
    monitoring.enable = mkEnableOption "Monitoring and hardware tools" // {
      default = true;
    };
    network-tools.enable = mkEnableOption "Networking utilities" // {
      default = true;
    };
    data.enable = mkEnableOption "Data processing tools" // {
      default = true;
    };
    security.enable = mkEnableOption "Security and encryption tools" // {
      default = true;
    };
  };

  imports = [
    ./base.nix
    ./monitoring.nix
    ./network-tools.nix
    ./data.nix
    ./security.nix
  ];
}
