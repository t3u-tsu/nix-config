# Profiles

Role-based host profiles, applied automatically by `mkSystem` (see [`lib/`](../../lib/README.md)). A profile must be specified for every host.

## Profiles

- [`desktop/`](desktop/README.md): Desktop experience — lightweight core via `my.services.desktop.enable` / `my.home.desktop.enable` plus an opt-in full stack (`my.services.desktop.full.enable` / `my.home.desktop.full.enable`) for gaming/creative/media; wires `home/desktop` into Home Manager for the primary user.
- **`gateway/`**: Enables the torii-chan gateway role ([`nixos/services/gateway/`](../services/gateway/README.md)) — Nebula Lighthouse/Relay, DDNS, Minecraft port-forward, firewall hardening. See [`hosts/torii-chan/README.md`](../../hosts/torii-chan/README.md) for details.
- [`sbc/`](sbc/README.md): Low-memory SBC profile — sandbox disabled, 4GB swapfile, swappiness tuning.
- [`tower-server/`](tower-server/README.md): Tower server common — stock kernel, SSH via Nebula mesh only, PC tools.