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
    ├── packages/       # System package groups (base, monitoring, etc.)
    ├── home/           # User environment via Home-manager (Shell, Desktop, SSH)
    ├── services/       # Various services (Minecraft, Update Hub, Desktop)
    └── profiles/       # Role-based profiles (Desktop, Tower Server)
```

## 🚀 Deployment and Updates

Normally, changes are automatically reflected across all hosts via **Update Hub** after pushing to GitHub.

### Immediate Reflect (Global)
After pushing to GitHub, you can trigger updates on all hosts by notifying the Hub:
```bash
curl -X POST -H "Content-Type: application/json" -d "{\"commit\": \"$(git rev-parse HEAD)\", \"host\": \"$(hostname)\"}" http://10.0.0.1:8080/producer/done
```

## 🛠️ Key Features

- **Modular Architecture**: Clear separation between system (NixOS) and user (Home-manager) layers.
- **Modern CLI Tools**: Starship, Atuin, Zellij, Yazi, fzf, ripgrep standardized across all hosts.
- **Desktop Environment**: Powered by Zen Browser (declarative), Vesktop, Neovim, and Alacritty.
- **Smart Hardware Tools**: Opt-in to physical server tools via `my.hardware.pc-tools.enable = true`.
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