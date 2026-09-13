# System Services

System-wide services managed by NixOS modules.

## Services

- **`backup/`**: Restic backup — sender (`default.nix`) and receiver (`receiver.nix`, currently `kagutsuchi-sama`). See `backup/README.md`.
- **`desktop/`**: Desktop system services — compositor, login manager, audio, fonts, file manager, and the gaming stack.
- **`discord-bridge/`**: Minecraft Discord bridge service (whitelist management, status via Unix socket).
- **`gateway/`**: torii-chan gateway role (`my.services.gateway`) — Nebula Lighthouse/Relay, DDNS, Minecraft port-forward, firewall hardening. See `gateway/README.md`.
- **`minecraft/`**: Minecraft network — proxy frontend, backend servers, and nvfetcher-pinned plugins.
- **`default.nix`**: Imports the service modules.