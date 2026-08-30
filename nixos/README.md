# NixOS System Modules

System-wide NixOS configuration, imported for all hosts via `nixos/default.nix`.

## Modules

- **`base/`**: OS foundation — users (`user.nix`), Nix settings & Cachix (`nix.nix`), time sync (`time.nix`).
- **`core/`**: OS core settings — i18n / locales (`i18n.nix`).
- **`security/`**: Security and secrets — SOPS integration (`sops.nix`).
- **`networking/`**: Network settings — Nebula mesh VPN (`nebula.nix`), NAT loopback workaround (`local-network.nix`).
- **`environment/`**: System package groups (`my.packages.*`).
- **`hardware/`**: Hardware-specific modules — NVIDIA hybrid GPU (`nvidia.nix`), PC/server tools (`pc-tools.nix`).
- **`dev-tools/`**: Development hardware/tooling — WCH-LinkE udev rules, Ventoy.
- **`profiles/`**: Role-based host profiles (desktop, gateway, sbc, tower-server).
- **`services/`**: System services — backup (restic), Minecraft network, desktop services, Discord bridge.
- **`virtualisation/`**: Virtualisation — distrobox, microvm.