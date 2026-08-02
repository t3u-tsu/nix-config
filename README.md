# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[日本語](README.ja.md)

Centralized NixOS fleet configurations managed declaratively using Nix Flakes.

## Directory Structure

```text
.
├── flake.nix            # flake-parts entrypoint
├── flake/               # flake-parts modules
│   ├── overlays.nix     # Nixpkgs overlays
│   └── hosts.nix        # nixosConfigurations
├── nixos/               # NixOS system modules
│   ├── base/            # OS foundation (users, Nix, time)
│   ├── core/            # OS core settings (i18n)
│   ├── security/        # Security and secrets (SOPS)
│   ├── networking/      # Network settings (hosts, WireGuard)
│   ├── environment/     # System packages
│   ├── hardware/        # Hardware-specific modules (NVIDIA, etc.)
│   ├── profiles/        # Role-based host profiles (desktop, tower-server, sbc, gateway)
│   └── services/        # System services (backup, Minecraft, deployment, etc.)
├── home/                # Home Manager modules
│   ├── shell/           # Shell configuration (Zsh, Starship, Atuin)
│   ├── programs/        # Workstation tools (CLI tools, Git, SSH)
│   └── desktop/         # Desktop environment (Niri, browsers, theme, etc.)
├── hosts/               # Host-specific configurations
│   ├── BrokenPC/        # Desktop PC (NixOS)
│   ├── torii-chan/      # VPN gateway role (SBC aarch64 + VPS failover)
│   ├── shosoin-tan/     # Tower server (NixOS)
│   ├── kagutsuchi-sama/ # Tower server (NixOS)
│   └── sando-kun/       # Tower server (NixOS)
├── lib/                 # Helper functions (mkSystem)
└── secrets/             # SOPS-encrypted secrets
```

## Quick Start

To apply configurations to the local machine:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

For remote machines (e.g. torii-chan on Orange Pi Zero 3):

```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password
```

For more specific deployment details, check the respective README.md files in hosts/ and modules/.

## CI/CD and Automation

This repository uses GitHub Actions for continuous integration and automated updates:

- **Nix Flake Check** (`nix-check.yml`): Runs `nix flake check` automatically on pushes to `main`/`feat/*`/`fix/*`/`refactor/*`/`docs/*`/`chore/*` and on pull requests to ensure that configuration evaluation is clean.
- **Scheduled Auto Update** (`auto-update.yml`): Runs daily at 04:00 JST. It automatically runs `nvfetcher` to fetch the latest Minecraft plugins and updates `flake.lock` to bump system packages, committing changes directly back to `main`.

## References

This configuration was built with inspiration and knowledge from the following repositories:

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: Overall modular architecture and Niri setup.
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Declarative Zen Browser configuration.
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: Best practices for NixOS and Home-manager.
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: Structured module design.
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: Specialized Noctalia configuration and Japanese desktop environment layout.
