{ config, pkgs, lib, ... }:

{
  # Cloudflare Dynamic DNS (Go implementation: favonia/cloudflare-ddns)
  # Lightweight, fast, and supports IPv4/IPv6.

  # SOPS Secret for API Token
  # Note: The content of this secret must be in environment file format:
  # CLOUDFLARE_API_TOKEN=your_token_here
  sops.secrets.cloudflare_api_env = {
    # Service user needs to read this
    owner = "root"; # Systemd service usually runs as root or dynamic user with root group access, but we'll stick to root for now
  };

  services.cloudflare-ddns = {
    enable = true;
    # Path to the file containing CLOUDFLARE_API_TOKEN=...
    credentialsFile = config.sops.secrets.cloudflare_api_env.path;
    
    # Target Domains
    domains = [ "torii-chan.t3u.uk" ];
    
    # IPv4/IPv6 are enabled by default for 'domains' list in this module usually,
    # or it auto-detects.
    # If specific control is needed, 'ip4Domains' / 'ip6Domains' can be used,
    # but 'domains' usually covers both A and AAAA records if available.
  };
}