# My NixOS Fleet

This repository manages multiple NixOS configurations using Flakes and a **Modular Architecture**.

## 📂 Directory Structure

The repository is divided into "Mechanisms (Modules)" and "Entities (Hosts)".

```text
.
├── flake.nix           # Entry point for the configuration
├── hosts/              # Host-specific configurations
└── modules/            # Reusable modules
    ├── core/           # Base settings (Nix, Network, User, Sops)
    ├── hardware/       # Hardware abstraction (NVIDIA, PCIe tools, etc.)
    ├── packages/       # System package groups (base, monitoring, etc.)
    ├── home/           # User environment via Home-manager (Shell, Desktop, SSH)
    ├── services/       # Various services (Minecraft, Desktop)
    └── profiles/       # Role-based profiles (Desktop, Tower Server)
```

## 🚀 Deployment and Updates

Changes pushed to the `main` branch are automatically pulled and applied across all hosts via **comin** every 5 minutes. No manual trigger or central server is required.

## 🛠️ Key Features

- **Modular Architecture**: Clear separation between system (NixOS) and user (Home-manager) layers.
- **Unified Hardware Abstraction**: NVIDIA driver settings are centralized and architecture-aware (x86_64/AArch64).
- **Modern CLI Tools**: Starship, Atuin, Zellij, Yazi, fzf, ripgrep standardized across all hosts.
- **Desktop Environment**: Powered by Zen Browser (declarative), Vesktop, Neovim, and WezTerm.
- **Smart Hardware Tools**: Opt-in to physical server tools via `my.hardware.pc-tools.enable = true`.
- **Fleet Monitoring Dashboard**: Global metrics aggregated from all hosts via Prometheus and visualized centrally on `torii-chan` using Grafana.
- **sops-nix**: Secret encryption via `age`.
- **Automated Backup**: Restic backups managed on shosoin-tan.

For more details, see [GEMINI.md](GEMINI.md) or specific `README.md` files in subdirectories.

## 📚 References

This configuration was built with inspiration and knowledge from the following amazing repositories:

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: Overall modular architecture and Niri setup.
- **[omarchy-nix](https://github.com/henrysipp/omarchy-nix)**: Intuitive keybindings (Omarchy style).
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Declarative Zen Browser configuration.
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: Best practices for NixOS and Home-manager.
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: Structured module design.
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: Specialized Noctalia Shell configuration and Japanese desktop environment layout.