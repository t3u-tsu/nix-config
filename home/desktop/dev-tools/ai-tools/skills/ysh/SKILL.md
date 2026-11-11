---
name: ysh
description: Use this skill when writing, reviewing, or debugging YSH (Oils for Unix) scripts (.ysh), including converting Bash or jq snippets to YSH, parsing or emitting JSON in a shell script, handling typed data (List/Dict/Range), defining proc/func with block arguments, and using try/failed error handling. Also use for json read/write, parseArgs, and YSH block forms such as cd DIR { ... }, forkwait, shvar, and trap --add.
license: 0BSD
compatibility: Requires oils-for-unix (ysh). This repo pins Oils 0.37.0 through nixos-26.05; oils.pub documents 0.38.0.
metadata:
  version: "2.0.0"
  upstream-docs: "https://oils.pub/release/latest/doc/ref/chap-index.html"
---

# YSH (Oils for Unix)

YSH is a shell with Python-like expressions and typed data. It is not Bash with
extras: the parser has two modes, quoting rules differ, and many Bash idioms are
parse errors.

Version: this repo's `ysh` is **0.37.0** (`nixos-26.05`). The docs at oils.pub
describe 0.38.0. Anything marked `[0.38+]` does not exist locally. Run
`ysh --version` before trusting a version-dependent feature.

## 1. Two modes and the sigils

| Context | Example | Variable syntax |
| :--- | :--- | :--- |
| Command mode | `echo $name`, `write -- @files` | `$name`, `@list` |
| Expression mode | `var x = name ++ '!'`, `if (n > 0)` | bare `name` |

| Sigil | Meaning |
| :--- | :--- |
| `$name` | one word: the value of a variable |
| `@name` | splice a `List` into separate words |
| `$[expr]` | evaluate an expression and stringify it into one word |
| `@[expr]` | splice a `List` expression into separate words |
| `$(cmd)` | command substitution; trailing newlines removed |
| `@(cmd)` | command substitution split into a `List` (J8 Lines) |
| `^()`, `^[]`, `^""` | unevaluated `Command`, `Expr`, string template |
| `:\| a b \|` | `List` literal built from words |

Four rules cover most failures:

- In expression mode never write `$`: `var x = $name` is a parse error. Write
  `var x = name`.
- `$(...)` is a command sub, not an expression. `$(get(ENV, 'X'))` fails; use
  `$[get(ENV, 'X')]`.
- There is no word splitting, empty elision, or dynamic globbing. `$x` is always
  exactly one argument. Opt in explicitly with `@[split(s)]`, `@[glob(p)]`,
  `@[maybe(s)]`.
- `==` and `!=` are parse errors. Use `===` (strict) or `~==` (string-to-type).

## 2. Gotchas

These are verified against 0.37.0 and are the mistakes agents make most often.

- `$(cmd)` is a command sub; `$[expr]` is an expression. Mixing them is a parse
  error.
- `$name` in expression mode is a parse error; use `name`.
- `$FOO` never reads the environment; use `ENV.FOO`. `export` is disabled.
- `$d.key` is not attribute access: it is `$d` followed by the literal `.key`
  (silently wrong for a `Str`). Use `$[d.key]`.
- `$"${obj.attr}"` is a parse error; bind the value first.
- `'\n'` is a parse error; use `u'\n'` or `r'\n'`.
- `==` / `!=` are parse errors; use `===` / `~==`.
- `===` and `!==` are undefined on `Float`, even for `3.0 === 3.0`. Use
  `floatsEqual(float(a), float(b))` or compare `int(a) === int(b)`.
- `case (x) { (1 | 2) }` is bitwise OR; use `(1) | (2)` or word patterns.
- In an eggex, a bare word is a character class: `/pat/` fails with `'pat' isn't
  a character class`. Quote it (`/ 'pat' /`) or use a POSIX ERE string (`'pat'`).
- `proc p(&block)` is a parse error; use `proc p(; ; ; block)`.
- `$block` fails with `Can't substitute into word, got Command`; use
  `call io->eval(block)`.
- A hyphenated proc name cannot be called in expression mode: `load-fleet(x)`
  parses as `load - fleet`. Call it as a command, or use a `func`.
- `local` / `declare` abort even inside `try` (`no_osh_builtins`); `export`
  fails with a hint.
- `var x: Int = 'a'` is accepted; annotations are not checked.
- `str([1])` and `str({a: 1})` fail; use `toJson8()`, `json write`, or `=`.
- `$?` is a `Str` in expression mode, so `if ($? !== 0)` is always true. Compare
  with `'0'`, or use `_error.code`.
- `return ((a + b) * factor)` and `if ((x + 1) < n)` are parse errors because
  `((` starts an arithmetic command. Add a space: `return ( (a + b) * factor )`.
