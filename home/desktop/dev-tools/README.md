# Development Tools

User-specific developer tooling managed with Home Manager.

## Modules

| Module / Directory | Description | Profile |
| :--- | :--- | :--- |
| [`neovim.nix`](neovim.nix) | Neovim configuration with palette-driven highlights and desktop entries. | Core (`dev-tools.enable`) |
| [`ghostty.nix`](ghostty.nix) | Ghostty GPU-accelerated terminal emulator configuration. | Core (`dev-tools.enable`) |
| [`git-tools.nix`](git-tools.nix) | Git TUIs (LazyGit), forge CLIs (`gh`), and credential helpers. | Core (`dev-tools.enable`) |
| [`nix.nix`](nix.nix) | Nix developer utilities (`nix-tree`, `nix-output-monitor`, formatting/linting). | Core (`dev-tools.enable`) |
| `ai-tools/` | AI coding agents (`agy`, `pi`, `dsh`, CodeWhale, ConoHa MCP, agent skills). | Full (`full.enable`) |
| [`hardware.nix`](hardware.nix) | EDA tools (KiCad, Qucs-S), serial monitor (picocom), and Ventoy. | Full (`full.enable`) |
| [`unity.nix`](unity.nix) | Unity Editor environment via Distrobox container. | Full (`full.enable`) |
| [`default.nix`](default.nix) | Aggregator and default enablement rules. | — |

## AI Tooling (`ai-tools/`)

Coding assistant modules configured under `ai-tools/`:

| File | Tool / Function | Source |
| :--- | :--- | :--- |
| `antigravity.nix` | Antigravity CLI (`agy`) | [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) |
| `pi.nix` | Pi coding agent (`pi`) | [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) |
| `deepseek-harness.nix` | DeepSeek Harness (`dsh`) | [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) |
| `codewhale.nix` | CodeWhale binary package | Tracked by `nvfetcher` |
| `conoha-vps-mcp.nix` | ConoHa VPS MCP server | Local Node.js MCP server with SOPS API credentials |
| `skills.nix` | Agent skills installation | Installs `hush` (via `nvfetcher`) and `ysh` (`skills/ysh`) |

## References

- Hardware udev rules: [`nixos/dev-tools/wch-linke.nix`](../../../nixos/dev-tools/wch-linke.nix)
- Agent skills documentation: [`.agents/skills/`](../../../.agents/skills/)
