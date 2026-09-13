# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[日本語](README.ja.md)

Centralized NixOS fleet configurations managed declaratively using Nix Flakes.

## Directory Structure

- [`flake.nix`](flake.nix) — flake-parts entrypoint
- [`flake/`](flake/) — flake-parts modules (hosts, lib, overlays, packages, dev)
- [`lib/`](lib/) — mkSystem helper
- [`nixos/`](nixos/) — system-wide modules
- [`home/`](home/) — home-manager modules
- [`hosts/`](hosts/) — per-machine configurations
- [`secrets/`](secrets/) — SOPS-encrypted secrets
- [`scripts/`](scripts/) — operational scripts
- [`terraform/`](terraform/) — ConoHa VPS infrastructure

[`docs/architecture.md`](docs/architecture.md) explains how these layers are loaded.

## Quick Start

Available configurations (defined in `flake/hosts.nix`):

- **`BrokenPC`** — gaming laptop (local machine)
- **`x1c7`** — laptop (ThinkPad X1 Carbon Gen 7)
- **`shosoin-tan`**, **`kagutsuchi-sama`**, **`sando-kun`** — tower servers
- **`torii-chan-sd`** / **`torii-chan-hdd`** — VPN gateway on the Orange Pi Zero 3 SBC (SD / HDD root)
- **`torii-chan-vps`** — same gateway role on the failover VPS (x86_64)
- **`torii-chan-sd-installer`** — SD installer image (see [`hosts/torii-chan/README.md`](hosts/torii-chan/README.md))
- **`torii-chan-vps-iso`** — VPS installer ISO, exposed as a **package** (not a nixosConfiguration): `nix build .#torii-chan-vps-iso`

To apply configurations to the local machine:

```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

For remote machines (e.g. torii-chan on Orange Pi Zero 3):

```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

The `sandbox false` / `filter-syscalls false` flags are required: the Orange Pi kernel lacks `user_namespaces` / `seccomp BPF` (see [`hosts/torii-chan/README.md`](hosts/torii-chan/README.md)).

## Adding a New Host

Copy [`hosts/_template/`](hosts/_template) and follow [`hosts/README.md`](hosts/README.md) for registration, SOPS keys, Nebula certificates, and deployment.

## CI/CD and Automation

- **Nix Flake Check** (`nix-check.yml`): on every push and pull request — one job runs `nix flake check`, which evaluates every host and runs the formatting and linting hooks; another checks the commit messages with `convco`.
- **Scheduled Auto Update** (`auto-update.yml`): daily at 04:00 JST — updates the Minecraft plugin pins (`nvfetcher`) and `flake.lock`, validates them with `nix flake check`, and commits directly to `main`.

## References

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