- `$PWD` is undefined until the first `cd`; `ENV.PWD` is never updated by `cd`,
  so it is stale inside and after a `cd` block.
- `try cmd` without braces is rejected despite the docs; always use
  `try { cmd }`.
- `read -0 (&x)` is rejected despite the docs; use `read -0 x` or
  `read --all` plus `split(b'\y00')`.
- `echo` has no `-e`/`-n` under `simple_echo`; use `write -n --` or
  `write --end '' --`.
- A block must contain at least one command; `{ }` is a parse error.
- `forkwait` replaces `( ... )`; `fork` replaces `&`.
- `eval` takes exactly one string argument in YSH: `eval 'echo hi'`.
- `PIPESTATUS` is an internal `InternalStringArray`: only `@PIPESTATUS` works.
  It cannot be subscripted, `len()`-ed, or iterated. Use `_pipeline_status`
  (a `List` of `Int`) for those.
- `_status` is removed in 0.38; use `_error.code`.
- `shvar` sets a shell variable only. It does not update `ENV` or child
  processes; use a prefix binding (`TMPDIR=$tmp cmd`) for those.

## 3. Variables and scope

```ysh
const BASE = '/srv/app'        # top level only, immutable
var count = 0                  # dynamic type; annotations are ignored
var host, port                 # both null
setvar count += 1              # mutate a local (or top-level) variable
setglobal READY = true         # mutate a global from inside a proc/func
```

- `const` cannot appear inside `proc` or `func` (parse error).
- `local` and `declare` are fatal; `export` is disabled. Use
  `setglobal ENV.FOO = 'bar'`.
- Environment variables live on `ENV`, never as `$FOO`:

```ysh
var home = ENV.HOME
var region = get(ENV, 'REGION', 'us-east-1')   # default only when unset
try { var _ = ENV.API_KEY }
if failed { echo 'API_KEY not set' }
```

`get()` returns the default only for a missing key; an exported empty string
still yields `''`.

## 4. Strings

```ysh
var name = 'bob'
echo "hello $name"                 # plain double quotes interpolate
echo $"hello ${name}"              # $"" is the explicit form
echo $[name.upper()]               # method call in expression mode
var raw = r'C:\path'               # raw: backslashes literal
var nl = u'line\n'                 # J8 escapes: \n, \u{3bc}
var bytes = b'raw \yff'            # J8 with byte escapes
var block = """
    hello $name
    """
```

- Bare `'\n'` is a parse error: `Ambiguous backslash (OILS-ERR-20)`. Prefix with
  `r` (literal) or `u`/`b` (escapes).
- `${...}` inside a quoted string accepts a variable name only. Property access
  such as `$"${ENV.HOME}"` is a parse error; bind it first.
- `$[expr]` cannot stringify `Dict` or `List`. Use `$[toJson8(x)]`,
  `$(json write (x))`, or `= x` for debugging.

## 5. Data: List, Dict, Range

```ysh
var tags = ['web', 'db']
call tags->append('cache')         # -> mutates; requires call
call tags->extend(['api'])
var upper = tags[0].upper()        # . transforms, returns a new value
var merged = tags ++ ['extra']     # ++ concatenates Str and List
var cfg = {name: 'app', port: 8080}
setvar cfg.port = 9090             # d.key is d['key']
var port = get(cfg, 'port', 80)
var cfg_keys = keys(cfg)
for i, tag in (tags) { echo "$i $tag" }
for i in (0 ..< 3) { echo $i }     # half-open range; ..= is closed
```

- `->` methods mutate and need `call`; `.` methods return a value.
- `in` works only on `Dict` (`if ('k' in cfg)`), not on `Str` or `List`.
- `List` has `indexOf`, not `contains`; `Str` has `contains`.
- `1 / 2` is `Float` (`0.5`); `1 // 2` is `Int` (`0`). `%` and `**` require
  `Int` operands. Arithmetic coerces numeric strings, so `10 + '1'` is `11`.
- `Dict ++ Dict` and `Dict->clear` are `[0.38+]`.

## 6. proc and func

`proc` is shell-like (argv, status, I/O). `func` is pure and returns a value.
Both are closures with lexical scope.

```ysh
proc deploy(env; ; dry_run=false) {      # word params; typed pos; named
  echo "deploy $env dry_run=$dry_run"
}
deploy production (dry_run=true)

func add(a, b; factor=1) {
  var result = (a + b) * factor
  return (result)                        # parens are required
}
var sum = add(1, 2; factor=3)
```

The full proc signature has four sections:

```ysh
proc p(w1, ...rest_words; t1, ...rest_typed; n1=1, ...rest_named; block) {
  call io->eval(block)                   # run the block argument
}
p arg1 (1, 2; n1=3) { echo hi }
```

- The block parameter is named `block`, in the fourth section. `&block` is old
  syntax and a parse error. Invoke it with `call io->eval(block)`.
