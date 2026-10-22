#!/usr/bin/env python3
"""Automatically convert in-text file references into relative markdown links.

Scans markdown files across the repository respecting .gitignore, finds backticked
tokens that correspond to actual files within the repository, and converts them to:
  [token](relative/path/to/token)
"""

import argparse
import fnmatch
import os
import re
import subprocess
import sys


def get_repo_root() -> str:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, ".."))


def get_repo_files(repo_root: str) -> list[str]:
    """Return all repository files respecting .gitignore."""
    try:
        res = subprocess.run(
            ["git", "ls-files", "-co", "--exclude-standard"],
            cwd=repo_root,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=True,
        )
        files = [
            line.strip()
            for line in res.stdout.splitlines()
            if line.strip() and os.path.isfile(os.path.join(repo_root, line.strip()))
        ]
        if files:
            return files
    except Exception:
        pass

    ignore_patterns = [".git"]
    gitignore_path = os.path.join(repo_root, ".gitignore")
    if os.path.exists(gitignore_path):
        with open(gitignore_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    ignore_patterns.append(line.rstrip("/"))

    all_files = []
    for root, dirs, filenames in os.walk(repo_root):
        rel_dir = os.path.relpath(root, repo_root)
        if rel_dir != ".":
            parts = rel_dir.split(os.sep)
            ignored = False
            for pat in ignore_patterns:
                if pat.startswith("!"):
                    continue
                if fnmatch.fnmatch(rel_dir, pat) or any(
                    fnmatch.fnmatch(part, pat) for part in parts
                ):
                    ignored = True
                    break
            if ignored:
                dirs.clear()
                continue

        for f in filenames:
            rel_f = (os.path.join(rel_dir, f) if rel_dir != "." else f).replace("\\", "/")
            ignored = False
            for pat in ignore_patterns:
                if pat.startswith("!"):
                    continue
                if fnmatch.fnmatch(rel_f, pat) or fnmatch.fnmatch(f, pat):
                    ignored = True
                    break
            if not ignored:
                all_files.append(rel_f)

    return all_files


def process_markdown_file(
    md_path: str, repo_root: str, existing_files: set[str], apply_changes: bool
) -> tuple[int, list[str]]:
    rel_md = os.path.relpath(md_path, repo_root)
    md_dir_rel = os.path.dirname(rel_md)

    with open(md_path, "r", encoding="utf-8") as fh:
        lines = fh.readlines()

    pattern = re.compile(r"`([^`\n]+)`")
    in_code_block = False
    new_lines = []
    changes_count = 0
    change_summaries = []

    for line_idx, line in enumerate(lines):
        if line.strip().startswith("```"):
            in_code_block = not in_code_block
            new_lines.append(line)
            continue
        if in_code_block:
            new_lines.append(line)
            continue

        tokens = list(pattern.finditer(line))
        reps = []
        for m in tokens:
            token = m.group(1).strip()
            start, end = m.span()

            if (
                start > 0
                and line[start - 1] == "["
                and end < len(line)
                and line[end : end + 2] == "]("
            ):
                continue
            if start >= 2 and line[start - 2 : start] == "](":
                continue
            left = line[:start]
            right = line[end:]
            if "[" in left and "](" in right:
                last_open = left.rfind("[")
                last_close = left.rfind("]")
                if last_open > last_close:
                    continue

            if token == "README.md" and "サブディレクトリ" in left:
                continue

            target_rel_to_repo = None
            if token in existing_files:
                target_rel_to_repo = token
            else:
                cand = os.path.normpath(os.path.join(md_dir_rel, token))
                if cand in existing_files:
                    target_rel_to_repo = cand

            if not target_rel_to_repo:
                continue

            target_abs = os.path.join(repo_root, target_rel_to_repo)
            if not os.path.isfile(target_abs):
                continue

            rel_link = os.path.relpath(target_abs, os.path.join(repo_root, md_dir_rel))
            new_text = f"[{token}]({rel_link})"
            reps.append((start, end, new_text, token, rel_link))

        if reps:
            changes_count += len(reps)
            cur_line = line
            for s, e, n_text, tok, r_link in sorted(reps, key=lambda x: -x[0]):
                cur_line = cur_line[:s] + n_text + cur_line[e:]
                change_summaries.append(f"{rel_md}:{line_idx + 1} `{tok}` -> {r_link}")
            new_lines.append(cur_line)
        else:
            new_lines.append(line)

    if apply_changes and changes_count > 0:
        with open(md_path, "w", encoding="utf-8") as fh:
            fh.writelines(new_lines)

    return changes_count, change_summaries


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert in-text file references to relative markdown links."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check only and exit with code 1 if unlinked file references exist.",
    )
    args = parser.parse_args()

    repo_root = get_repo_root()
    all_files = get_repo_files(repo_root)
    existing_files = set(all_files)
    md_files = [os.path.join(repo_root, f) for f in all_files if f.endswith(".md")]

    total_changes = 0
    all_summaries = []

    for md_path in sorted(md_files):
        cnt, summaries = process_markdown_file(
            md_path, repo_root, existing_files, apply_changes=not args.check
        )
        total_changes += cnt
        all_summaries.extend(summaries)

    if total_changes > 0:
        if args.check:
            print(
                f"Found {total_changes} unlinked file references in markdown documents:"
            )
            for s in all_summaries[:20]:
                print(f"  {s}")
            if len(all_summaries) > 20:
                print(f"  ... and {len(all_summaries) - 20} more.")
            print("\nRun 'python3 scripts/linkify-markdown.py' to convert them automatically.")
            return 1
        else:
            print(f"Successfully linked {total_changes} file references across markdown documents.")
            return 0
    else:
        print("All file references in markdown documents are properly linked.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
