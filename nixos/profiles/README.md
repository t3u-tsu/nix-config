# Profiles

Role-based host profiles, applied automatically by `mkSystem` (see `lib/`). A profile must be specified for every host.

## Profiles

- **`desktop/`**: Desktop experience — Niri, Fcitx5, PipeWire, GUI apps; wires `home/desktop` into Home Manager for the primary user.
- **`gateway/`**: torii-chan role — Nebula Lighthouse/Relay, DDNS, Minecraft port-forward, firewall hardening. See `hosts/torii-chan/README.md` for details.
- **`sbc/`**: Low-memory SBC profile — sandbox disabled, 4GB swapfile, swappiness tuning.
- **`tower-server/`**: Tower server common — stock kernel, SSH via Nebula mesh only, PC tools.