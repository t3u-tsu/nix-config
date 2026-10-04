---
name: codewhale-worker
description: Delegate implementation and coding tasks to Codewhale CLI (OpenRouter / DeepSeek). Use when implementing code changes, leaving requirements to Antigravity main and comment/doc cleanup to Antigravity subagents.
---

# Codewhale Worker

## Design Philosophy

- **Antigravity (Gemini)**: Quota is limited and precious, but excels at natural Japanese, nuanced requirements, architecture design, and clean documentation (Gemini 3.8 Flash / Pro). Use Antigravity for high-signal orchestration, planning, comment pruning (`hush`), and user communication.
- **Codewhale (Worker)**: Highly cost-effective coding agent with high cache hit rates running inexpensive models (DeepSeek). Offload heavy code exploration, file edits, and refactoring to Codewhale to protect Antigravity's quota.

## Role Division

1. **Antigravity Main**: Requirements, architecture design, and coordination.
2. **Codewhale**: Code implementation and refactoring:
   - Run: `.agents/skills/codewhale-worker/scripts/run.sh "<PROMPT>"`
   - Overrides (when requested): `CODEPROVIDER=<provider> CODEMODEL=<model> ...` or `CONTINUE=1 ...`
   - Inspect: `.agents/skills/codewhale-worker/scripts/info.sh [search <keyword> | update]`
3. **Antigravity Subagent**: Comment cleanup per `hush` (`~/.agents/skills/hush/SKILL.md`) and documentation updates (`，．`).

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
