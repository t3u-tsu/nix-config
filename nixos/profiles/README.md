# Host Profiles (`nixos/profiles/`)

Role-based host profiles applied automatically during system evaluation via `mkSystem` ([`lib/default.nix`](../../lib/default.nix)). Every managed machine specifies one primary profile.

## Profile Catalog

| Profile | Target Architecture | Description | Target Hosts |
| :--- | :--- | :--- | :--- |
| [`desktop/`](desktop/README.md) | `x86_64-linux` | Graphical desktop workstations (Niri Wayland compositor, Noctalia shell, audio, and optional gaming/creative tools). | `BrokenPC`, `x1c7` |
| [`gateway/`](../services/gateway/README.md) | `aarch64-linux`, `x86_64-linux` | Edge network router: Nebula Lighthouse and Relay, Cloudflare DDNS, and port forwarding. | `torii-chan`, `torii-chan-vps` |
| [`sbc/`](sbc/README.md) | `aarch64-linux` | Low-RAM single-board computers (sandboxing disabled, 4GB swapfile, reduced swappiness at `vm.swappiness = 10`). | `torii-chan` (physical SBC) |
| [`tower-server/`](tower-server/README.md) | `x86_64-linux` | Headless servers (default kernel, SSH restricted to the Nebula mesh, hardware health monitoring). | `shosoin-tan`, `kagutsuchi-sama`, `sando-kun` |

## References

- System evaluation architecture: [`docs/architecture/overview.md`](../../docs/architecture/overview.md)
- System builder implementation: [`lib/README.md`](../../lib/README.md)
