# Host: torii-chan (Nebula Gateway / Lighthouse & Relay)

Edge gateway node deployed at **Site T** on an Orange Pi Zero 3 SBC (`192.168.0.128`), with failover capability to a ConoHa VPS.

## Role & Architecture
- **Primary Lighthouse & Relay:** Serves as the central discovery lighthouse and relay for the Nebula mesh (`10.0.0.1:4242`).
- **Cloudflare DDNS:** Automatically synchronizes public dynamic IPv4 to `torii-chan.t3u.uk` and `*.mc.t3u.uk`.
- **Minecraft Port Forward:** Proxies public TCP `25565` traffic to `shosoin-tan` (`10.0.0.4:25565`) via Nebula mesh overlay.
- **Security Boundary:** SSH port 22 is strictly restricted to `nebula0`. Only UDP `4242` (Nebula) and TCP `25565` (Minecraft) are publicly exposed.
- **Failover Design:** Shares hostname and SOPS secrets with `torii-chan-vps` to enable seamless DNS/traffic takeover during physical outages.

## Configurations in Flake
- `torii-chan-sd`: Production SBC deployment (root on microSD).
- `torii-chan-hdd`: Production SBC deployment (root on USB SATA HDD).
- `torii-chan-vps`: Failover deployment on ConoHa VPS (x86_64).
- `torii-chan-sd-installer`: Minimal installer image package for SBC provisioning.
- `torii-chan-vps-iso`: Minimal installer ISO package for VPS rescue boots.

## Quick Operations
```bash
# Rebuild SBC remotely (requires disabling sandbox on low-RAM SBC)
nixos-rebuild switch \
  --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --sudo --ask-sudo-password \
  --option sandbox false \
  --option filter-syscalls false
```

## References
- Hardware architecture, U-Boot & HDD setup: [`docs/hardware/orange-pi-zero3.md`](../../docs/hardware/orange-pi-zero3.md)
- ConoHa VPS failover & failback runbook: [`docs/operations/vps-failover.md`](../../docs/operations/vps-failover.md)
- Fleet network topology & IP allocation: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
