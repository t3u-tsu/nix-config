# Host: HOSTNAME

Short description of this machine (role, hardware headline, profile).

## Hardware Specs
- **CPU:** Model, core / thread count
- **GPU:** Model, driver, role
- **RAM:** Capacity
- **Storage:**
  - `/dev/disk/by-id/...`: mount points, partition layout

## Configuration Summary
- **Profile:** `desktop` | `tower-server` | `gateway` | `sbc`
- **Nebula Mesh:** `10.0.0.X` (groups: `mgmt`, ...)
- **Key Services:**
  - `my.services.<name>.enable = true;`

## Quick Operations
```bash
# Local rebuild
sudo nixos-rebuild switch --flake .#HOSTNAME

# Remote deploy over Nebula
nixos-rebuild switch --flake .#HOSTNAME --target-host t3u@10.0.0.X --sudo --ask-sudo-password
```

## Installation
Follow the comprehensive, step-by-step installation runbook in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

## References
- Adding a host runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
