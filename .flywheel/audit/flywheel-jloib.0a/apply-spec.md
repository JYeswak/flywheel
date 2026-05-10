# Bead jloib.0a: canonical-cli-helpers.sh library

Foundation for canonical-cli + doctor-mode integration tooling.
Drop-in helpers that compress per-surface boilerplate by ~50%.

Pilot reference: `.flywheel/scripts/daily-report-enabled-repos.sh` +
`tests/daily-report-enabled-repos-canonical-cli.sh` (commit dab051e).

## Goal

Ship `.flywheel/lib/canonical-cli-helpers.sh` providing reusable functions
for the templated portions of canonical-cli + doctor-mode work. After
this lands, every P0 surface upgrade can `source` this lib at the top and
call helpers instead of inlining ~150 lines of boilerplate per script.

## Scope

### AG1: helper functions (drop-in)

```bash
# Time + script identity
cli_iso_now                                    # echo UTC ISO timestamp
cli_sha_self <script_path>                     # echo sha256 of caller

# Audit log primitive
cli_audit_append <log_path> <action> <status> [<extra_json>]
  # Appends one JSONL row: {ts, action, status, sha256, ...extra}
  # extra_json must be valid JSON object string OR empty (defaults to {})
  # Creates dirname if missing. Silent on append failure.

# Refusal envelope
cli_refuse_apply_without_idem_key <schema_version> <command> <scope>
  # Emits the canonical refusal envelope and exits 3.
  # Used in repair subcommands when --apply was passed without --idempotency-key.

# Subcommand --help routing
cli_dispatch_subcommand_help <topic_help_function> <args...>
  # If first arg is --help or -h, calls topic_help_function and exits 0.
  # Else returns 0 (caller proceeds with normal dispatch).

# --info envelope generator
cli_emit_info <name> <version> <schema_version> <subcommands_csv> <env_vars_csv> [<extra_paths_json>]
  # Emits canonical {schema_version,command,name,version,sha256,paths,env_vars,subcommands,canonical_cli_surfaces,...}
  # subcommands_csv: comma-separated subcommand names
  # env_vars_csv: comma-separated env-var names
  # extra_paths_json: optional JSON object of {key:path} entries to merge into .paths

# --examples envelope generator
cli_emit_examples <schema_version> <examples_jsonl_string>
  # examples_jsonl_string: newline-delimited JSON, each {name,invocation,purpose}
  # Wraps into canonical envelope.

# quickstart envelope generator
cli_emit_quickstart <schema_version> <steps_jsonl_string> [<next_actions_csv>]
  # steps_jsonl_string: newline-delimited JSON, each {step,action,command}

# Completion generators
cli_emit_completion_bash <command_name> <subcommands_csv> <flags_csv>
cli_emit_completion_zsh <command_name> <subcommands_csv>

# Topic help dispatcher (data-driven; topics defined in caller)
cli_emit_topic_help <topic> <topic_map_file>
  # topic_map_file: JSON {<topic>:"<help text>", ...}
  # Empty topic shows topic list.
```

### AG2: bug-prevention defaults

The lib must DEMONSTRATE correct patterns to prevent the 4 bugs hit
during pilot:

1. Each helper begins with `set -euo pipefail` already assumed; helpers
   themselves never assume it's NOT set, but they're robust to either.
2. All `local` declarations are split (one var per `local` line) where
   the second initialization references the first.
3. All enumerator-style helpers end with explicit `return 0`.
4. Default values for params with braces: `${N:-}` then `[[ -n "$x" ]] || x='{}'`,
   never `${N:-{}}`.
5. Conditional-return helpers use `if/then/elif/fi`, never `[[ ]] && X || Y`.

### AG3: schema versioning

The lib carries its own schema version: `canonical-cli-helpers/v1`.
Helpers emit consumer-script schemas; the lib doesn't override
caller's `<surface>.<command>/v1` schema versions.

### AG4: smoke test

Ship `tests/canonical-cli-helpers-smoke.sh` exercising:
- Each helper produces valid JSON (where applicable)
- `cli_audit_append` with empty `extra_json` produces single-row JSONL
- `cli_audit_append` with valid extra_json merges keys correctly
- `cli_refuse_apply_without_idem_key` exits 3 with refusal envelope
- `cli_dispatch_subcommand_help --help` returns 0; dispatch fired
- `cli_emit_info` emits envelope with all required fields
- `cli_emit_completion_bash`/zsh produce parsable shell scripts

### AG5: documentation

Ship `.flywheel/lib/canonical-cli-helpers.README.md` with:
- One-line per helper
- Sourcing pattern: `source "$REPO/.flywheel/lib/canonical-cli-helpers.sh"`
- Per-helper example usage
- Caveat list (the 4 bash gotchas the lib helps avoid)

## Boundary

- READ from caller's env (no globals owned by the lib except its own
  schema version).
- WRITE only to paths the caller passes in. Never make assumptions
  about caller's audit log path.
- DO NOT replace functions the lib doesn't fully cover (e.g., per-surface
  doctor checks, repair actions, validate logic — those stay in caller).
- ZERO external dependencies beyond `bash`, `jq`, `date`, `shasum`.

## Acceptance gate

- `bash -n .flywheel/lib/canonical-cli-helpers.sh` passes
- `bash tests/canonical-cli-helpers-smoke.sh` exits 0 with all assertions pass
- README.md documents every exported helper
- Pilot script (jloib.0d) successfully refactors against this lib

## Estimated effort

~4 hours. ~250 lines of helpers + ~80 lines of smoke tests + ~50 lines docs.
