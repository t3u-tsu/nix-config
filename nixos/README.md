# NixOS System Modules

System-wide NixOS configuration, imported for all hosts via `nixos/default.nix`.

## Modules

- [`base/`](base/README.md): OS foundation — users (`user.nix`), Nix settings (`nix.nix`), time sync (`time.nix`).
- [`core/`](core/README.md): OS core settings — i18n / locales (`i18n.nix`).
- [`security/`](security/README.md): Security and secrets — SOPS integration (`sops.nix`).
- [`networking/`](networking/README.md): Network settings — Nebula mesh VPN (`nebula.nix`), NAT loopback workaround (`local-network.nix`).
- [`environment/`](environment/README.md): System package groups (`my.packages.*`).
- [`hardware/`](hardware/README.md): Hardware-specific modules — NVIDIA hybrid GPU (`nvidia.nix`), PC/server tools (`pc-tools.nix`).
- [`dev-tools/`](dev-tools/README.md): Development hardware — debug-probe udev rules and installer-USB approval.
- [`profiles/`](profiles/README.md): Role-based host profiles (desktop, gateway, sbc, tower-server).
- [`services/`](services/README.md): System services — backups, Minecraft network, desktop services, Discord bridge.
- [`virtualisation/`](virtualisation/README.md): Virtualisation — container environments and microVM guests.