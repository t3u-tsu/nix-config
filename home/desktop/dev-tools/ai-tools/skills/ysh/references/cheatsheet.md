# YSH Cheatsheet

Compact reference for Oils 0.37.0 (this repo) and 0.38.0 (oils.pub docs).
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

`List` has no `contains`; use `indexOf(x) >= 0`.

## Dict methods

| Method | Kind | Signature | Version |
| :--- | :--- | :--- | :--- |
| `erase` | `->` | `erase(key)`; idempotent | 0.37 |
| `clear` | `->` | `clear()` | 0.38+ |
| `append` | `->` | `append(key, value)`; appends to the list at `key` | 0.38+ |
| `inc` | `->` | `inc(key, n)`; missing key starts at 0 | 0.38+ |
| `update` | `->` | `update(other)`; right side wins | 0.38+ |

`++` concatenates Str and List on 0.37. `Dict ++ Dict` (a new Dict, neither
side mutated) is `[0.38+]`.

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
| `get` | `get(d, key, default=null)` | default only for a missing key |
| `join` | `join(list, sep='')` | positional separator; `sep=` is rejected |
| `maybe` | `maybe(s)` | `[]` if empty, `[s]` otherwise |
| `shSplit` | `shSplit(s)` | `$IFS` splitting; prefer `split()` |
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
| `vm.id` | `vm.id(v)` | identity for mutable values |

Stdlib functions require a `source`:

| Module | Functions |
| :--- | :--- |
| `$LIB_YSH/math.ysh` | `identity`, `abs`, `max`, `min`, `sum` |
| `$LIB_YSH/list.ysh` | `all`, `any`, `repeat` |
| `$LIB_YSH/args.ysh` | `parser`, `flag`, `arg`, `rest`, `parseArgs` |

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
| `boolstatus cmd { ... } else { ... }` | distinguish status 1 from real errors |
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
| `OILS_VERSION` | e.g. `0.37.0` |
| `LIB_YSH`, `LIB_OSH` | embedded stdlib prefixes |

`_status` is removed in 0.38; use `_error.code`.

## Version notes

| Feature | 0.37.0 | 0.38.0 |
| :--- | :--- | :--- |
| `Dict->append`, `Dict->inc`, `Dict->update`, `Dict->clear` | absent | present |
| `Dict ++ Dict` | absent | present |
| `_status` | present (deprecated) | removed |
| `Str.lines()` | present | present |
| `json8` | present | present |
| `parseArgs` | present | present |
| `===` on `Float` | runtime error for any pair | runtime error (docs say false) |
| `var x: Int` annotations | parsed, ignored | parsed, ignored |

Check the installed version with `ysh --version` before relying on a
version-dependent feature.
