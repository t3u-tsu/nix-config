# Development Tools

User-specific development environment configuration.

## Modules

- **`neovim.nix`**: Neovim configuration — Vesper highlight groups, `vi`/`vim` aliases and an `nvim-ghostty` desktop entry for file managers.
- **`git-tools.nix`**: `lazygit`, `gh`, and the Git credential helper.
- **`nix.nix`**: Nix ecosystem tools — nh, nix-du, nix-output-monitor, nix-tree, nixfmt, statix.
- **`ai-tools.nix`**: AI-assisted development tools (CodeWhale, Node.js for the ConoHa MCP). Enabled with the desktop full stack (`my.home.desktop.full.enable`).
- **`conoha-vps-mcp.nix`**: ConoHa VPS MCP server integration for codewhale, with SOPS-injected credentials.
- **`mcp/`**: ConoHa VPS MCP schema-fix wrapper (`conoha-schema-fix.js`), used by ai-tools.
- **`hardware.nix`**: KiCad, Qucs-S, picocom and Ventoy. The system-level udev rules for WCH-LinkE (ch32fun) programming live in `nixos/dev-tools/wch-linke.nix`. Enabled with the desktop full stack.
- **`ghostty.nix`**: Ghostty terminal configuration.
- **`unity.nix`**: Unity Hub for game development, provided by the standalone [unity-via-distrobox-flake](https://github.com/t3u-tsu/unity-via-distrobox-flake) repository (Distrobox-based Ubuntu 22.04 container). Enabled with the desktop full stack (`my.home.desktop.full.enable`).
- **`default.nix`**: Index module for the development tool categories.
