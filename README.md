# nix-config

Centralized NixOS fleet configurations managed declaratively using Nix Flakes.

## Directory Structure

```text
.
├── flake.nix        # System entrypoint
├── hosts/           # Host-specific configurations (BrokenPC, torii-chan, etc.)
└── modules/         # Reusable modules
    ├── core/        # Base system configuration (Nix, networking, SOPS)
    ├── hardware/    # Hardware-specific modules (NVIDIA, etc.)
    ├── home/        # User environment (Home Manager)
    ├── packages/    # System package groups
    ├── profiles/    # Role-based host profiles
    └── services/    # Specialized services (Backup, Minecraft, etc.)
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

## References

This configuration was built with inspiration and knowledge from the following repositories:

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: Overall modular architecture and Niri setup.
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Declarative Zen Browser configuration.
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: Best practices for NixOS and Home-manager.
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: Structured module design.
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: Specialized Noctalia configuration and Japanese desktop environment layout.
