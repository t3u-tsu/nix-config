---
name: ysh
description: Write, refactor, and execute modern YSH (Oils for Unix) scripts. Use when writing .ysh shell scripts, handling structured data (JSON/Dict/List) without external tools, replacing legacy Bash scripts, or working with proc, func, and block scoping in Oils.
license: 0BSD
compatibility: Requires oils-for-unix (bin/ysh)
metadata:
  version: "1.0.0"
  standard: "agentskills.io"
---

# YSH (Oils for Unix) Scripting Skill

## Overview
YSH is a modern Unix shell from the Oils project that eliminates common shell pitfalls by providing dynamic typing, Ruby-like block scopes, Python-like data structures, and native JSON handling without external utilities like `jq`.

---

## 1. Syntax Modes & Sigils

YSH strictly separates **Command Mode** (running processes) and **Expression Mode** (calculating data).

| Context | Example | Variable Lookup |
| :--- | :--- | :--- |
| **Command Mode** | `echo $name`, `ls @[files]` | Uses `$var` or `@[list]` |
| **Expression Mode** | `var total = x + y`, `if (port > 80)` | No `$`, uses direct variable names |
| **Environment Vars in Expressions** | `var home = ENV.HOME` | Must be accessed via `ENV` dict |

* `$[expr]`: Evaluates an expression and stringifies the result inside command mode.
* `@[list]`: Splices array elements as distinct shell words (prevents unintended word splitting).

---

## 2. Variables & Mutability

* **`const`**: Top-level immutable definitions.
* **`var`**: Typed variable definitions (`Int`, `Float`, `Str`, `Bool`, `Null`, `List`, `Dict`).
* **`setvar`**: Mutates local/function variables.
* **`setglobal`**: Mutates global variables from inside procedures.
* **`call`**: Executes expression statements discarding return values (e.g., calling methods).

```ysh
const APP_NAME = "my-service"

var count = 0
var tags = ["web", "db"]
var config = {
  host: "127.0.0.1",
  port: 8080
}

# Mutation
setvar count += 1
call tags->append("prod")
setvar config.port = 8443
```

---

## 3. Procedures (`proc`) vs Functions (`func`)

* **`func`**: Pure functions evaluated in **expression mode**. Returns values via `return (expr)`.
* **`proc`**: Command-like units evaluated in **command mode**. Exits with status codes.

### Signature Rules
* **`func`** arguments use Julia style: `(pos_args...; named_args...)`
* **`proc`** arguments have 4 sections separated by semicolons:
  `(word_args... ; typed_pos... ; typed_named... ; &block)`

```ysh
# Pure function
func add(a, b; factor=1) {
  return ((a + b) * factor)
}
var sum = add(10, 20; factor=2)

# Procedure: (word_params ; ; named_params)
proc deploy(env; ; dry_run=false) {
  echo "Deploying to: $env (dry_run: $dry_run)"
}

# Procedure Invocation
deploy "staging"
deploy "production" (dry_run=true)
```

---

## 4. Control Flow

Conditions in `if`, `while`, and `case` take parentheses `(...)` and support modern operators (`===`, `!==`, `<`, `>`, `and`, `or`, `not`).

```ysh
# if / else
if (config.port === 8443) {
  echo "Using secure port"
} else {
  echo "Using standard port"
}

# for loop (list and index)
for i, tag in (tags) {
  echo "[$i] tag: $tag"
}

# case pattern matching
case (config.port) {
  (80 | 8080)   { echo "HTTP" }
  (443 | 8443)  { echo "HTTPS" }
  else          { echo "Other" }
}
```

---

## 5. Ruby-like Blocks

Commands such as `cd` and `shvar` accept blocks `{ ... }`. Scope changes are automatically reverted when exiting the block.

```ysh
echo "Before: $PWD"
cd /tmp {
  echo "Inside: $PWD"
  # Directory is automatically restored when block ends
}
echo "After: $PWD"
```

---

## 6. Built-in JSON Support

YSH handles JSON natively without `jq`.

```ysh
var user = {
  id: 42,
  roles: ["admin"]
}

# 1. Output formatted JSON to stdout
json write (user)

# 2. Read from pipe (stored automatically in _reply)
echo '{"status": "ok", "retries": 3}' | json read
echo "Status: $[_reply.status]"
echo "Retries: $[_reply.retries]"

# 3. Read directly into a target variable reference (&var)
var res = null
json read (&res) <<< '{"version": "1.0"}'
echo "Version: $[res.version]"
```

---

## 7. Error Handling

YSH enables strict error checking by default (like `set -e`). To handle anticipated errors safely:

```ysh
try {
  # Command that may exit non-zero
  grep -q "nonexistent" /etc/hosts
}
if (_error.code !== 0) {
  echo "Pattern not found (exit code: $[_error.code])"
}
```

---

## 8. Anti-Patterns & Best Practices

| Anti-Pattern (Bash style) | YSH Idiom | Why |
| :--- | :--- | :--- |
| `[ "$a" = "$b" ]` or `[[ ... ]]` | `if (a === b)` | Native typed expressions prevent word splitting errors |
| `VAR=val` (no declaration) | `var x = val` / `setvar x = val` | Explicit scope and dynamic typing |
| `var path = $PWD` | `var path = ENV.PWD` | Environment variables live in the `ENV` namespace |
| `for item in $(ls)` | `for item in (glob("*.txt"))` | Prevents fragile word splitting |
| `echo $JSON \| jq .key` | `... \| json read; $[_reply.key]` | Native parsing is faster and dependency-free |
| `"$@"` | `@[argv]` or `@[list]` | Explicit list splicing syntax |
