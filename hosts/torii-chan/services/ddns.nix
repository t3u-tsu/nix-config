{ config, pkgs, lib, ... }:

{
  # Cloudflare Dynamic DNS (Go implementation: favonia/cloudflare-ddns)
  # Lightweight, fast, and supports IPv4/IPv6.

  # SOPS Secret for API Token
  # Note: The content of this secret must be in environment file format:
  # CLOUDFLARE_API_TOKEN=your_token_here
  sops.secrets.cloudflare_api_env = {
    # Service user needs to read this
    owner = "root";
    # Restart the service automatically when the secret changes
    restartUnits = [ "cloudflare-ddns.service" ];
  };

  services.cloudflare-ddns = {
    enable = true;
    # Path to the file containing CLOUDFLARE_API_TOKEN=...
    credentialsFile = config.sops.secrets.cloudflare_api_env.path;
    
    # Increase timeout for more reliability on slow networks or DNS
    detectionTimeout = "15s";

    # Update only IPv4 (A record)
    ip4Domains = [ "torii-chan.t3u.uk" "mc.t3u.uk" "*.mc.t3u.uk" ];
    ip6Domains = [ ];

    # Target Domains
    domains = [ "torii-chan.t3u.uk" "mc.t3u.uk" "*.mc.t3u.uk" ];
  };

  # Explicitly disable IPv6 detection via environment variable to avoid timeouts
  systemd.services.cloudflare-ddns.serviceConfig.Environment = [
    "IP6_PROVIDER=none"
  ];
}