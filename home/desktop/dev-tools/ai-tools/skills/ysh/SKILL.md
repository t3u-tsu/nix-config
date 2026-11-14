---
name: ysh
description: Use this skill when writing, reviewing, or debugging YSH (Oils for Unix) scripts (.ysh), including converting Bash or jq snippets to YSH, parsing or emitting JSON in a shell script, handling typed data (List/Dict/Range), defining proc/func with block arguments, and using try/failed error handling. Also use for json read/write, parseArgs, and YSH block forms such as cd DIR { ... }, forkwait, shvar, and trap --add.
license: 0BSD
compatibility: Requires oils-for-unix (ysh >= 0.38.0).
metadata:
  version: "2.2.0"
  upstream-docs: "https://oils.pub/release/latest/doc/ref/chap-index.html"
---

# YSH (Oils for Unix)

YSH is a shell with Python-like expressions and typed data. It is not Bash with
extras: the parser has two modes, quoting rules differ, and many Bash/Python
idioms fail.

Target version: **Oils 0.38.0** (matching `oils.pub` and this repo's overlay).
Run `ysh --version` if running outside this repo's devshell.

## 1. Two modes and sigils

| Context | Example | Variable syntax |
| :--- | :--- | :--- |
| Command mode | `echo $name`, `write -- @files` | `$name`, `@list` |
| Expression mode | `var x = name ++ '!'`, `if (n > 0)` | bare `name` |

| Sigil | Meaning |
| :--- | :--- |
| `$name` / `@name` | one word / splice `List` into separate words |
| `$[expr]` / `@[expr]` | eval expression to one word / splice `List` expr |
| `$(cmd)` / `@(cmd)` | command sub (strips trailing `\n`, drops NULs) / split lines to `List` |
| `^()`, `^[]`, `^""` | unevaluated `Command`, `Expr`, template |
| `:\| a b \|` | `List` literal from words |

Four rules prevent most failures:
- Never write `$` in expression mode (`var x = $name` fails; use `var x = name`).
- `$(...)` is command sub, not expression (`$(get(ENV, 'X'))` fails; use `$[get(ENV, 'X')]`).
- No word splitting, empty elision, or dynamic globbing: `$x` is always 1 arg. Opt in with `@[split(s)]`, `@[glob(p)]`, `@[maybe(s)]`.
- `==` and `!=` are parse errors. Use `===` (strict) or `~==` (string-to-type).

## 2. Gotchas (verified on 0.38.0)

| Trap (fails or wrong) | YSH idiom | Why |
| :--- | :--- | :--- |
| `if (b) { var x = 1 } else { var x = 2 }` | `var x = null; if (b) { setvar x = 1 } else { setvar x = 2 }` | Flat scope inside `proc`/`func` |
| `'a' < 'b'` or `call list->sort()` | `strcmp(a, b) < 0` / `@(write -- @list \| LC_ALL=C sort)` | `<` is numeric-only; `List` has no `sort()` |
| `'x' in s` / `'x' in list` / `s ++= 'a'` | `s.contains('x')` / `list.indexOf('x') >= 0` / `List->append` + `join()` | `in` is `Dict`-only; no `++=` on `Str` |
| `var p = ~/src` / `@[glob(*.py)]` | `"$HOME/src"` / `@[glob('*.py')]` | Expression mode does not expand `~` or bare globs |
| `$FOO` / `export FOO=1` / `shvar` for child | `ENV.FOO` / `get(ENV, 'FOO', 'd')` / `setglobal ENV.FOO = '1'` / `FOO=1 cmd` | `ENV` is separate; `shvar` is shell-only |
| `$d.key` / `$"${obj.attr}"` | `$[d.key]` or bind `var v = obj.attr; $"${v}"` | No nested attr access in words or `$"..."` |
| `'\n'` / `str([1])` / `3.0 === 3.0` | `u'\n'` or `r'\n'` / `toJson8(x)` / `floatsEqual(float(a), float(b))` | Ambiguous `\`; `str()` rejects containers; `===` rejects `Float` |
| `return ((a + b) * c)` / `(80 \| 8080)` | `return ( (a + b) * c )` / `(80) \| (8080)` | `((` starts bash arith; `\|` inside `(...)` is bitwise OR |
| `/pat/` / `/"a"/` / `/[a-zA-Z0-9._]/` / multiline `/ /` | `/ 'pat' /` / `/ [a-z A-Z 0-9 '._-'] /` (single-line) | Eggex requires single quotes, spaced ranges, `![...]` |
| `_group(1)` after `s.search(...)` | `m.group(1)` for `search()`/`leftMatch()`; `_group(1)` for `~` | `Match` and global `_group` do not mix |
| `if isValid x` / `load-fleet(x)` / `proc p(&b)` | `if (isValid(x))` / `load-fleet $x` / `proc p(; ; ; block)` + `call io->eval(block)` | `func` is expr-only; hyphenated names are cmd-only |
| `myproc (&out) \| grep foo` | Avoid `&out` on left of pipe | Left pipe stages run in subshells |
| `args.min_port` for `--min-port` | `args['min-port']` | `parseArgs` keeps hyphens in Dict keys |
| `local`/`declare`, `echo -n`, `try cmd`, `read -0 (&x)`, `{ }` | `var`, `write -n --`, `try { cmd }`, `read -0 x`, `{ true }` | Disabled OSH / parser rules; `_status` removed |
| `$PWD` before `cd` / `ENV.PWD` in `cd` block | Use `$PWD` inside `cd /dir { ... }` | `$PWD` needs first `cd`; `ENV.PWD` stays stale |

## 3. Core syntax & idioms

### Variables, scope & data
```ysh
const BASE = '/srv/app'                 # top level only
var count = 0                           # dynamic; type annotations are ignored
setvar count += 1
setglobal READY = true                  # mutate global from inside proc/func

var tags = ['web']
call tags->append('db')                 # -> mutates (requires call)
var lower = tags[0].lower()             # . transforms (returns new value)
var merged = tags ++ ['api']            # ++ joins Str, List, or Dict
var port = get(cfg, 'port', 8080)       # default only when key is missing
```

### `proc` and `func`
```ysh
proc deploy(env; ; dry_run=false; block) {   # words; typed_pos; named; block
  echo "deploy $env dry_run=$dry_run"
  call io->eval(block)
}
deploy prod (dry_run=true) { echo 'hook' }

func add(a, b; factor=1) {
  return ( (a + b) * factor )                # parens required; space after (
}
```
Open proc (`proc p { ... }`) sees only the arguments passed to `p` in `ARGV` (not top-level `ARGV`—pass `main @ARGV` or use `proc main(; argv)` + `main (ARGV)`). Closed proc (`proc p(x) { ... }`) has empty `ARGV`. Out-params use `Place`: `proc p(; out) { call out->setValue(42) }`, called as `p (&x)`.

### Control flow, blocks & errors
`errexit` is on by default. Wrap expected failures in `try { ... }` and check `if failed` (`_error.code !== 0`).
```ysh
shopt --unset verbose_errexit {
  try { grep -q 'pat' $file }
}
if failed { echo $"missing: $[_error.code]" >&2 }

cd /tmp { echo $PWD }                   # cwd restored on exit (replaces subshells)
forkwait { cd /tmp; rm -f x }           # explicit subshell
trap --add EXIT { rm -f $lock }         # block syntax only (not a closure)
```
Loops and `case`:
```ysh
for i, item in (items) { echo "$i $item" }
for k, v in (dict) { echo "$k=$v" }
for line in (io.stdin) { echo $line }   # buffered lines

case (port) {
  (80) | (8080) { echo 'http' }
  (else)        { echo 'other' }
}
```

### JSON, I/O & modules
```ysh
var cfg = null
try { json read (&cfg) < $path }        # or: cmd | json read -> _reply
json write (cfg, space=2) > $out_path

var text = ''
read --all (&text) < $file              # preserves trailing \n & NULs
write --end '' -- $text > $copy         # exact bytes

source $_this_dir/lib/common.ysh        # eval in current namespace
if is-main { main (ARGV) }
```
For `use` modules (namespaced `Obj`), the module must define `var __provide__ = [...]`.

## 4. Verification & Nix integration

1. Syntax check: `ysh -n file.ysh >/dev/null` (prints AST on success; does not catch runtime errors like missing block args or type errors).
2. Run: `ysh file.ysh args` or `ysh -c '...'`. Debug values with `= expr` or `pp (expr)`.
3. Pre-commit hook `ysh-check` runs `ysh -n` on all `.ysh` files.
4. After an Oils upgrade, run `ysh scripts/verify.ysh` in this skill directory to check doc/binary drift.
5. In Nix, embed scripts with `pkgs.writeYshApplication` (from `flake/overlays.nix`), which adds the shebang, prepends `runtimeInputs`, and runs `ysh -n` in `checkPhase`.

## References

Read these on demand rather than end-to-end:
- [references/cheatsheet.md](references/cheatsheet.md): exact signatures for types, `Str`/`List`/`Dict`/`Match` methods, builtins, operators, special vars, Bash-to-YSH table, and 0.37 vs 0.38 differences.
- [references/patterns.md](references/patterns.md): full recipes for script skeleton, `parseArgs`, JSON config, subprocess capture, regex extraction, sorting, modules, and tests.
- [scripts/verify.ysh](scripts/verify.ysh): runnable 0.37.0/0.38.0 verification suite.
