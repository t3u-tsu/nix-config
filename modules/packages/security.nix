{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.my.packages.security;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      age
      gnupg
      sops
      ssh-to-age
    ];
  };
}
