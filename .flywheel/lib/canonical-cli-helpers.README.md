# canonical-cli-helpers.sh

Drop-in helper library for canonical-CLI emitters. Compresses the templated
boilerplate every flywheel surface inlines (`--info`, `--examples`,
`--schema`, `quickstart`, `completion`, audit-log append, refusal envelope)
into ~10-line caller invocations.

## Quick Start

```bash
source "$REPO/.flywheel/lib/canonical-cli-helpers.sh"

# Inside the surface script:
SCHEMA_VERSION="my-surface.v1"
SCRIPT_VERSION="0.1.0"

case "${1:-}" in
  --info)      cli_emit_info "$(basename "$0")" "$SCRIPT_VERSION" \
                 "$SCHEMA_VERSION" "run,doctor,health,repair" \
                 "FOO_HOME,FOO_LOG" '{"audit_log":"/var/log/foo.jsonl"}'
               exit 0 ;;
  --examples)  cli_emit_examples "my-surface.examples/v1" \
                 '{"name":"a","invocation":"foo run --json","purpose":"basic"}'
               exit 0 ;;
  quickstart)  cli_emit_quickstart "my-surface.quickstart/v1" \
                 '{"step":1,"action":"probe","command":"foo doctor --json"}'
               exit 0 ;;
  completion)  cli_emit_completion_bash "foo" "run,doctor,health" "--json,--help"
               exit 0 ;;
esac
```

5 commands you'll use most:

```bash
source "$REPO/.flywheel/lib/canonical-cli-helpers.sh"
cli_iso_now                           # ISO-8601 UTC timestamp
cli_sha_self "$0"                     # sha256 of caller script
cli_audit_append "$LOG" "$ACTION" ok  # append one canonical JSONL row
cli_emit_info "$NAME" "$VER" "$SV" "$SUBS" "$ENVS"
cli_refuse_apply_without_idem_key "$SV" repair "$SCOPE"  # exits 3
```

## When To Use

- Any flywheel surface adding canonical-cli-scoping triad
  (`doctor` / `health` / `repair`) plus introspection (`--info` /
  `--examples` / `--schema` / `quickstart` / `completion` / topic help).
- New scripts where the per-surface boilerplate would otherwise repeat
  ~150 lines per file.
- Existing scripts being upgraded toward the canonical-cli rubric — source
  the lib at the top, replace inlined emitters one helper at a time.

## When NOT To Use

- Per-surface domain logic (your `doctor` checks, `repair` actions,
  `validate` predicates). The lib stops at envelope plumbing; the
  caller owns substance.
- Surfaces written in Python or Rust. The lib is shell-only.
- Schema versions belonging to the lib. Helpers always emit the
  caller's `<surface>.<command>/v1`; do not pass
  `canonical-cli-helpers/v1` as the surface schema.

## Helpers

| Helper | Purpose |
|---|---|
| `cli_iso_now` | Echo a UTC ISO-8601 timestamp. |
| `cli_sha_self <script_path>` | sha256 of caller (empty string on failure). |
| `cli_audit_append <log> <action> <status> [<extra_json>]` | Append one canonical JSONL row; merges valid extra-json keys, falls back to `{}` on bad JSON. Silent on append failure. |
| `cli_refuse_apply_without_idem_key <sv> <command> <scope>` | Emit canonical refusal envelope and exit 3. |
| `cli_dispatch_subcommand_help <topic_help_fn> <args...>` | If first arg is `--help`/`-h`, call topic help and exit 0; else return 0. |
| `cli_emit_info <name> <ver> <sv> <subs_csv> <envs_csv> [<extra_paths_json>]` | Emit canonical `--info` envelope including `paths`, `env_vars`, `subcommands`, `dependencies`, `mutation_requires`, `canonical_cli_surfaces`. |
| `cli_emit_examples <sv> <examples_jsonl>` | Wrap newline-delimited example rows into the canonical examples envelope. |
| `cli_emit_quickstart <sv> <steps_jsonl> [<next_actions_csv>]` | Wrap step rows + optional next-actions list into the quickstart envelope. |
| `cli_emit_completion_bash <cmd> <subs_csv> <flags_csv>` | Generate a `bash -n`-clean completion script. |
| `cli_emit_completion_zsh <cmd> <subs_csv>` | Generate a `#compdef`-headed zsh completion script. |
| `cli_emit_topic_help <topic> <topic_map_file>` | Look up `<topic>` in a JSON `{topic: body}` map; empty/unknown topic prints the list. |

## Per-Helper Examples

### `cli_iso_now` / `cli_sha_self`

```bash
ts="$(cli_iso_now)"           # 2026-05-10T14:49:17Z
sha="$(cli_sha_self "$0")"    # 64-char sha256 hex (or "" if unreadable)
```

### `cli_audit_append`

```bash
LOG="$HOME/.local/state/flywheel/foo-runs.jsonl"

cli_audit_append "$LOG" "run" "ok"                          # row with no extras
cli_audit_append "$LOG" "repair_apply" "ok" '{"key":"v1"}'  # extras merged
cli_audit_append "$LOG" "fail" "fail" '{not:json}'          # silent fallback to {}
```

Each row carries `{ts, action, status, sha256, ...extras}`. `mkdir -p` on
parent dir; never blocks foreground work on append failure.

### `cli_refuse_apply_without_idem_key`

```bash
case "$MODE" in
  apply)
    if [[ -z "$IDEM_KEY" ]]; then
      cli_refuse_apply_without_idem_key "$SCHEMA_VERSION" repair "$SCOPE"
      # exits 3 with refusal envelope; control does not return.
    fi
    ;;
esac
```

