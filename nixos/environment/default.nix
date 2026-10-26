{ lib, ... }:

{
  options.my.packages = {
    core.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Core packages and shell integration";
    };
    monitoring.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Monitoring and hardware tools";
    };
    network-tools.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Networking utilities";
    };
    data.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Data processing tools";
    };
    security.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Security and encryption tools";
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
