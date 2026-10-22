#!/usr/bin/env python3
"""Validate that all relative markdown links point to existing files or directories.

Usage:
  python3 scripts/check-markdown-links.py [files...]
If no files are given, scans all markdown files across the repository respecting .gitignore.
"""

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

    # Fallback: Read .gitignore patterns and walk
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


def check_file(md_path: str, repo_root: str) -> list[str]:
    errors = []
    try:
        with open(md_path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except Exception as e:
        return [f"{md_path}: failed to read file: {e}"]

    md_dir = os.path.dirname(md_path)
    for m in re.finditer(r"\[([^\]]+)\]\(([^)]+)\)", content):
        raw_target = m.group(2).strip()
        link = raw_target.split("#")[0].split("?")[0].strip()
        if not link or link.startswith(("http:", "https:", "mailto:", "ftp:")):
            continue

        if link.startswith("/"):
            resolved = os.path.normpath(os.path.join(repo_root, link.lstrip("/")))
        else:
            resolved = os.path.normpath(os.path.join(md_dir, link))

        if not os.path.exists(resolved):
            rel_display = os.path.relpath(md_path, repo_root)
            errors.append(f"{rel_display}: broken link -> '{raw_target}' (resolved: '{resolved}')")

    return errors


def main() -> int:
    repo_root = get_repo_root()
    files_to_check = sys.argv[1:]

    if not files_to_check:
        all_files = get_repo_files(repo_root)
        files_to_check = [os.path.join(repo_root, f) for f in all_files if f.endswith(".md")]
    else:
        files_to_check = [
            f if os.path.isabs(f) else os.path.abspath(f)
            for f in files_to_check
            if f.endswith(".md") and os.path.exists(f)
        ]

    total_errors = []
    for f in sorted(files_to_check):
        total_errors.extend(check_file(f, repo_root))

    if total_errors:
        print(f"FAILED: Found {len(total_errors)} broken markdown links:")
        for err in total_errors:
            print(f"  {err}")
        return 1

    print(f"PASSED: All relative links in {len(files_to_check)} markdown files are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
