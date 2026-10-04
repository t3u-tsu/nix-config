---
name: codewhale-worker
description: Delegate implementation, coding, exploration, or refactoring tasks to the Codewhale CLI agent running DeepSeek models (e.g. deepseek-flash). Use whenever a task requires writing or editing code, exploring the repository, or executing tests, allowing Antigravity (Gemini) to orchestrate, refine prompts, clean up comments according to hush rules, write documentation, and report to the user.
---

# Codewhale Worker Delegation Skill

This skill defines the workflow for using Codewhale (running DeepSeek models like `deepseek-flash`) as an implementation worker agent, while Antigravity (Gemini) acts as the orchestrator, reviewer, documenter, and user interface.

## Workflow Overview

1. **Plan & Draft Prompt (Antigravity)**: Analyze user requests, determine files to change, and compose an explicit instruction in English.
2. **Execute Worker (Codewhale)**: Run `codewhale` non-interactively with `--auto` to implement the changes.
3. **Review & Hush (Antigravity)**: Inspect `git diff`, strip unnecessary explanatory comments per the `hush` skill, and ensure formatting and correctness.
4. **Verify & Build (Antigravity)**: Run `nix flake check` or relevant build checks per `dev-workflow`.
5. **Document & Commit (Antigravity)**: Update documentation (`README.md`, `README.ja.md`, `docs/`) with Japanese punctuation `，．`, generate conventional commits in English, and report to the user.

---

## Step 1: Composing the Worker Prompt

DeepSeek excels at code logic and exploration, but struggles with verbose/unnatural Japanese and tends to generate excessive obvious comments. Always adhere to these rules when delegating:

- **Language**: Always write the prompt in **English**.
- **Hush Constraint**: Explicitly instruct it not to add explanatory or restating comments.
- **Scope Limitation**: Clearly specify target files/directories and explicitly instruct it NOT to edit documentation or README files.

### Prompt Template

```text
Task: <Brief description of the implementation goal>

Target files:
- <path/to/target1.nix>
- <path/to/target2.nix>

Instructions:
1. <Specific requirement 1>
2. <Specific requirement 2>

Constraints:
- Strictly follow self-documenting naming. Do NOT write obvious, narrating, or redundant comments. Only add a comment if there is a non-obvious invariant or external constraint (max 3 lines).
- Do NOT edit documentation files, READMEs, or AGENTS.md.
- Ensure the code follows nixpkgs conventions and formatting.
```

---

## Step 2: Executing Codewhale

Use the helper script or run the command directly:

```bash
# Using the helper script
.agents/skills/codewhale-worker/scripts/run.sh "<PROMPT>"

# Or direct invocation:
codewhale --provider deepseek --model deepseek-flash exec --auto "<PROMPT>"
```

### Helper Script Execution & Log Redirection

The `run.sh` script executes Codewhale with full log redirection to `/tmp/codewhale-<timestamp>.log` to suppress excessive tool logs and terminal output from flooding Antigravity's context window. It captures the exit code safely, outputs only the final model response, prints changed files via `git status --short`, and provides session continuation instructions.

### Provider & Model Selection Guide

- **Recommended Default**: `provider = "deepseek"`, `model = "deepseek-flash"`
  - **Critical**: In the current version, `deepseek-flash` is significantly smarter and more reliable for coding and reasoning than `deepseek-v4-pro`. Always prioritize `deepseek-flash` as the primary worker model.
  - Avoid switching to `deepseek-v4-pro` assuming it is more powerful; current versioning makes `deepseek-flash` the superior choice.
- **Configured Providers**:
  - `deepseek` (default): Native DeepSeek API, highly recommended.
  - `openrouter`: Configured with access to models like `deepseek/deepseek-v4.1-flash`.
  - `fireworks`: Configured in `~/.codewhale/config.toml` (e.g. `accounts/fireworks/models/deepseek-v4p1-flash`).
- **Session Continuation**:
  - If the initial run needs iterative adjustments or follow-up fixes, use `CONTINUE=1 .agents/skills/codewhale-worker/scripts/run.sh "<FOLLOW_UP_PROMPT>"` or specify a session explicitly via `SESSION=<id> .agents/skills/codewhale-worker/scripts/run.sh "<FOLLOW_UP_PROMPT>"` (or pass `--continue` / `--resume <id>`).

### Inspecting and Updating Providers & Models via CLI Helper

Antigravity or the user can check available providers, refresh model catalogs, and search models dynamically before delegation:

```bash
# Show current active route and list all authenticated providers
.agents/skills/codewhale-worker/scripts/info.sh

# Refresh cached model catalogs across configured providers
.agents/skills/codewhale-worker/scripts/info.sh update
# or: .agents/skills/codewhale-worker/scripts/info.sh --update

# Search across all authenticated providers for a model keyword (e.g. v4.1, flash)
.agents/skills/codewhale-worker/scripts/info.sh search v4.1

# List all models available under a specific provider
.agents/skills/codewhale-worker/scripts/info.sh models openrouter
```

---

## Step 3: Review and Hush Post-Processing

After Codewhale finishes:

1. Run `git status` and `git diff` to review all changes.
2. Apply the **Hush Rules** (`~/.agents/skills/hush/SKILL.md`):
   - Remove comments that merely restate variable names, function names, or obvious loop mechanics.
   - Replace comments with descriptive names whenever possible.
   - Keep only critical comments explaining *why* (non-obvious constraints, workarounds, invariants).
3. Verify Nix configurations:
   ```bash
   nix flake check
   # Or dry-run build for a specific host if applicable
   ```

---

## Step 4: Documentation and Reporting

1. **Documentation**:
   - If user-facing or architectural changes occurred, Antigravity writes/updates documents in `docs/` or `README.md` / `README.ja.md`.
   - In Japanese documents, strictly use `，．` for punctuation.
2. **Commit**:
   - Commit with Conventional Commits format in English (e.g. `feat(nixos): add ...`).
3. **User Communication**:
   - Report the outcome clearly to the user in natural Japanese.
