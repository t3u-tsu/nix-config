# YSH Patterns

Task-oriented recipes for Oils 0.38.0. See [cheatsheet.md](cheatsheet.md) for
signatures.

## Script skeleton

```ysh
#!/usr/bin/env ysh
#
# Apply the staging secrets to the target host.
#
# Usage:
#   ysh scripts/secrets/apply-staging.ysh [--dry-run]

source $_this_dir/lib/common.ysh

proc usage() {
  echo 'usage: ysh scripts/secrets/apply-staging.ysh [--dry-run]' >&2
}

proc main(; args) {
  if (len(args) > 0) {
    usage
    exit 2
  }
  echo 'ok'
}

if is-main { main (ARGV) }
```

`is-main` returns 0 in the entry file and 1 when the file is sourced, so the
same file works as a script and as a library.
If `main` is an open proc (`proc main { ... }`), pass `main @ARGV` (an open
proc's `ARGV` holds only the arguments passed to it, not the script's top-level
`ARGV`).

## Parse arguments

```ysh
source $LIB_YSH/args.ysh

var spec = {}
parser (&spec) {
  flag -n --dry-run (Bool, help='print actions only')
  flag -j --jobs (Int, default=1, help='parallel jobs')
  arg source (help='source directory')
  rest paths
}

var args = parseArgs(spec, ARGV)
echo $[args['dry-run']]    # hyphenated flags keep hyphens as Dict keys
echo $[args.jobs]
for p in (args.paths) { echo $p }
```

`parseArgs` raises on unknown flags or missing required args. Use `--` to pass
everything after it into `rest`. Hyphenated flag names are NOT converted to
underscores: access `--dry-run` as `args['dry-run']`, not `args.dry_run`.

## Read a JSON config

```ysh
var config_path = '/etc/my-tool/config.json'
var cfg = null
try { json read (&cfg) < $config_path }
if failed {
  echo $"cannot parse ${config_path}" >&2
  exit 1
}
if (type(cfg) !== 'Dict') {
  echo 'config must be a JSON object' >&2
  exit 1
}
var name = get(cfg, 'name', 'default')
var hosts = get(cfg, 'hosts', [])
```

`json read` writes to `_reply` when no place is given. It is valid at the end of
a pipeline because YSH enables `lastpipe`:

```ysh
var url = 'https://api.example.com/status'
curl -fsSL $url | json read
var status = get(_reply, 'status', 'unknown')
```

## Capture output and status

```ysh
var out = ''
try { setvar out = $(nix eval --raw --impure --expr '1 + 1') }
if failed {
  echo "nix eval failed with $[_error.code]" >&2
  exit 1
}
```

`$(cmd)` strips trailing newlines and every NUL byte, including interior ones.
To keep raw bytes, use `read --all` or `io.captureAll`:

```ysh
var url = 'https://api.example.com/status'
var cmd = ^(curl -fsSL $url)
var result = io.captureAll(cmd)
echo $[result.status]
echo $[result.stdout]
```

`io.captureAll` does not raise on a non-zero status; `io.captureStdout` raises
and strips the trailing newline.

## Check files and commands

```ysh
func fileExists(path) {
  try { test -f $path }
  return (_error.code === 0)
}

func commandExists(name) {
  try { command -v $name >/dev/null 2>&1 }
  return (_error.code === 0)
}

if (not commandExists('nix')) {
  echo 'nix is required' >&2
  exit 1
}
```

`test` accepts long flags: `test --file`, `test --dir`, `test --symlink`,
`test --exists`.

## Iterate lines

```ysh
for line in (io.stdin) {          # buffered, fastest
  echo $line
}
```

```ysh
var line = ''
while read --raw-line (&line) {   # unbuffered, needed for interactive input
  echo $line
}
```

Prefer `read --raw-line (&line)` over `read -r line` to avoid `$IFS` whitespace trimming and pass an explicit place.

## Write files exactly

```ysh
var src = '/etc/my-tool/input'
var dest = '/tmp/copy'
var text = ''
read --all (&text) < $src
write --end '' -- $text > $dest      # preserve bytes, no extra newline
```

```ysh
var lines = ['one', 'two']
write -- @lines > /tmp/lines.txt     # one line per element
```

`echo` has no `-n` or `-e` in YSH; use `write -n --` instead.

## Cleanup on exit

```ysh
var tmp = $(mktemp -d)
trap --add EXIT { rm -rf $tmp }
```

The trap block is not a closure, so keep the variable it needs in scope at the
top level. For scoped cleanup, prefer a block:

```ysh
cd $tmp {
  true   # cwd is restored even on failure
}
```

## Error handling

```ysh
try { cp $src $dest }
if failed {
  echo $"copy failed ($[_error.code]): $src -> $dest" >&2
  exit $[_error.code]
}
```

```ysh
try { grep -q 'pattern' $file }
case (_error.code) {
  (0)    { echo 'found' }
  (1)    { echo 'not found' }
  (else) { echo 'fatal' >&2; exit $[_error.code] }
}
```

