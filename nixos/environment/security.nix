{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.packages.security;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      age
      gnupg
      ssh-to-age
    ];
  };
}
