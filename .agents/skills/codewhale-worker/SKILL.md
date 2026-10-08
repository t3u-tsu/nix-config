---
name: codewhale-worker
description: Delegate implementation and coding tasks to Codewhale CLI (OpenRouter / DeepSeek). Use when implementing code changes, leaving requirements to Antigravity main and comment/doc cleanup to Antigravity subagents.
---

# Codewhale Worker

## Design Philosophy

- **Antigravity (Gemini)**: Quota is limited and precious, but excels at natural Japanese, nuanced requirements, architecture design, and clean documentation (Gemini 3.8 Flash / Pro). Use Antigravity for high-signal orchestration, planning, comment pruning (`hush`), and user communication.
- **Codewhale (Worker)**: Highly cost-effective coding agent with high cache hit rates running inexpensive models (DeepSeek). Offload heavy code exploration, file edits, and refactoring to Codewhale to protect Antigravity's quota.

## Role Division

1. **Antigravity Main**: Requirements, architecture design, coordination, and final synthesis.
2. **Codewhale**:
   - **Code Implementation & Refactoring**:
     - Run: `.agents/skills/codewhale-worker/scripts/run.sh "<PROMPT>"`
     - Overrides (when requested): `CODEPROVIDER=<provider> CODEMODEL=<model> ...` or `CONTINUE=1 ...`
     - Inspect: `.agents/skills/codewhale-worker/scripts/info.sh [search <keyword> | update]`
   - **Technical Review**:
     - Strong at deep technical reasoning, Nix language semantics, Linux/systemd internals, and edge-case detection.
     - Review code diffs and technical statements in documentation (commands, paths, systemd units, network topology).
     - Run: `.agents/skills/codewhale-worker/scripts/review.sh "<PROMPT>"`
     - Or with diff: `DIFF_RANGE="origin/main..HEAD" .agents/skills/codewhale-worker/scripts/review.sh`
     - Or with files: `FILES="path/to/file.nix" .agents/skills/codewhale-worker/scripts/review.sh`
3. **Antigravity Subagent**:
   - **Natural Language & Documentation Review**:
     - Japanese / English natural flow, phrasing, tone consistency, and punctuation (`，．`).
     - Structural integrity, SSOT compliance, and cross-references in `docs/`.
   - **Comment Pruning & Hush Review**:
     - Enforce `hush` rule (`~/.agents/skills/hush/SKILL.md`) — remove redundant comments, ensure names speak for themselves.

## Prompting Rules for Codewhale

### Implementation Tasks
Always adhere to these rules when delegating coding:
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

### Technical Review Tasks
When delegating technical reviews:
1. Specify target files or diff range clearly.
2. Instruct strictly read-only evaluation.
3. Review criteria: technical validity, systemd/network/NixOS correctness, failure modes, security.

```text
Review Target: <diff range or file paths>
Focus: <e.g. systemd service definitions, restic restore logic, networking>
Instructions:
- Verify that commands, unit names, and Nix options match actual repository configs.
- Identify edge cases, race conditions, permission issues, or missing steps.
- Provide concrete suggested fixes with code snippets.
```

## Review & Post-Processing (Antigravity's Job)

After Codewhale finishes an implementation or review:
1. **Combine reviews**: Synthesize Codewhale's technical findings with Antigravity subagent's natural language / style findings.
2. **Refine comments and text**: Use an Antigravity subagent to prune redundant comments per `hush` and maintain Japanese punctuation (`，．`).
3. **Verify**: Run `nix flake check` or dry-run builds.
4. **Commit & Report**: Commit with Conventional Commits (English) and report to user in natural Japanese (`，．`).
