# NixOS System Modules

System-wide NixOS configuration, imported for all hosts via `nixos/default.nix`.

## Modules

- [`base/`](base/): OS foundation — users (`user.nix`), Nix settings (`nix.nix`), time sync (`time.nix`).
- [`core/`](core/): OS core settings — i18n / locales (`i18n.nix`).
- [`security/`](security/): Security and secrets — SOPS integration (`sops.nix`).
- [`networking/`](networking/): Network settings — Nebula mesh VPN (`nebula.nix`), NAT loopback workaround (`local-network.nix`).
- [`environment/`](environment/): System package groups (`my.packages.*`).
- [`hardware/`](hardware/): Hardware-specific modules — NVIDIA hybrid GPU (`nvidia.nix`), PC/server tools (`pc-tools.nix`).
- [`dev-tools/`](dev-tools/): Development hardware — debug-probe udev rules and installer-USB approval.
- [`profiles/`](profiles/): Role-based host profiles (desktop, gateway, sbc, tower-server).
- [`services/`](services/): System services — backups, Minecraft network, desktop services, Discord bridge.
- [`virtualisation/`](virtualisation/): Virtualisation — container environments and microVM guests.