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
      cloudflared
      curl
      dnsutils
      gping
      iftop
      lsof
      mtr
      nebula
      nmap
      rsync
      tcpdump
      wget
      xh
    ];
  };
}
