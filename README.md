# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[日本語](README.ja.md)

Declarative NixOS configuration managing workstations, servers, and network gateways with Nix Flakes.

## Tech Stack

| Component | Technology |
| :--- | :--- |
| OS | NixOS 26.05 |
| WM / Compositor | niri (Wayland) |
| Desktop Shell / Bar | Noctalia |
| Shell | zsh + pure + Atuin |
| Terminal | Ghostty |
| Editor | Neovim |
| Browser | Zen Browser |
| Color Theme | Vesper |
| Secrets Management | agenix-rekey + agenix + age |
| Mesh VPN | Nebula |
| Backup | Restic + ZFS Mirror |
| IaC | OpenTofu |

## Directory Structure

- [flake.nix](flake.nix) — flake-parts entrypoint
- [flake/](flake/) — flake-parts modules (`hosts`, `lib`, `overlays`, `packages`, `dev`)
- [lib/](lib/) — `mkSystem` builder, shared color palette (`palette.nix`), and agenix master identity (`agenix.nix`)
- [nixos/](nixos/) — Shared system-level NixOS modules
- [home/](home/) — Home Manager user-level configurations
- [hosts/](hosts/) — Host definitions and hardware configurations
- [secrets/](secrets/) — Encrypted secrets managed via agenix-rekey
- [scripts/](scripts/) — Fleet management and maintenance scripts
- [terraform/](terraform/) — ConoHa VPS infrastructure definitions (OpenTofu)
- [docs/](docs/) — Architecture designs, operational runbooks, hardware guides, and troubleshooting procedures

See [docs/architecture/overview.md](docs/architecture/overview.md) for system architecture and module evaluation flow.

Sensitive data is isolated in a private repository ([nix-config-private](https://github.com/t3u-tsu/nix-config-private)) and imported as a flake input. For initial machine setup and authentication bootstrap, refer to [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md).

## Quick Start

Available host configurations (defined in [flake/hosts.nix](flake/hosts.nix)):

| Configuration | Role / Target Environment |
| :--- | :--- |
| `x1c7` | Primary laptop (ThinkPad X1 Carbon Gen 7) |
| `BrokenPC` | Portable gaming laptop (HP Victus 16-e1065AX) |
| `shosoin-tan`, `kagutsuchi-sama`, `sando-kun` | Tower server cluster |
| `torii-chan-sd` / `torii-chan-hdd` | Edge VPN gateway on Orange Pi Zero 3 SBC (SD / HDD boot) |
| `torii-chan-vps` | Failover gateway on ConoHa VPS (x86_64) |
| `torii-chan-sd-installer` | SD card installer image ([hosts/torii-chan/build-sd-image.ysh](hosts/torii-chan/build-sd-image.ysh)) |
| `torii-chan-vps-iso` | VPS rescue installer ISO package (`nix build .#torii-chan-vps-iso`) |

Apply configuration locally:
```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

Deploy to a remote machine over Nebula:
```bash
nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --sudo --ask-sudo-password
```

Deploy to SBC (`torii-chan`):
```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

## Adding a New Host

See [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md) for host setup: skeleton copy ([hosts/_template/](hosts/_template)), agenix host key registration, Nebula certificate issuance, and deployment verification.

## CI/CD & Automation

| Workflow | Trigger & Details |
| :--- | :--- |
| [Nix Flake Check](.github/workflows/nix-check.yml) | Evaluates all hosts, runs pre-commit linters (`nixfmt`, `statix`, `ysh-check`, `shellcheck`, `ja-punctuation`, `docs-check`), and enforces Conventional Commits via `convco` |
| [Scheduled Auto Update](.github/workflows/auto-update.yml) | Runs daily at 04:00 JST. Synchronizes upstream sources via nvfetcher, updates [flake.lock](flake.lock), validates in CI, and pushes updates to `main` |

## Documentation

Operational runbooks, architecture designs, hardware notes, and recovery procedures are indexed in [docs/README.md](docs/README.md).

## References

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
