{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.packages.data;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jq
      p7zip
      unzip
      xz
      yq-go
      zip
      zstd
    ];
  };
}
