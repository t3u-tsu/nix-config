---
name: ysh
description: Write, refactor, and execute modern YSH (Oils for Unix) scripts. Use when writing .ysh shell scripts, handling structured data (JSON/Dict/List) without external tools, replacing legacy Bash scripts, or working with proc, func, and block scoping in Oils.
license: 0BSD
compatibility: Requires oils-for-unix (bin/ysh)
metadata:
  version: "1.2.0"
  standard: "agentskills.io"
---

# YSH (Oils for Unix) Scripting Skill

## Overview
YSH is a modern Unix shell from the Oils project providing dynamic typing, Ruby-like block scopes, Python-like data structures, and native JSON handling without external utilities. Idioms verified against Oils 0.37.0.

---

## 1. Syntax Modes & Sigils

YSH strictly separates **Command Mode** (running processes) and **Expression Mode** (calculating data).

| Context | Example | Variable Lookup |
| :--- | :--- | :--- |
| **Command Mode** | `echo $name`, `ls @[files]` | `$var`, `@[list]`, `$[expr]` |
| **Expression Mode** | `var total = x + y`, `if (port > 80)` | Bare variable names |
| **Environment Vars** | `var home = ENV.HOME`, `var r = get(ENV, 'REGION', 'us-east-1')` | Access via `ENV` object (`get()` with fallback) |

* `$[expr]`: Evaluates an expression and stringifies the result into a shell word.
* `@[list]`: Splices array elements as distinct shell words (prevents unintended word splitting).

### Environment Variables & Fallbacks

Environment variables live in the `ENV` object (`Obj` type).
* Direct property access (`var home = ENV.HOME`) requires the variable to exist; accessing an unset variable triggers a fatal error (`Attribute 'KEY' not found on Obj`).
* `get(ENV, 'KEY', default_val)`: Built-in function to safely access an environment variable with a fallback default. Returns `default_val` only when the key is unset (missing on `Obj`). If the variable is set to an empty string (`export KEY=""`), `get()` returns `""`. For values that must not be empty (e.g. integer conversions like port or timeout), test `if (val !== '')` explicitly.

### String Interpolation & Quotes

* `$"${dir}/file"`: Interpolates variables/expressions into a double-quoted word.
  > **Note**: Property/dict access (e.g. `${ENV.HOME}`, `${node.attr}`) is **not supported** inside `$"..."`. Pre-bind to a local variable (`var home = ENV.HOME`) first.
* `u'\n'`: Explicit Unicode escape. Bare `'\n'` fails with `Ambiguous backslash (OILS-ERR-20)`.
* `r'C:\path'`: Raw string where backslashes remain literal.

```ysh
var home = ENV.HOME
var region = get(ENV, 'REGION', 'us-east-1')  # Idiomatic fallback if unset
var log_path = $"${home}/logs/app.log"        # Pre-bind before interpolating

var newline = u'\n'                           # Unicode escape
var winpath = r'C:\Users\me'                  # Raw string
```

---

## 2. Variables & Mutability

* `const`: Immutable top-level definition.
* `var`: Typed variable declaration (`Int`, `Float`, `Str`, `Bool`, `Null`, `List`, `Dict`).
* `setvar`: Mutates local/function variable (`setvar count += 1`).
* `setglobal`: Mutates global variable from inside a proc.
* `call`: Evaluates expression statement discarding return value.

### Method Calls: `->` (Mutating) vs `.` (Transforming)

* `->` (mutating): Changes receiver in place; requires `call` on mutable types (`List`, `Dict`).
* `.` (transforming): Read-only method returning a new value (`Str`, etc.). Receiver remains unchanged.

```ysh
var tags = ["web"]
call tags->append("db")         # Mutating (->)

var s = "Hello-World"
echo $[s.lower()]               # Transforming (.): "hello-world"
echo $[s.replace("-", "_")]     # Transforming (.): "Hello_World"
echo $[s.contains("World")]     # true ($s unchanged)
```

---

## 3. Procedures (`proc`) vs Functions (`func`)

| Feature | `proc` | `func` |
| :--- | :--- | :--- |
| **Mode** | Command Mode | Expression Mode only |
| **Returns** | Status code (0–255) | Typed value via `return (expr)` |
| **Invoked as** | `deploy staging (dry_run=true)` | `var x = add(1, 2; factor=3)` |
| **Signatures** | `(word... ; typed_pos... ; typed_named... ; &block)` | `(pos...; named...)` |

> **Caution**: A `func` is only callable in expression mode. In command position (e.g., `if is_valid x`), it fails with `Command not found`. Always write `if (is_valid(x))`.

```ysh
# Pure function
func add(a, b; factor=1) {
  return ((a + b) * factor)
}
var sum = add(10, 20; factor=2)

# Procedure
proc deploy(env; ; dry_run=false) {
  echo "Deploying to: $env (dry_run: $dry_run)"
}
deploy "production" (dry_run=true)
```

---

## 4. Control Flow

Conditions in `if`, `while`, and `case` take parentheses `(...)` and use modern operators (`===`, `!==`, `<`, `>`, `and`, `or`, `not`).

