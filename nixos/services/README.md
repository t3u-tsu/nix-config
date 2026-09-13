# System Services

System-wide services managed by NixOS modules.

## Services

- [`backup/`](backup/): Restic backup — sender (`default.nix`) and receiver (`receiver.nix`, currently `kagutsuchi-sama`).
- [`desktop/`](desktop/): Desktop system services — compositor, login manager, audio, fonts, file manager, and the gaming stack.
- [`discord-bridge/`](discord-bridge/): Minecraft Discord bridge service (whitelist management, status via Unix socket).
- [`gateway/`](gateway/): torii-chan gateway role (`my.services.gateway`) — Nebula Lighthouse/Relay, DDNS, Minecraft port-forward, firewall hardening.
- [`minecraft/`](minecraft/): Minecraft network — proxy frontend, backend servers, and nvfetcher-pinned plugins.
- **`default.nix`**: Imports the service modules.