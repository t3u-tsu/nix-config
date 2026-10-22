# AI Development Tools (`home/desktop/dev-tools/ai-tools/`)

Autonomous coding agents, MCP server integrations, and agent skills managed with Home Manager. All modules use the `my.home.desktop.dev-tools.ai-tools.enable` gate, which defaults to `my.home.desktop.full.enable`.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [antigravity.nix](antigravity.nix) | Google Antigravity agent CLI (`agy`). | Packaged via `inputs.llm-agents` |
| [pi.nix](pi.nix) | Terminal coding agent (`pi`). | Packaged via `inputs.llm-agents` |
| [deepseek-harness.nix](deepseek-harness.nix) | DeepSeek Harness (`dsh`) CLI and the `deepseek-harness` symlink alias. | Packaged via `inputs.llm-agents` |
| [codewhale.nix](codewhale.nix) | Terminal coding agent for DeepSeek models (`codewhale`). | Binary release tracked by `nvfetcher` |
| [conoha-vps-mcp.nix](conoha-vps-mcp.nix) | ConoHa VPS MCP server for CodeWhale with SOPS credentials and a schema sanitizer wrapper. | Installs Node.js and writes `~/.codewhale/mcp.json` |
| [skills.nix](skills.nix) | Agent skills deployment into `~/.agents/skills/`. | Links the external `hush` skill (via `nvfetcher`) and the repository [skills/ysh/](skills/ysh) |
| [default.nix](default.nix) | AI tooling module aggregator. | Declares `my.home.desktop.dev-tools.ai-tools.enable` |

## Model Context Protocol (MCP) Integration

The [conoha-vps-mcp.nix](conoha-vps-mcp.nix) module exposes ConoHa VPS management tools to CodeWhale.

| Component | Behavior |
| :--- | :--- |
| Schema sanitizer | The [conoha-schema-fix.js](conoha-schema-fix.js) wrapper rewrites regex `pattern` values that contain lookaheads, which CodeWhale rejects, into length-bounded patterns in every tool `inputSchema` and `outputSchema`. |
| SOPS credentials | The `sops.templates."codewhale-mcp.json"` entry injects `OPENSTACK_TENANT_ID`, `OPENSTACK_USER_ID`, and `OPENSTACK_PASSWORD` from [secrets/services/conoha-vps-mcp.yaml](../../../../secrets/services/conoha-vps-mcp.yaml). |
| Activation hook | `home.activation.conohaMcpConfig` copies the rendered template to `~/.codewhale/mcp.json` with `0600` permissions after `sops-nix` runs. |

## References

- Parent development tools: [home/desktop/dev-tools/](../README.md)
- Agent coding skills: [.agents/skills/](../../../../.agents/skills/)
- ConoHa VPS secrets: [secrets/services/conoha-vps-mcp.yaml](../../../../secrets/services/conoha-vps-mcp.yaml)
- Generated package sources: [_sources/generated.nix](../../../../_sources/generated.nix)