Use `shopt --unset verbose_errexit { ... }` around an expected failure to keep
the shell from printing its own message.

```ysh
shopt --unset verbose_errexit {
  try { grep -q 'pattern' $file }
}
if failed { echo 'not found' }
```

## Environment and defaults

```ysh
var home = ENV.HOME
var region = get(ENV, 'REGION', 'us-east-1')
var debug = get(ENV, 'DEBUG', '') !== ''
```

`get()` returns the default only when the key is unset. An exported empty string
returns `''`, so test for emptiness when the value must be non-empty:

```ysh
var port = get(ENV, 'PORT', '')
if (port === '') { setvar port = '8080' }
var port_num = int(port)
```

To set an environment variable for later child processes:

```ysh
setglobal ENV.PYTHONPATH = '.'
```

## Modules

For shared code in this repo, `source` is the usual choice. It evaluates the
file in the current namespace:

```ysh
# lib/fleet.ysh
var FLEET = {}

proc load-fleet(path) {
  var raw = ''
  try { read --all (&raw) < $path }
  if failed { return 1 }
  var parsed = null
  try { json read (&parsed) <<< $raw }
  if failed { return 1 }
  setglobal FLEET = parsed
  return 0
}
```

```ysh
# main.ysh
source $_this_dir/lib/fleet.ysh
load-fleet $path
echo $[len(FLEET)]
```

`use` gives a namespace instead. It caches the module, must run at the top
level, and requires `__provide__`:

```ysh
var __provide__ = ['my-proc', 'MY_VALUE']
```

```ysh
use $_this_dir/lib/module.ysh
module my-proc
echo $[module.MY_VALUE]
```

Bindings are copied into the namespace, so `setglobal` inside the module does
not update `module.FLEET`. Mutate a shared object in place, or use `source`
when the module has mutable state. When loading multiple `$LIB_YSH/*` stdlib
modules in one scope, use `use` rather than `source` (stdlib modules define
`const __provide__`, which collides on a second `source`).

## Run a subprocess with a scoped environment

Use a prefix binding. The child sees the variable and the parent environment is
unchanged:

```ysh
var tmp = '/tmp/build'
TMPDIR=$tmp sh -c 'echo $TMPDIR'
```

`shvar` is for shell variables such as `IFS`; it does not update `ENV` or reach
child processes. `TMPDIR=$tmp { ... }` is a parse error.

## Logging

```ysh
proc log(msg) {
  echo $"[build] $msg" >&2
}
```

Use `>&2` for diagnostics and stdout for data that a caller may capture with
`$(...)`.

## Extract with Eggex

Use `s.search(...)` for `Match` objects (`m.group(...)`), or `~` for global
`_group(...)`:

```ysh
var line = 'host=api-1.local port=8443'
var pat = / 'host=' <capture [a-z A-Z 0-9 '._-']+ as host> ' port=' <capture d+ as port : int> /
var m = line.search(pat)
if (m !== null) {
  echo "$[m.group('host')] $[m.group('port')]"   # port is already Int
}

if (line ~ / ':' <capture d+> /) {
  echo $[_group(1)]
}
```

Eggex rules that differ from PCRE:
- Keep `/ ... /` on a single line (newlines inside `/ ... /` are parse errors).
- Literal text uses single quotes (`'host='`), never double quotes.
- Character class ranges must be space-separated, and punctuation other than
  `_` must be single-quoted: `[a-z A-Z 0-9 '._-']`, not `[a-zA-Z0-9._-]`.
- Negation is `![...]` or `!digit`; anchors are `%start` and `%end`.
- Do not mix `Match` and `_group()`: `_group()` fails after `s.search()`.

## Sort a list

`List` has no `sort()` method and strings do not support `<` (`strcmp` only).
For newline-free strings, delegate to external `sort`:

```ysh
var raw = ['beta', 'alpha', 'gamma']
var sorted = @(write -- @raw | LC_ALL=C sort)
```

## Declare before branching (flat scope)

Inside `proc` and `func`, `if`/`for`/`cd` blocks share one flat scope.
Declare variables once before the branch and mutate with `setvar`:

```ysh
func classify(n) {
  var label = null
  if (n > 0) {
    setvar label = 'positive'
  } else {
    setvar label = 'non-positive'
  }
  return (label)
}
```

## Tests

```ysh
#!/usr/bin/env ysh
#
# Smoke test for lib/fleet.ysh.

source $_this_dir/../lib/fleet.ysh

try { load-fleet /dev/null 2>/dev/null }
assert [_error.code === 1]
assert [len(FLEET) === 0]

var tmp = $(mktemp)
write -- '{"nodes": []}' > $tmp
try { load-fleet $tmp }
assert [_error.code === 0]
assert [len(FLEET.nodes) === 0]
rm -f $tmp
```

Procs are called as commands, not in expression mode, so a hyphenated name like
`load-fleet` cannot appear inside `assert [...]`. Check the status through
`_error.code`. `assert [expected === actual]` prints both values on failure.
Check syntax with `ysh -n tests/fleet_test.ysh >/dev/null` before running.
