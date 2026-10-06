# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[日本語](README.ja.md)

A central declarative repository managing personal workstations, servers, and network gateways using Nix Flakes.

## Tech Stack

| Component | Technology |
| :--- | :--- |
| **OS** | NixOS 26.05 |
| **WM / Compositor** | niri (Wayland) |
| **Bar / Shell** | Noctalia |
| **Shell** | zsh + pure + Atuin |
| **Terminal** | Ghostty |
| **Editor** | Neovim |
| **Browser** | Zen Browser |
| **Color Theme** | Vesper |
| **Secrets** | SOPS (sops-nix) + age |
| **Mesh VPN** | Nebula |
| **Backup** | Restic + ZFS Mirror |
| **IaC** | OpenTofu |

## Directory Structure

- [`flake.nix`](flake.nix) — Flake-parts entrypoint
- [`flake/`](flake/) — Flake-parts modules (`hosts`, `lib`, `overlays`, `packages`, `dev`)
- [`lib/`](lib/) — `mkSystem` builder and shared color palette
- [`nixos/`](nixos/) — Shared system-level NixOS modules
- [`home/`](home/) — Home Manager user-level configurations
- [`hosts/`](hosts/) — Host definitions and hardware configurations
- [`secrets/`](secrets/) — Encrypted secrets managed via SOPS
- [`scripts/`](scripts/) — Fleet management and maintenance utility scripts
- [`terraform/`](terraform/) — ConoHa VPS infrastructure definitions (OpenTofu)
- [`docs/`](docs/) — Complete architecture, operations, hardware, and troubleshooting documentation (SSOT)

For detailed system architecture and evaluation flow, see [`docs/architecture/overview.md`](docs/architecture/overview.md). Complete operational runbooks and guides are indexed in [`docs/README.md`](docs/README.md).

Sensitive data is isolated in a private repository ([`nix-config-private`](https://github.com/t3u-tsu/nix-config-private)) and imported as a flake input. For initial machine setup and authentication bootstrap, refer to [`docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md).

## Quick Start

Available host configurations (defined in `flake/hosts.nix`):

- **`x1c7`** — Laptop (ThinkPad X1 Carbon Gen 7)
- **`BrokenPC`** — Secondary portable laptop (HP Victus 16-e1065AX)
- **`shosoin-tan`**, **`kagutsuchi-sama`**, **`sando-kun`** — Tower server cluster
- **`torii-chan-sd`** / **`torii-chan-hdd`** — Edge VPN gateway on an Orange Pi Zero 3 SBC (SD / HDD boot)
- **`torii-chan-vps`** — Failover gateway on ConoHa VPS (x86_64)
- **`torii-chan-sd-installer`** — SD card installer image (`hosts/torii-chan/build-sd-image.sh`)
- **`torii-chan-vps-iso`** — VPS rescue installer ISO package (`nix build .#torii-chan-vps-iso`)

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

Follow the comprehensive step-by-step runbook in [`docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md). It covers copying the [`hosts/_template/`](hosts/_template) skeleton, generating SOPS age keys, issuing Nebula certificates, and deployment verification.

## CI/CD & Automation

- **Nix Flake Check** ([`nix-check.yml`](.github/workflows/nix-check.yml)): Evaluates all hosts, executes pre-commit linters (`nixfmt`, `statix`, `shellcheck`, `ja-punctuation`), and enforces Conventional Commits via `convco`.
- **Scheduled Auto Update** ([`auto-update.yml`](.github/workflows/auto-update.yml)): Runs daily at 04:00 JST. Synchronizes upstream sources via nvfetcher, updates `flake.lock`, validates changes, and automatically pushes updates to `main`.

## Documentation

Comprehensive architecture designs, operational runbooks, hardware guides, and troubleshooting procedures are documented in [`docs/README.md`](docs/README.md).

## References

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
