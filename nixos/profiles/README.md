# Profiles

Role-based host profiles, applied automatically by `mkSystem` (see [`lib/`](../../lib/)). A profile must be specified for every host.

## Profiles

- [`desktop/`](desktop/): Desktop experience — lightweight core via `my.services.desktop.enable` / `my.home.desktop.enable` plus an opt-in full stack (`my.services.desktop.full.enable` / `my.home.desktop.full.enable`) for gaming/creative/media; wires `home/desktop` into Home Manager for the primary user.
- [`gateway/`](gateway/): Enables the torii-chan gateway role ([`nixos/services/gateway/`](../services/gateway/)) — Nebula Lighthouse/Relay, DDNS, Minecraft port-forward, firewall hardening. See [`hosts/torii-chan/`](../../hosts/torii-chan/) for details.
- [`sbc/`](sbc/): Low-memory SBC profile — sandbox disabled, 4GB swapfile, swappiness tuning.
- [`tower-server/`](tower-server/): Tower server common — stock kernel, SSH via Nebula mesh only, PC tools.