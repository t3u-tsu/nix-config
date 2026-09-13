# Development Tools

User-specific development environment configuration.

## Modules

- **`neovim.nix`**: Editor configuration — palette-driven highlight groups, `vi`/`vim` aliases and a desktop entry for file managers.
- **`git-tools.nix`**: Git TUI, forge CLI and the Git credential helper.
- **`nix.nix`**: Nix ecosystem tooling — store inspection, build monitoring, formatting and linting.
- **`ai-tools.nix`**: AI-assisted development tools. Enabled with the desktop full stack (`my.home.desktop.full.enable`).
- **`conoha-vps-mcp.nix`**: MCP server integration for the agent CLI, with SOPS-injected credentials.
- **`mcp/`**: Schema-fix wrapper for the MCP server (`conoha-schema-fix.js`), used by ai-tools.
- **`hardware.nix`**: EDA tooling, serial console and USB installer writing. The system-level udev rules for the WCH-LinkE programmer live in `nixos/dev-tools/wch-linke.nix`. Enabled with the desktop full stack.
- **`ghostty.nix`**: Terminal emulator configuration.
- **`unity.nix`**: Game engine tooling from the standalone [unity-via-distrobox-flake](https://github.com/t3u-tsu/unity-via-distrobox-flake) repository (Distrobox-based Ubuntu 22.04 container). Enabled with the desktop full stack (`my.home.desktop.full.enable`).
- **`default.nix`**: Index module for the development tool categories.
