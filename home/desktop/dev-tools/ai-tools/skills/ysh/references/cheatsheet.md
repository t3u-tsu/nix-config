# YSH Cheatsheet

Compact reference for Oils 0.38.0.
`->` marks a mutating method (call with `call x->m(...)`); `.` marks a
transforming method that returns a new value.

## Types

| Type | Literal | Notes |
| :--- | :--- | :--- |
| `Null` | `null` | uninitialized `var` is `null` |
| `Bool` | `true`, `false` | |
| `Int` | `42`, `0xff`, `0o755`, `0b1010`, `42_000` | 64-bit signed |
| `Float` | `3.14`, `-1.5e-100` | |
| `Str` | `'x'`, `"x $v"`, `u'x\n'`, `b'x\yff'`, `r'x\n'` | byte sequence, may be UTF-8 |
| `List` | `[1, 2]`, `:| one two \|` | ordered, mutable |
| `Dict` | `{k: 1, 'k2': 2}`, `{x, y}` | insertion-ordered |
| `Range` | `0 ..< 3`, `0 ..= 3` | iteration only |
| `Eggex` | `/ d+ /` | composable regex |
| `Command` | `^(echo hi)`, block arg | unevaluated command |
| `Expr` | `^[1 + 2]`, `^"x $v"`, `[expr]` | unevaluated expression |
| `Obj` | `Obj.new(fields, proto)` | prototype-based object |

## Str methods

| Method | Kind | Signature |
| :--- | :--- | :--- |
| `find` | `.` | `find(sub; start=0, end=-1)` → Int, `-1` if absent |
| `findLast` | `.` | `findLast(sub; start=0, end=-1)` |
| `contains` | `.` | `contains(sub)` → Bool |
| `replace` | `.` | `replace(old, new; count=-1)`; `old` may be Str or Eggex |
| `startsWith` | `.` | `startsWith(prefix)` → Bool (byte-based) |
| `endsWith` | `.` | `endsWith(suffix)` → Bool |
| `trim` | `.` | `trim()` or `trim(chars_or_eggex)` |
| `trimStart` | `.` | leading only |
| `trimEnd` | `.` | trailing only |
| `upper` | `.` | Unicode-aware |
| `lower` | `.` | Unicode-aware |
| `search` | `.` | `search(eggex; pos=0)` → Match or null (like `re.search`) |
| `leftMatch` | `.` | `leftMatch(eggex; pos=0)` → Match or null (like `re.match`) |
| `split` | `.` | `split(sep; count=-1)`; empty `sep` is an error |
| `lines` | `.` | `lines(eol=u'\n')` → List; `'a\nb\n'` has 2 lines |

Indexing and slicing are byte-based: `s[1]`, `s[-1]`, `s[1:-1]`, `s[2:]`.

## List methods

| Method | Kind | Signature |
| :--- | :--- | :--- |
| `append` | `->` | `append(x)` |
| `pop` | `->` | `pop()` → removed element |
| `extend` | `->` | `extend(other)` |
| `insert` | `->` | `insert(index, x)` |
| `remove` | `->` | `remove(x)`; returns null even if absent |
| `reverse` | `->` | `reverse()` |
| `clear` | `->` | `clear()` |
| `indexOf` | `.` | `indexOf(x)` → Int, `-1` if absent |
| `lastIndexOf` | `.` | `lastIndexOf(x)` |

`List` has no `contains` (`indexOf(x) >= 0`) and no `sort` (pipe `write -- @list | LC_ALL=C sort` into `@(...)`).

## Match methods

Returned by `s.search(eggex)` and `s.leftMatch(eggex)` (or `null` if no match).

| Method | Kind | Signature |
| :--- | :--- | :--- |
| `group` | `.` | `group(0)` (whole), `group(i)` (index), `group('name')` (named capture) |
| `start` | `.` | `start(i_or_name)` → Int byte offset |
| `end` | `.` | `end(i_or_name)` → Int byte offset |

For global `s ~ eggex` matches, use builtin functions `_group()`, `_start()`, `_end()` instead.

## Dict methods

| Method | Kind | Signature |
| :--- | :--- | :--- |
| `erase` | `->` | `erase(key)`; idempotent |
| `clear` | `->` | `clear()` |
| `append` | `->` | `append(key, value)`; appends to the list at `key` |
| `inc` | `->` | `inc(key, n)`; missing key starts at 0 |
| `update` | `->` | `update(other)`; right side wins |

`++` concatenates `Str`, `List`, and `Dict` (returns a new `Dict`, neither side mutated).

