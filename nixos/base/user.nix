{ lib, ... }:

with lib;

{
  options.my.user = {
    name = mkOption {
      type = types.str;
      default = "t3u";
      description = "The primary user of the system";
    };
  };
}