- `func` cannot be called in command position: `if isValid x` fails with
  `Command not found`. Write `if (isValid(x))`.
- A hyphenated `proc` name is not an expression identifier; call it as a
  command (`load-fleet $path`) or write a `func`.
- Out parameters use a `Place`: `proc p(; out) { call out->setValue(42) }` then
  `p (&x)`.
- An open proc (`proc p { ... }`) sees its arguments in `ARGV`; a closed proc
  (`proc p (x) { ... }`) has an empty `ARGV`.
- Naming: procs are `kebab-case`, funcs are `camelCase`, locals `snake_case`.

## 7. Control flow

Conditions take parentheses and use expression operators.

```ysh
if (port === 8443) {
  echo 'secure'
} elif (port === 80) {
  echo 'http'
} else {
  echo 'other'
}

while (i < 10) { setvar i += 1 }
until (i >= 10) { setvar i += 1 }

for i, name in src/*.py { echo "$i $name" }        # word list
for item in (list) { echo $item }                  # typed data
for key, value in (dict) { echo "$key $value" }    # Dict: key, value
for i, key, value in (dict) { echo "$i $key $value" }
for line in (io.stdin) { echo $line }              # buffered lines
```

`break` and `continue` work inside loops and are keywords, not commands.

`case` has two pattern styles. Word patterns are globs and support `|`:

```ysh
case (filename) {
  *.py | *.pyi  { echo 'python' }
  *             { echo 'other' }
}
```

Typed patterns go in parentheses. `(80 | 8080)` is **bitwise OR**, not
alternation; write `(80) | (8080)`:

```ysh
case (port) {
  (80) | (8080) { echo 'http' }
  (else)        { echo 'other' }
}
```

## 8. Blocks

Blocks are the YSH replacement for subshells and manual save/restore.

```ysh
cd /tmp { echo $PWD }              # cwd restored on exit; ENV.PWD stays stale
shvar IFS=/ { echo $IFS }          # scoped shell variable, restored
redir >out.txt { echo 1; echo 2 }  # prefix redirect
forkwait { cd /tmp; rm -f x }      # subshell replacement
fork { sleep 1 }                   # background; wait -n to collect
trap --add EXIT { rm -f $lock }    # block syntax; not a closure
ctx push (spec) { ctx set (k='v') } # shared, nestable context
```

`try` and `shopt` also take blocks:

```ysh
try { grep -q pattern /etc/hosts }
if failed { echo "not found: $[_error.code]" }

shopt --unset verbose_errexit {    # silence the errexit message
  try { grep -q pattern /etc/hosts }
}
```

For a child process environment, use a prefix binding; `shvar` does not reach
the environment:

```ysh
TMPDIR=$tmp run-build
```

## 9. Error handling

`errexit` is on by default. `try` runs a block, stores the result in `_error`,
and always returns status 0.

```ysh
try { cp src /bad/dest }
if failed { echo "failed with $[_error.code]" }

var path = '/etc/app.toml'
try { error 'missing config' (path=path) }
echo $[_error.code]        # 10 by default
echo $[_error.path]        # named args become _error keys
```

- `_error` is a `Dict` with `code`. `message` is set by the `error` builtin and
  by `fromJson`/`fromJson8`; `json read`/`json8 read` set only `code` and print
  the diagnostic to stderr.
- `failed` is exactly `(_error.code !== 0)`.
- Do not re-raise with `return`; `exit $[_error.code]` or `error` with a code.
- `boolstatus cmd { ... } else { ... }` distinguishes exit 1 (false) from real
  errors.
- `if myFunc` is rejected by `strict_errexit`; use `try { myFunc }`.

## 10. JSON, J8, and file I/O

```ysh
var cfg = {name: 'app', tags: ['web']}
json write (cfg)                   # pretty by default (space=2)
json write (cfg, space=0)          # compact
json write (cfg) >out.json

json read < cfg.json               # into _reply
echo $[_reply.name]
var cfg2 = null
json read (&cfg2) < cfg.json       # into a named variable

var text = ''
read --all (&text) < file.txt      # keeps the trailing newline
setvar text = text.trim()
write --end '' -- $text > copy.txt # exact bytes
```

- `json read` fails with status 1 and prints a diagnostic; `try` captures the
  status but not the message.
- `json8 read` / `json8 write` are the binary-safe variants.
- `read --raw-line (&line)` reads one line (unbuffered); `for line in (io.stdin)`
  is the fast buffered form.
- `toJson8(x)` / `fromJson8(s)` are the function forms; `toJson()` defaults to
  `space=0`.
- `$(cmd)` drops every NUL byte, including interior ones; use `read --all` for
  binary data.

## 11. Modules and CLI arguments