```ysh
if (config.port === 8443) {
  echo "Secure"
} else {
  echo "Standard"
}

for i, tag in (tags) {
  echo "[$i] tag: $tag"
}

case (config.port) {
  (80 | 8080)   { echo "HTTP" }
  (443 | 8443)  { echo "HTTPS" }
  (else)        { echo "Other" }
}
```

---

## 5. Blocks, Scoping & Traps

Ruby-like blocks `{ ... }` automatically revert scoped state on exit.

* `cd /dir { ... }`: Directory scope. Wrapping directory-dependent operations inside a block guarantees RAII-style restoration of the working directory upon exit (even on errors or caught failures), replacing fragile `(cd ... && ...)` subshells or manual `cd -`.
  > **Note**: Inside the block, `$PWD` and `$(pwd)` reflect the target directory; `ENV.PWD` remains stale.
* `shvar VAR=val { ... }`: Scoped environment/shell variable override.
* `trap --add SIG { ... }`: YSH uses block syntax for signal traps. String commands (e.g. `trap '...' EXIT`) are invalid.

```ysh
# Scoped directory execution with RAII restoration
cd /tmp {
  echo "Inside PWD: $PWD"       # /tmp
  # All directory-dependent operations run here; PWD is restored on exit
}
echo "Outside PWD: $PWD"        # Restored

# Exit cleanup trap (block syntax only)
trap --add EXIT {
  rm -f /tmp/lockfile
}
```

---

## 6. Built-in JSON & Stream I/O

YSH parses and serializes JSON natively without `jq`.

```ysh
var user = {id: 42, roles: ["admin"]}

# Write JSON
json write (user)

# Read JSON from pipeline into _reply
echo '{"status": "ok", "code": 200}' | json read
echo "Status: $[_reply.status]"

# Read directly into target variable reference (&var)
var res = null
json read (&res) <<< '{"version": "1.0"}'

# Read entire file into string without subshells (subprocess-free $(cat ...) / jq -Rs replacement)
var text = ""
read --all (&text) < path/to/file.txt
setvar text = text.trim()                     # Preferred $(cat file) replacement, strips trailing newlines
var json_str = $(json write (text))
```

---

## 7. Error Handling

YSH enables strict error checking (`errexit`) by default.

* `try { ... }`: Executes block without aborting; records result in `_error`.
* `if failed { ... }`: Idiomatic check for non-zero exit (`_error.code !== 0`).
* Suppress `errexit` stderr noise for caught failures:
  ```ysh
  shopt --unset verbose_errexit {
    try { grep -q "pattern" /etc/hosts }
  }
  if failed { echo "Pattern not found" }
  ```
* **Environment Variable Access vs. Strict Existence Checks**:
  `ENV` is an `Obj`, not a `Dict` (the `in` operator is unsupported, and direct missing property access triggers an error).
  * **Reading with default fallback (idiomatic)**: Use the built-in function `get(ENV, 'KEY', default_val)` directly without `try`:
    ```ysh
    var region = get(ENV, 'REGION', 'us-east-1')
    ```
  * **Strict existence check (no default)**: Contrast with `try`, which is only needed when strictly checking key existence without providing a default value:
    ```ysh
    try { var _ = ENV.API_KEY }
    if failed { echo "API_KEY not set" }
    ```

---

## 8. Anti-Patterns & Best Practices

| Anti-Pattern (Bash style) | YSH Idiom | Why |
| :--- | :--- | :--- |
| `[ "$a" = "$b" ]` or `[[ ... ]]` | `if (a === b)` | Native typed expressions prevent word splitting errors |
| `VAR=val` (implicit global) | `var x = val` / `setvar x = val` | Explicit scope and dynamic typing |
| `$"${node.attr}"` | `var a = node.attr; $"${a}"` | Nested property/dict access unsupported in string interpolation |
| `FOO="${FOO-default}"` | `var foo = get(ENV, 'FOO', 'default')` | `get()` corresponds to unset fallback (`${FOO-default}`, not set-but-empty `${FOO:-default}`) on `Obj` without fatal missing-key errors |
| `if ("KEY" in ENV)` | `try { var _ = ENV.KEY } / if failed` | `ENV` is an `Obj` (`in` unsupported); only use `try` when strictly checking presence without a default |
| `trap 'rm ...' EXIT` | `trap --add EXIT { rm ... }` | YSH requires block syntax; string commands are invalid |
| `var path = $PWD` | `var path = ENV.PWD` | Environment variables live in `ENV` object (or `$PWD` after `cd`) |
| `(cd /dir && cmd)` or `cd /dir; cmd; cd -` | `cd /dir { cmd }` | Block scoping guarantees RAII-style restoration of working directory |
| `for item in $(ls)` | `for item in (glob("*.txt"))` | Prevents fragile word splitting |
| `echo $JSON \| jq .key` | `... \| json read; $[_reply.key]` | Native parsing is faster and dependency-free |
| `jq -Rs . < file` | `read --all (&text); $(json write (text))` | Whole-file JSON encoding without `jq` |
| `$(cat file)` | `read --all (&text) < file; setvar text = text.trim()` | Subprocess-free, avoids subshell overhead, and strips trailing newlines cleanly |
| `"$@"` | `@[ARGV]` or `@[list]` | Explicit list splicing; built-in CLI args list is uppercase `ARGV` |
