# Development Tools

This directory contains user-specific development environment configurations.

## 📂 Modules

- **`neovim.nix`**: Core Neovim configuration, including aliases (`vi`, `vim`) and a custom desktop entry (`nvim-ghostty`) for file managers.
- **`git-tools.nix`**: Modern Git TUI tools like `lazygit`.
- **`ai-tools.nix`**: AI-assisted development tools (e.g., `gemini-cli`).
- **`hardware.nix`**: KiCad and picocom for hardware development. Also configures system-level udev rules for WCH-LinkE (ch32fun) programming/debugging.
- **`vscode.nix`**: Optional Visual Studio Code configuration with declarative extensions.
- **`unity.nix`**: Unity Hub for game development.
- **`default.nix`**: Index module to manage the enablement of development tool categories.
