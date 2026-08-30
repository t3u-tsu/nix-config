# Networking Modules

Network configuration shared across the fleet.

## Modules

- **`nebula.nix`**: Nebula mesh VPN. Generates `services.nebula.networks.nebula0` from `my.networking.nebula` (ip / groups / mtu / isLighthouse / isRelay / extraInbound). SOPS-declared CA cert + per-host node certs; `nebula0` is a trusted firewall interface.
- **`local-network.nix`**: Local network optimizations behind `my.networking.local-network.enable` — resolves `torii-chan.t3u.uk` to its LAN IP (`192.168.0.128`) to work around routers without NAT loopback.
- **`default.nix`**: Imports the networking modules.