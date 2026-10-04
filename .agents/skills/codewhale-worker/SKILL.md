---
name: codewhale-worker
description: Delegate implementation and coding tasks to Codewhale CLI (OpenRouter / DeepSeek). Use when implementing code changes, leaving requirements to Antigravity main and comment/doc cleanup to Antigravity subagents.
---

# Codewhale Worker

Antigravity orchestrates, Codewhale implements.

## Role Division

- **Antigravity Main**: Requirements, architecture design, overall coordination.
- **Codewhale**: Code implementation and exploration (default: `openrouter` / `deepseek/deepseek-v4.1-flash`).
- **Antigravity Subagent**: Comment cleanup per `hush` (`~/.agents/skills/hush/SKILL.md`) and documentation updates (`，．`).

## Delegation Routing

Unless specified otherwise, delegate implementation tasks to Codewhale default automatically.

| User Trigger | Provider / Model | Command Override |
| :--- | :--- | :--- |
| Default (unspecified) | `openrouter` / `deepseek/deepseek-v4.1-flash` | `.agents/skills/codewhale-worker/scripts/run.sh "<PROMPT>"` |
| "deepseek で" | `deepseek` / `deepseek-flash` | `CODEPROVIDER=deepseek CODEMODEL=deepseek-flash ...` |
| "fireworks で" | `fireworks` | `CODEPROVIDER=fireworks ...` |
| "直して" / continue | Previous session | `CONTINUE=1 ...` or `SESSION=<id> ...` |
| "Gemini で" / "直接" | Antigravity Main | Edit directly without Codewhale |

*Tip: Run `.agents/skills/codewhale-worker/scripts/info.sh` to check routes or `info.sh search <keyword>` to locate models.*

## Prompting Rules for Codewhale

Always adhere to these rules when delegating:
1. **English only**: Always compose prompts in concise English.
2. **Hush rule**: Instruct "No explanatory or restating comments. Self-documenting naming only."
3. **Scope rule**: Instruct "Do NOT edit documentation or README files."

```text
Task: <goal>
Target files: <list of files>
Instructions: <concise steps>
Constraints:
- No explanatory or obvious comments. Self-documenting naming only.
- Do NOT edit documentation or README files.
- Follow nixpkgs conventions and formatting.
```

## Post-Processing (Antigravity's Job)

After Codewhale finishes:
1. Check `git diff`. Use an Antigravity subagent to prune redundant comments per `hush` and write/update docs if needed.
2. Verify via `nix flake check` or dry-run builds.
3. Commit with Conventional Commits (English) and report to user in Japanese (`，．`).
