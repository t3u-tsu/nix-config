# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[日本語](README.ja.md)

A central repository managing desktop environments and various servers using Nix Flakes.

## Tech Stack

|                  |                    |
| ---------------- | ------------------ |
| **OS**           | NixOS 26.05        |
| **WM**           | niri               |
| **Bar**          | Noctalia           |
| **Shell**        | zsh + pure + Atuin |
| **Terminal**     | Ghostty            |
| **Editor**       | Neovim             |
| **Browser**      | Zen Browser        |
| **Theme**        | Vesper             |
| **Secrets**      | SOPS               |
| **VPN**          | Nebula             |
| **Backup**       | restic             |
| **IaC**          | OpenTofu           |

## Directory Structure

- [`flake.nix`](flake.nix) — Flake-parts entrypoint
- [`flake/`](flake/) — Flake-parts modules (`hosts`, `lib`, `overlays`, `packages`, `dev`)
- [`lib/`](lib/) — `mkSystem` helper functions and shared color palette
- [`nixos/`](nixos/) — Shared NixOS modules across all hosts
- [`home/`](home/) — Home Manager modules
- [`hosts/`](hosts/) — Machine-specific configurations
- [`secrets/`](secrets/) — Encrypted secrets managed via SOPS
- [`scripts/`](scripts/) — Maintenance and operational utility scripts
- [`terraform/`](terraform/) — ConoHa VPS infrastructure definitions

For details on layer evaluation order and dependencies, see [`docs/architecture.md`](docs/architecture.md).

Sensitive personal data is isolated in a private repository, [`nix-config-private`](https://github.com/t3u-tsu/nix-config-private), and imported as a flake input.
Since every host evaluating this flake requires read access to this private repository, `nixos/base/private-config.nix` automatically configures a read-only deploy key (stored in `secrets/common.yaml`) and an SSH alias `github-nix-config-private`. However, on a machine where this module is not yet applied (e.g., fresh OS installations or hosts prior to adding the private input), flake evaluation will fail due to missing authentication. In such cases, root's SSH configuration must be set up manually for the initial bootstrap. Refer to [hosts/README.md](hosts/README.md#bootstrap-the-private-flake-input) for step-by-step instructions.

## Quick Start

Available host configurations (defined in `flake/hosts.nix`):

- **`x1c7`** — Laptop (ThinkPad X1 Carbon Gen 7)
- **`BrokenPC`** — Gaming Laptop (HP Victus 16-e1065AX)
- **`shosoin-tan`**, **`kagutsuchi-sama`**, **`sando-kun`** — Home server cluster (tower PCs)
- **`torii-chan-sd`** / **`torii-chan-hdd`** — VPN gateway on an Orange Pi Zero 3 SBC (booting from SD / HDD root)
- **`torii-chan-vps`** — Failover gateway on a VPS (x86_64)
- **`torii-chan-sd-installer`** — SD card installer image (see [`hosts/torii-chan/README.md`](hosts/torii-chan/README.md))
- **`torii-chan-vps-iso`** — VPS installer ISO (exposed as a **package**, not a nixosConfiguration: `nix build .#torii-chan-vps-iso`)

Apply configuration to the local machine:

```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

Deploy to a remote machine (e.g., Orange Pi Zero 3 `torii-chan`):

```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

> **Note:** The `--option sandbox false` and `--option filter-syscalls false` flags are required because the Orange Pi kernel does not support `user_namespaces` and `seccomp BPF` (see [`hosts/torii-chan/README.md`](hosts/torii-chan/README.md) for details).

## Adding a New Host

Duplicate [`hosts/_template/`](hosts/_template) and follow the instructions in [`hosts/README.md`](hosts/README.md). It guides you through registering the host, setting up SOPS keys, issuing Nebula certificates, and deployment.

## CI/CD & Automation

- **Nix Flake Check** ([`nix-check.yml`](.github/workflows/nix-check.yml)): Triggers on pushes and pull requests targeting the `main` branch. One job runs `nix flake check` (evaluates all hosts, formatting, and linting hooks), while another verifies commit message conventions using `convco`.
- **Scheduled Auto Update** ([`auto-update.yml`](.github/workflows/auto-update.yml)): Runs daily at 04:00 JST. Synchronizes package sources via nvfetcher, updates `flake.lock`, validates changes with `nix flake check`, and automatically commits passing updates to `main`.

## References

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