## Builtin functions

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `len` | `len(x)` | List entries, Dict pairs, Str bytes |
| `type` | `type(v)` | `'Int'`, `'Dict'`, ... |
| `bool` | `bool(v)` | false for `false 0 0.0 '' {} [] null` |
| `int` | `int(x)` | Float truncates toward zero; Str parsed base 10 |
| `float` | `float(x)` | |
| `str` | `str(x)` | Int/Float only; fails on List/Dict |
| `list` | `list(x)` | copy; Dict → keys; Range → values |
| `dict` | `dict(x)` | shallow copy |
| `keys` | `keys(d)` | insertion order |
| `values` | `values(d)` | insertion order |
| `get` | `get(d, key, default=null)` | default only for missing key (`d` must be `Dict`/`Obj`) |
| `join` | `join(list, sep='')` | positional separator; `sep=` is rejected |
| `maybe` | `maybe(s)` | `[]` if empty, `[s]` otherwise |
| `split` | `split(s)` | split on `$IFS` (or `s.split(sep)` for exact sep) |
| `shSplit` | `shSplit(s)` | collapse `$IFS` whitespace (use `s.split(sep)` for exact sep) |
| `strcmp` | `strcmp(a, b)` | `0`, `-1`, `1` |
| `floatsEqual` | `floatsEqual(a, b)` | both args must be `Float` |
| `first` | `first(obj)` | property Dict (shared storage) |
| `rest` | `rest(obj)` | prototype or null |
| `toJson` | `toJson(v; space=0, type_errors=true)` | compact by default |
| `fromJson` | `fromJson(s)` | |
| `toJson8` | `toJson8(v; space=0)` | binary-safe |
| `fromJson8` | `fromJson8(s)` | |
| `glob` | `glob(pat)` | List of paths |
| `eval` | `eval(cmd; to_dict=false)` | pure evaluation |
| `evalExpr` | `evalExpr(expr)` | pure expression eval |
| `getVar` | `getVar(name)` | null if undefined |
| `setVar` | `setVar(name, value; global=false)` | |
| `shvarGet` | `shvarGet(name)` | dynamic scope lookup |
| `parseCommand` | `parseCommand(s)` | → Command |
| `_group`, `_start`, `_end` | `_group(0)` / `_group('name')` | submatch from `~` operator (not `search()`) |
| `vm.id` | `vm.id(v)` | identity for mutable values |

Stdlib modules (prefer `use` when loading multiple modules, since stdlib defines `const __provide__`):

| Module | Functions |
| :--- | :--- |
| `$LIB_YSH/math.ysh` | `identity`, `abs`, `max`, `min`, `sum` |
| `$LIB_YSH/list.ysh` | `all`, `any`, `repeat` |
| `$LIB_YSH/args.ysh` | `parser`, `parseArgs` (block DSL: `flag`, `arg`, `rest`) |

`sum` is in `math.ysh` on both versions; check with
`ysh -c 'source $LIB_YSH/math.ysh; = __provide__'`.

## Builtin commands

| Command | Purpose |
| :--- | :--- |
| `write -- x y` | print words, one per line; `-n`, `--sep`, `--end`, `--` |
| `json write (x, space=2)` | serialize; `type_errors=false` turns bad types into null |
| `json read (&x)` | parse into a variable; default `_reply` |
| `json8 read` / `json8 write` | binary-safe J8 variants |
| `read --all (&x)` | whole input including trailing newline |
| `read --raw-line (&x)` | one line, trailing newline stripped |
| `read --num-bytes N (&x)` | N bytes |
| `read -0 VAR` | until NUL into a shell variable; `(&x)` is rejected |
| `try { ... }` | capture failure in `_error`, always status 0 |
| `failed` | `(_error.code !== 0)` |
| `error 'msg' (code=10, key=val)` | raise; named args become `_error` keys |
| `if boolstatus cmd { ... } else { ... }` | distinguish status 1 from real errors |
| `assert [expr]` | fail unless truthy; prints expected vs actual |
| `cd DIR { ... }` | scoped working directory |
| `shvar NAME=VAL { ... }` | scoped shell variable (not `ENV`) |
| `shopt --set/--unset OPT { ... }` | scoped shell options |
| `ctx push (dict) { ... }` | shared context; `ctx set`, `ctx emit` |
| `forkwait { ... }` | subshell replacement |
| `fork { ... }` | background; `wait -n` |
| `redir >out { ... }` | prefix redirect |
| `trap --add EXIT { ... }` | block trap; not a closure |
| `push-registers { ... }` | save `$?`, `_error`, pipeline status |
| `source FILE` | run in the current namespace |
| `use FILE --pick NAMES` | import a module namespace |
| `is-main` | 0 in the main file, 1 when sourced |
| `source-guard NAME` | 0 if new, 1 if already registered |
| `append WORDS (LIST)` | append words to a List |
| `pp (expr)` / `= expr` | pretty-print a value |
| `eval ARG` | exactly one string; `eval 'echo hi'` |

