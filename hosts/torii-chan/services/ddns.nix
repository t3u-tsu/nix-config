{ config, pkgs, lib, ... }:

{
  # Cloudflare Dynamic DNS
  # API Token must have "Zone.DNS:Edit" permission for the target zone.

  sops.secrets.cloudflare_api_token = {
    # サービスが読み取れるように所有者を設定 (Systemd Dynamic Userの場合は調整が必要だが、
    # cloudflare-dyndnsは通常rootまたは専用ユーザーで動作する。
    # ここではデフォルトのroot所有にしておく)
  };

  services.cloudflare-dyndns = {
    enable = true;
    # API Token file path (managed by sops-nix)
    apiTokenFile = config.sops.secrets.cloudflare_api_token.path;
    
    # Target Domains
    domains = [ "torii-chan.t3u.uk" ];
    
    # Update IPv4 (A record)
    ipv4 = true;
    
    # Update IPv6 (AAAA record) - Orange Pi usually has IPv6
    ipv6 = true; # 無効にする場合は false にしてください
  };
}