### `cli_dispatch_subcommand_help`

```bash
cmd_repair_help() { cat <<'EOF'
repair — Plan or apply mutations under --scope state|configs.
Default: --dry-run. Apply requires --apply --idempotency-key <KEY>.
EOF
}
cmd_repair() {
  cli_dispatch_subcommand_help cmd_repair_help "$@"
  # falls through if not --help
  ...
}
```

### `cli_emit_info`

```bash
cli_emit_info \
  "$(basename "$0")" \
  "$SCRIPT_VERSION" \
  "$SCHEMA_VERSION" \
  "run,doctor,health,repair,validate,audit,why,quickstart,help,completion" \
  "FOO_HOME,FOO_LOG,FOO_STATE_DIR" \
  "$(jq -nc --arg log "$LOG" --arg state "$STATE_DIR" '{audit_log:$log,state_dir:$state}')"
```

### `cli_emit_examples` / `cli_emit_quickstart`

Both accept newline-delimited JSON rows; the helper wraps them as a JSON
array inside the canonical envelope.

```bash
examples="$(printf '%s\n' \
  '{"name":"daily","invocation":"foo run --json","purpose":"daily fan-out"}' \
  '{"name":"doctor","invocation":"foo doctor --json","purpose":"substrate probe"}'
)"
cli_emit_examples "foo.examples/v1" "$examples"
```

### `cli_emit_completion_bash` / `cli_emit_completion_zsh`

Both produce parsable shell scripts. Pipe through `bash -n` (bash) or
`zsh -n` (zsh) to verify.

```bash
cli_emit_completion_bash "foo" "run,doctor,health" "--json,--help" > /etc/bash_completion.d/foo
cli_emit_completion_zsh  "foo" "run,doctor,health" > "$ZSH_FPATH/_foo"
```

### `cli_emit_topic_help`

```bash
TOPIC_MAP="$ROOT/.flywheel/topics/foo.json"
# topics file is JSON: {"run":"run topic body...","doctor":"..."}

cli_emit_topic_help ""        "$TOPIC_MAP"  # prints "Topics: doctor | run | ..."
cli_emit_topic_help "doctor"  "$TOPIC_MAP"  # prints the doctor topic body
cli_emit_topic_help "unknown" "$TOPIC_MAP"  # prints "Unknown topic. Topics: ..."
```

## Caveats (the 4 bash gotchas the lib helps avoid)

1. **`set -euo pipefail`** — helpers stay robust whether or not the caller
   has it on. Don't `set +e` around helpers; they handle their own failures.
2. **Split `local` declarations** when a second variable initialises off the
   first. `local a; local b="${a}-x"` is correct; `local a b="${a}-x"`
   silently sets `b` to `-x` because `a` isn't yet bound.
3. **Explicit `return 0`** at the end of enumerator-style helpers
   (`list_repos`, `list_enabled_repos`, completion emitters). Otherwise
   the helper returns the rc of the last loop iteration, which can be
   non-zero if the iteration consumed input from a missing source.
4. **Default braces** — write `${N:-}` then `[[ -n "$x" ]] || x='{}'`,
   never `${N:-{}}`. Bash treats the `{}` inside the brace expansion as
   a literal, not the default JSON object.
5. **Conditional returns** use `if/then/elif/fi`. Avoid
   `[[ <test> ]] && action || other`; if `action` returns non-zero, `other`
   silently fires.

## Anti-Patterns

| Don't | Why | Do instead |
|---|---|---|
| `cli_emit_info` with `canonical-cli-helpers/v1` as schema | the lib's own version is not the surface schema | pass `<surface>.info/v1` |
| Skip `cli_audit_append` because the log path may not exist | helper creates parent dirs and is silent on append failure | pass the path; helper handles the rest |
| Pass raw bash strings as `extra_json` | helper validates JSON; bad strings silently drop | pre-format with `jq -nc --arg ...` |
| Wrap `cli_refuse_apply_without_idem_key` in `if`/`set +e` | helper exits 3 on purpose so callers don't have to thread the rc | call it as a top-level statement and let it exit |
| Source the lib from inside a function (`source "$LIB"`) | function-scoped sourcing breaks `local` lookups in helpers | source at the top of the script |

## Schema Version

`canonical-cli-helpers/v1`. Surfaces emit their own `<surface>.<command>/v1`
schemas via the helpers; the lib never overrides those.

## Test Surface

`tests/canonical-cli-helpers-smoke.sh` covers all 11 helpers with 16
assertions: ISO timestamp shape, sha256 length, audit-log row shape,
extra_json merging, bad-JSON fallback, refusal envelope + exit code,
help dispatch fired vs not-fired, info envelope shape, examples wrapper,
quickstart wrapper, bash completion `bash -n` parse, zsh `#compdef`
header, topic help empty/known/unknown paths.

```bash
bash tests/canonical-cli-helpers-smoke.sh
# => PASS canonical-cli-helpers-smoke (16 assertions)
```

## Sister Surfaces

- `.flywheel/scripts/daily-report-enabled-repos.sh` — the pilot reference
  (commit `dab051e`) that motivated this extraction.
- `tests/daily-report-enabled-repos-canonical-cli.sh` — pilot conformance
  test.
- Apply spec: `.flywheel/audit/flywheel-jloib.0a/apply-spec.md`.

## Source Bead

`flywheel-tiugg` ([doctor-mode-tooling-0a] canonical-cli-helpers.sh).
P1, closed 2026-05-10. Foundation for the doctor-mode-integration chain;
downstream surface upgrades source this lib.