## Operators

| Operator | Meaning |
| :--- | :--- |
| `===`, `!==` | strict equality, no conversion |
| `~==` | string left operand converted to the right type |
| `is`, `is not` | identity |
| `in` | Dict key membership only |
| `~`, `!~` | regex/eggex search; quote a literal word (`/ 'pat' /`) |
| `~~`, `!~~` | glob match (always anchored) |
| `++` | concatenate `Str`, `List`; `Dict` is `[0.38+]` |
| `+ - * /` | arithmetic; `/` always Float |
| `//` | Int division |
| `%`, `**` | Int only, positive right operand |
| `and`, `or`, `not` | logical |
| `x if cond else y` | ternary |
| `->` | mutating method |
| `=>` | function chaining |
| `..<`, `..=` | half-open and closed ranges |

## Special variables

| Name | Meaning |
| :--- | :--- |
| `ARGV` | List of arguments; top level or open proc |
| `ENV` | environment `Obj`; `ENV.HOME`, `ENV.PATH` |
| `_reply` | default target of `read --all`, `json read` |
| `_error` | Dict set by `try`; `code`, sometimes `message` |
| `_pipeline_status` | List of Int statuses |
| `_this_dir` | directory of the current script |
| `$0`, `$1`, `$@`, `$?`, `$!` | POSIX specials still work |
| `PIPESTATUS` | internal `InternalStringArray`; only `@PIPESTATUS` works |
| `OILS_VERSION` | e.g. `0.38.0` |
| `LIB_YSH`, `LIB_OSH` | embedded stdlib prefixes |
| `io` | I/O object: `io.stdin`, `io.captureStdout(cmd)`, `io.captureAll(cmd)`, `io->eval(block)` |

## Runtime quirks (0.38.0)

- `errexit`, `pipefail`, and `inherit_errexit` are on by default.
- `===` / `!==` on `Float` is a runtime error (use `floatsEqual(float(a), float(b))`).
- `var x: Int` type annotations are parsed and ignored at runtime.
- `_status` is removed; use `_error.code`. `_error.message` may be absent (e.g. `json read` failures); use `get(_error, 'message', '')`.
- Unset an environment variable with `setglobal ENV.X = null` (`= ''` leaves an empty string; `unset ENV.X` fails).
- `exec` replaces the current process and cannot be caught by `try`.
- Upstream `toc-ysh.md` also lists unimplemented (`X`-marked) items such as
  `each-line`, `table`, `binascii`, and `${x %.3f}`—do not use them.

## Bash to YSH

| Bash | YSH |
| :--- | :--- |
| `x=foo` | `var x = 'foo'` |
| `x="$x more"` | `setvar x = x ++ ' more'` |
| `"$@"` / `"${arr[@]}"` | `@ARGV` / `@arr` |
| `$((1 + 2))` | `$[1 + 2]` |
| `[ "$a" = "$b" ]` | `if (a === b)` |
| `[ "$a" \< "$b" ]` | `if (strcmp(a, b) < 0)` |
| `[[ $x =~ $pat ]]` | `if (x ~ pat)` (quote literal: `~ 'pat'`) |
| `[[ $x == *.py ]]` | `if (x ~~ '*.py')` |
| `echo -n "$x"` / `printf '%s\n' "$x"` | `write -n -- $x` / `write -- $x` |
| `IFS= read -r line` | `read --raw-line (&line)` |
| `while read -r l; do ...; done` | `for l in (io.stdin) { ... }` |
| `read -d ''` / `$(cat file)` | `read --all (&x)` |
| `( cd /tmp; cmd )` | `cd /tmp { cmd }` |
| `{ cmd; } >out` | `redir >out { cmd }` |
| `cmd &` | `fork { cmd }` |
| `export FOO=bar` / `$EDITOR` | `setglobal ENV.FOO = 'bar'` / `$[ENV.EDITOR]` |
| `jq .key file` | `json read (&x) < file; $[x.key]` |
| `jq -Rs . < file` | `read --all (&s) < file; $[toJson(s)]` |
