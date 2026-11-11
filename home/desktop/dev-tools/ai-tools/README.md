# AI Development Tools (`home/desktop/dev-tools/ai-tools/`)

Autonomous coding agents, MCP server integrations, and agent skills managed with Home Manager. All modules use the `my.home.desktop.dev-tools.ai-tools.enable` gate, which defaults to `my.home.desktop.full.enable`.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [antigravity.nix](antigravity.nix) | Google Antigravity agent CLI (`agy`). | Packaged via `inputs.llm-agents` |
| [pi.nix](pi.nix) | Terminal coding agent (`pi`). | Packaged via `inputs.llm-agents` |
| [deepseek-harness.nix](deepseek-harness.nix) | DeepSeek Harness (`dsh`) CLI and the `deepseek-harness` symlink alias. | Packaged via `inputs.llm-agents` |
| [codewhale.nix](codewhale.nix) | Terminal coding agent for DeepSeek models (`codewhale`). | Binary release tracked by `nvfetcher` |
| [skills.nix](skills.nix) | Agent skills deployment into `~/.agents/skills/` and `~/.gemini/config/skills.json`. | Links `hush` and `dispatching-parallel-agents` (via `nvfetcher`) and the repository [skills/ysh/](skills/ysh) |
| [gcp-failover-mcp.nix](gcp-failover-mcp.nix) | GCP failover MCP server for AI coding agents (`gcp-failover-mcp`). | Exposes instance status, start, and stop tools, writes `~/.codewhale/mcp.json` |
| [default.nix](default.nix) | AI tooling module aggregator. | Declares `my.home.desktop.dev-tools.ai-tools.enable` |

## References

- Parent development tools: [home/desktop/dev-tools/](../README.md)
- Agent coding skills: [.agents/skills/](../../../../.agents/skills/)
- Generated package sources: [_sources/generated.nix](../../../../_sources/generated.nix)
