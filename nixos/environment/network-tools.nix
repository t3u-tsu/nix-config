{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.packages.network-tools;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bandwhich
      cloudflared
      curl
      dnsutils
      gping
      iftop
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