```ysh
source $_this_dir/lib/common.ysh   # run in the current namespace
use $_this_dir/lib/module.ysh      # namespace Obj; see below
use $_this_dir/lib/module.ysh --pick my-proc

if is-main { runproc @ARGV }       # 0 in the main file, 1 when sourced
source-guard mylib || return 0     # include guard (in a sourced library)
```

A module namespace is an invokable `Obj`. Call procs as `module my-proc` and
read data as `module.MY_VALUE`; hyphens break attribute access.

`use` requires the module to declare its exports; otherwise it fails with
`Module is missing __provide__ List`:

```ysh
var __provide__ = ['my-proc', 'MY_VALUE']
```

Argument parsing uses the stdlib parser. A full example is in
[patterns.md](references/patterns.md) under "Parse arguments".

```ysh
source $LIB_YSH/args.ysh
var spec = {}
parser (&spec) { arg path; rest files }
var args = parseArgs(spec, ARGV)
```

`parseArgs` raises on invalid input. `--` stops flag processing and fills
`rest`; required `arg` values must appear before `--`.

## 12. Bash to YSH

| Bash | YSH |
| :--- | :--- |
| `x=foo` | `var x = 'foo'` |
| `x="$x more"` | `setvar x = x ++ ' more'` |
| `"$@"` | `@ARGV` |
| `"${arr[@]}"` | `@arr` |
| `$(cmd)` | `$(cmd)` (one word) |
| `$((1 + 2))` | `$[1 + 2]` |
| `[ "$a" = "$b" ]` | `if (a === b)` |
| `[[ $x =~ $pat ]]` | `if (x ~ pat)` (quote a literal: `~ 'pat'`) |
| `[[ $x == *.py ]]` | `if (x ~~ '*.py')` |
| `echo "$x"` | `write -- $x` |
| `echo -n "$x"` | `write -n -- $x` |
| `printf '%s\n' "$x"` | `write -- $x` |
| `IFS= read -r line` | `read --raw-line (&line)` |
| `while read -r l; do ...; done` | `for l in (io.stdin) { ... }` |
| `read -d ''` | `read --all (&x)` |
| `( cd /tmp; cmd )` | `cd /tmp { cmd }` |
| `{ cmd; } >out` | `redir >out { cmd }` |
| `cmd &` | `fork { cmd }` |
| `set -e` | default (`errexit`) |
| `set +e; cmd; set -e` | `shopt --unset errexit { cmd }` |
| `export FOO=bar` | `setglobal ENV.FOO = 'bar'` |
| `$EDITOR` | `$[ENV.EDITOR]` |
| `jq .key file` | `json read (&x) < file; $[x.key]` |
| `jq -Rs . < file` | `read --all (&s) < file; $[toJson(s)]` |
| `$(cat file)` | `read --all (&s) < file` |

## 13. Writing, checking, and debugging

1. Start from the skeleton in [patterns.md](references/patterns.md) under
   "Script skeleton". Use `#!/usr/bin/env ysh` and the `.ysh` extension.
2. Check syntax: `ysh -n file.ysh >/dev/null`. This prints the AST on success,
   and it does not catch runtime errors such as a missing block argument.
3. Run it: `ysh file.ysh args`. `ysh -c 'echo hi'` handles one-liners.
4. Debug with `= expr` or `pp (expr)`, then inspect `_error.code` and
   `_error.message`. Wrap expected failures in
   `shopt --unset verbose_errexit { try { ... } }`.
5. The pre-commit hook `ysh-check` runs `ysh -n` on every `.ysh` file. Its AST
   output is normal, not a failure.
6. After an Oils upgrade, run `ysh scripts/verify.ysh` (in this skill) to catch
   drift between the docs and the installed version.

If `ysh` is missing, `nix shell nixpkgs#oils-for-unix` may resolve to 0.38 or
later; re-check `ysh --version` before relying on the version notes.

To embed a script in Nix, use the repo's `pkgs.writeYshApplication` (defined in
`flake/overlays.nix`). It adds the shebang, prepends `runtimeInputs` to `PATH`,
and runs `ysh -n` as `checkPhase`:

```nix
pkgs.writeYshApplication {
  name = "my-tool";
  runtimeInputs = [ pkgs.curl ];
  text = ''
    var body = ""
    read --all (&body) < /etc/my-tool/input
    write --end "" -- $body
  '';
}
```

## References

- [references/cheatsheet.md](references/cheatsheet.md): read when you need an
  exact method signature, a builtin flag, an operator, or a special variable.
  Do not read it end to end.
- [references/patterns.md](references/patterns.md): read when writing a whole
  script (argument parsing, JSON config, subprocess capture, modules, tests).
- `scripts/verify.ysh`: run after an Oils upgrade or when this skill disagrees
  with the installed `ysh`.
- Upstream reference: <https://oils.pub/release/latest/doc/ref/chap-index.html>
  (0.38.0; check `ysh --version` first).
