# Codex App-Server Metadata Pollution Audit

Date: 2026-05-19
Bead: flywheel-w3x2k
Scope: scoped to codex app-server cwd/originator pollution audit + fix

## Disposition

Disposition: `NOT_IN_USE`

The pinned local CLI is `codex-cli 0.130.0`. `codex app-server` exists, and watchtower flagged `openai/codex#23437` as high relevance, but the audited flywheel worker substrate does not show app-server use for autonomous Codex dispatches. No Codex install files were patched.

## Evidence

1. Watchtower source exists and is high relevance:
   - `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-19.jsonl`
   - Issue `openai/codex#23437`: "codex app-server can pollute subsequent TUI session metadata (wrong cwd/source/originator)"
   - Labels: `bug`, `CLI`, `regression`, `app-server`
   - `env_match=true`, signals include `0.130.0`

2. Local CLI shape:
   - `codex --version` => `codex-cli 0.130.0`
   - `codex app-server --help` is present and labels the surface experimental.
   - `ps ax ... | rg 'codex.*app-server|app-server'` found no running app-server process at audit time.

3. Codex session metadata, 2026-05-19:
   - `session_meta` rows inspected: 26.
   - `source=cli`: 26.
   - `originator=codex-tui`: 26.
   - Non-CLI source rows: 0.
   - Non-TUI originator rows: 0.
   - Observed cwd values were expected repo roots: flywheel, skillos, mobile-eats, polymarket-pico-z, clutterfreespaces, and zesttube.

4. Dispatch-log callback metadata, last 24h:
   - Terminal callback rows inspected: 41.
   - Rows with `cwd`: 0.
   - Rows with `repo_path`/`source_repo_path`: 0.
   - Rows with `originator`: 0.
   - Rows with app-server/source markers: 0.

Because callback envelopes currently do not carry these metadata fields, there was no observed cwd/originator drift to repair. The risk remains future-facing: once callback rows include cwd/originator/repo_path, those fields must be internally consistent before downstream workspace inference trusts them.

## Guard Shipped

`.flywheel/scripts/dispatch-log-fitness-invariant.sh` now reads callback-shaped rows from `.flywheel/dispatch-log.jsonl` and flags:

- `cwd_repo_path_mismatch`: reported `cwd` does not resolve to the git top-level of the named `repo_path`.
- `originator_agent_mismatch`: reported `originator` differs from the callback agent identity when both are present.

Rows without these metadata fields are not considered polluted; they are counted as unchecked.

## Validation

- `bash tests/codex-app-server-metadata-fires-clean.sh` => `SUMMARY pass=12 fail=0`
- `bash tests/test_dispatch_log_fitness_invariant.sh` => `Results: 10 PASS  0 FAIL`
- `shellcheck .flywheel/scripts/dispatch-log-fitness-invariant.sh tests/codex-app-server-metadata-fires-clean.sh tests/test_dispatch_log_fitness_invariant.sh` => PASS
- `bash -n .flywheel/scripts/dispatch-log-fitness-invariant.sh tests/codex-app-server-metadata-fires-clean.sh tests/test_dispatch_log_fitness_invariant.sh` => PASS
- Real flywheel cwd check with `NTM_TIMELINE_JSON='{"events":[]}'` => `metadata_integrity_status=PASS`, `cwd_integrity_checked=0`, `cwd_integrity_violation_count=0`
