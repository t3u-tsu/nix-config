# Development Tools (`home/desktop/dev-tools/`)

User-specific developer tooling managed with Home Manager.

## Modules

Core modules are enabled by default; full modules require `my.home.desktop.full.enable`.

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [neovim.nix](neovim.nix) | Neovim configuration with palette-driven highlights and a desktop entry. | Core (`my.home.desktop.dev-tools.neovim.enable`) |
| [ghostty.nix](ghostty.nix) | Ghostty GPU-accelerated terminal emulator configuration. | Core (`my.home.desktop.dev-tools.ghostty.enable`) |
| [git-tools.nix](git-tools.nix) | Git TUI (`lazygit`), GitHub CLI (`gh`), and `gh`-backed Git credential helper. | Core (`my.home.desktop.dev-tools.git-tools.enable`) |
| [nix.nix](nix.nix) | Nix utilities (`nh`, `nix-tree`, `nix-output-monitor`) and formatters/linters (`nixfmt`, `statix`). | Core (`my.home.desktop.dev-tools.nix.enable`) |
| [ai-tools/](ai-tools/README.md) | AI coding agents (`agy`, `pi`, `dsh`, `codewhale`), MCP servers, and agent skills. | Full (`my.home.desktop.dev-tools.ai-tools.enable`) |
| [hardware.nix](hardware.nix) | EDA tools (KiCad, Qucs-S), JLCPCB client (`jlcone`), serial monitor (`picocom`), and Ventoy. | Full (`my.home.desktop.dev-tools.hardware.enable`) |
| [unity.nix](unity.nix) | Unity Editor environment in a Distrobox container. | Full (`my.home.desktop.full.enable`) |
| [default.nix](default.nix) | Dev-tools category aggregator and option declarations. | — |

## References

- AI development tools index: [home/desktop/dev-tools/ai-tools/](ai-tools/README.md)
- Hardware udev rules: [nixos/dev-tools/wch-linke.nix](../../../nixos/dev-tools/wch-linke.nix)
- Agent skills documentation: [.agents/skills/](../../../.agents/skills/)
