#!/usr/bin/env python3
"""Validate relative markdown links and heading anchors.

Usage:
  python3 scripts/check-markdown-links.py [files...]
If no files are given, scans all markdown files across the repository respecting .gitignore.
"""

import fnmatch
import os
import re
import subprocess
import sys
import unicodedata
from urllib.parse import unquote

LINK_RE = re.compile(r"\[([^\]]*)\]\(\s*(<[^>]*>|[^)\s]+)(?:\s+(?:\"[^\"]*\"|'[^']*'|\([^)]*\)))?\s*\)")
ATX_HEADING_RE = re.compile(r"^ {0,3}(#{1,6})(?:[ \t]+(.*?))?\s*$")
SETEXT_UNDERLINE_RE = re.compile(r"^ {0,3}(=+|-+)[ \t]*$")
SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")


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


def blank_preserving_newlines(match: re.Match[str]) -> str:
    return re.sub(r"[^\n]", " ", match.group(0))


def strip_fenced_code(content: str) -> str:
    """Blank fenced blocks and HTML comments while keeping line numbers."""
    lines = content.split("\n")
    blanked: list[str] = []
    fence: tuple[str, int] | None = None

    for line in lines:
        stripped = line.lstrip(" ")
        indent = len(line) - len(stripped)
        fence_char = stripped[:1]

        if fence is not None:
            if indent <= 3 and fence_char == fence[0]:
                run = len(stripped) - len(stripped.lstrip(fence_char))
                if run >= fence[1] and stripped[run:].strip() == "":
                    fence = None
            blanked.append("")
            continue

        if indent <= 3 and (stripped.startswith("```") or stripped.startswith("~~~")):
            run = len(stripped) - len(stripped.lstrip(fence_char))
            if run >= 3:
                fence = (fence_char, run)
                blanked.append("")
                continue

        blanked.append(line)

    text = "\n".join(blanked)
    return re.sub(r"(?s)<!--.*?-->", blank_preserving_newlines, text)


def strip_markdown_code(content: str) -> str:
    """Blank fenced blocks, inline code, and HTML comments while keeping line numbers."""
    text = strip_fenced_code(content)
    return re.sub(r"(`+)([^\n]+?)\1", blank_preserving_newlines, text)


def heading_text(raw: str) -> str:
    """Reduce inline markdown in a heading to the text GitHub renders."""
    code_spans: list[str] = []

    def protect_code(match: re.Match[str]) -> str:
        code_spans.append(match.group(2))
        return f"\x00{len(code_spans) - 1}\x00"

    text = re.sub(r"(`+)(.+?)\1", protect_code, raw)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\\([\\`*_{}\[\]()#+\-.!>])", r"\1", text)
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"(?<![A-Za-z0-9])__([^_]+)__(?![A-Za-z0-9])", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"(?<![A-Za-z0-9])_([^_]+)_(?![A-Za-z0-9])", r"\1", text)
    text = re.sub(r"~~(.+?)~~", r"\1", text)
    for index, code in enumerate(code_spans):
        text = text.replace(f"\x00{index}\x00", code)
    return text


def slugify(raw: str) -> str:
    """Approximate GitHub's heading slug algorithm."""
    text = heading_text(raw).strip().lower()
    slug: list[str] = []
    for ch in text:
        if ch in "-_":
            slug.append(ch)
        elif ch.isspace():
            slug.append("-")
        elif unicodedata.category(ch)[0] in ("P", "S", "C"):
            continue
        else:
            slug.append(ch)
    return "".join(slug)


def strip_front_matter(lines: list[str]) -> list[str]:
    if len(lines) < 2 or lines[0].strip() != "---" or not re.match(
        r"^[A-Za-z0-9_-]+:", lines[1]
    ):
        return lines
    for end in range(1, len(lines)):
        if lines[end].strip() in ("---", "..."):
            return [""] * (end + 1) + lines[end + 1 :]
    return lines


def extract_headings(content: str) -> list[str]:
    lines = strip_front_matter(strip_fenced_code(content).split("\n"))
    headings: list[str] = []

    for index, line in enumerate(lines):
        match = ATX_HEADING_RE.match(line)
        if match:
            text = re.sub(r"[ \t]+#+[ \t]*$", "", match.group(2) or "")
            headings.append(text.strip())
            continue

        if index + 1 >= len(lines) or not line.strip():
            continue
        if len(line) - len(line.lstrip(" ")) > 3:
            continue
        if SETEXT_UNDERLINE_RE.match(lines[index + 1]) and not re.match(
            r"^ {0,3}([-*+>=~#|]|\d+[.)]\s)", line
        ):
            headings.append(line.strip())

    return headings


def heading_anchors(path: str, cache: dict[str, set[str]]) -> set[str]:
    if path not in cache:
        try:
            with open(path, "r", encoding="utf-8") as fh:
                content = fh.read()
        except (OSError, UnicodeDecodeError):
            cache[path] = set()
            return cache[path]

        seen: dict[str, int] = {}
        anchors: set[str] = set()
        for heading in extract_headings(content):
            base = slugify(heading)
            if not base:
                continue
            count = seen.get(base, 0)
            anchors.add(base if count == 0 else f"{base}-{count}")
            seen[base] = count + 1
        cache[path] = anchors
    return cache[path]


def check_file(md_path: str, repo_root: str, anchor_cache: dict[str, set[str]]) -> list[str]:
    errors: list[str] = []
    try:
        with open(md_path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except (OSError, UnicodeDecodeError) as e:
        return [f"{md_path}: failed to read file: {e}"]

    clean_content = strip_markdown_code(content)
    md_dir = os.path.dirname(md_path)
    rel_display = os.path.relpath(md_path, repo_root)

    for match in LINK_RE.finditer(clean_content):
        raw_target = match.group(2).strip()
        if raw_target.startswith("<") and raw_target.endswith(">"):
            raw_target = raw_target[1:-1]

        path_part, _, fragment = raw_target.partition("#")
        path_part = unquote(path_part.split("?", 1)[0])
        fragment = unquote(fragment)

        if SCHEME_RE.match(raw_target) or raw_target.startswith("//"):
            continue

        if not path_part:
            resolved = md_path
        elif path_part.startswith("/"):
            resolved = os.path.normpath(os.path.join(repo_root, path_part.lstrip("/")))
        else:
            resolved = os.path.normpath(os.path.join(md_dir, path_part))

        line_number = clean_content.count("\n", 0, match.start()) + 1
        location = f"{rel_display}:{line_number}"

        if not os.path.exists(resolved):
            errors.append(
                f"{location}: broken link -> '{raw_target}' (resolved: '{resolved}')"
            )
            continue

        if not fragment or not resolved.lower().endswith(".md"):
            continue

        if fragment not in heading_anchors(resolved, anchor_cache):
            target_display = os.path.relpath(resolved, repo_root)
            errors.append(
                f"{location}: broken anchor -> '#{fragment}' not found in '{target_display}'"
            )

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

    anchor_cache: dict[str, set[str]] = {}
    total_errors: list[str] = []
    for f in sorted(files_to_check):
        total_errors.extend(check_file(f, repo_root, anchor_cache))

    if total_errors:
        print(f"FAILED: Found {len(total_errors)} markdown link or anchor error(s):")
        for err in total_errors:
            print(f"  {err}")
        return 1

    print(
        f"PASSED: All relative links and anchors in {len(files_to_check)} markdown files are valid."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
