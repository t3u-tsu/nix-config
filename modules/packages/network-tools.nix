{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.packages.network-tools;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bandwhich
      curl
      dnsutils
      gping
      lsof
      mtr
      nmap
      rsync
      tcpdump
      wget
      xh
      iftop
      fast-cli
    ];
  };
}
