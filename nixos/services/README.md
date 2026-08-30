# System Services

System-wide services managed by NixOS modules.

## Services

- **`backup/`**: Restic backup — sender (`default.nix`) and receiver (`receiver.nix`, currently `kagutsuchi-sama`). See `backup/README.md`.
- **`desktop/`**: Desktop system services — Niri, greetd, PipeWire, fonts, Thunar, gaming, Unity.
- **`discord-bridge/`**: Minecraft Discord bridge service (whitelist management, status via Unix socket).
- **`minecraft/`**: Minecraft network — Velocity proxy + Paper backends, nvfetcher-managed plugins.
- **`default.nix`**: Imports the service modules.