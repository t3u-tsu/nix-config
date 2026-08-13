# Development Tools

This directory contains user-specific development environment configurations.

## Modules

- **`neovim.nix`**: Core Neovim configuration, including aliases (`vi`, `vim`) and a custom desktop entry (`nvim-ghostty`) for file managers.
- **`git-tools.nix`**: Modern Git TUI tools like `lazygit`.
- **`nix.nix`**: Nix ecosystem development and management tools (devenv, nh, nixfmt, statix, nix-tree).
- **`ai-tools.nix`**: AI-assisted development tools (e.g., `CodeWhale`, `GitHub Copilot`).
- **`mcp/`**: ConoHa VPS MCP schema-fix wrapper (conoha-schema-fix.js), used by ai-tools for codewhale integration.
- **`hardware.nix`**: KiCad, Qucs-S and picocom for hardware development. Also configures system-level udev rules for WCH-LinkE (ch32fun) programming/debugging.
- **`ghostty.nix`**: Ghostty terminal configuration.
- **`unity`**: Unity Hub for game development, provided by the standalone [unity-via-distrobox-flake](https://github.com/t3u-tsu/unity-via-distrobox-flake) repository (Distrobox-based Ubuntu 22.04 container).
- **`default.nix`**: Index module to manage the enablement of development tool categories.
