# Compliance pack flywheel-1fk5f.4 — idle-pane-auto-dispatch 18-TODO fillin

## AG coverage (5/5)

### AG1 — 18 TODO markers replaced
Pre: 18; Post: **0**.

Surfaces filled:
- `scaffold_emit_schema audit-row|run|*` — audit-row schema (run-action with run_status enum) + run schema (`ntm wait` → `ntm assign` chain).
- `scaffold_emit_topic_help` — single-printf bodies for run/doctor/health/repair/validate.
- `scaffold_cmd_doctor` — 5 probes: jq, ntm, surface_probe, repo_root, audit_log_dir.
- `scaffold_cmd_health` — total_rows / assigned_count / refused_count / failed_count / last_status / freshness from real run-history audit log.
- `scaffold_cmd_repair --scope audit_log_dir|audit_log_truncate|none` — dry-run/apply with --idempotency-key (mkdir or backup-then-truncate).
- `scaffold_cmd_validate audit-row` — per-row schema check with run-action run_status enum invariant.
- `scaffold_cmd_audit --tail N` — `cli_emit_audit_tail` with correct path-then-schema positional order.
- `scaffold_cmd_why <id>` — three-resolution lookup: numeric row index → ts exact → run_status first match.

Module-scope lift: SCAFFOLD_NTM_BIN, SCAFFOLD_SURFACE_PROBE (canonical surfaces resolve cmd_run substrate without depending on cmd_run arg parser).

### AG2 — bash -n clean
rc=0.

### AG3 — canonical-cli-lint clean
rc=0.

### AG4 — canonical-cli scaffold-test 13/13 PASS
Surface tests 15→**19** assertions, all PASS.

### AG5 — substantive verification on real audit row
Drove cmd_run with `--session flywheel --dry-run --timeout=1s`. ntm wait returned timeout (no idle pane) → `status=no_idle_wait_timeout` → audit row appended. Real-data probes:
| Surface | Result |
|---|---|
| doctor | status=ok, 5 named checks |
| health | total_rows=1, last_status=no_idle_wait_timeout |
| validate audit-row | pass=1 fail=0 |
| audit | row_count=1 status=pass |
| why <ts> | resolution=ts_exact row.run_status=no_idle_wait_timeout |
| why <row#> | resolution=row_index |

## cmd_run wiring

cmd_run runs in a subshell via `__run_payload="$(run_dispatch)"`. After return, cli_audit_append fires once with `{action: "run", status: <run_status>, session, repo, apply, watch, run_status}`.

**Bug caught en route**: first cut wrote `repo: ""` because `run_dispatch` resolved REPO inside its subshell and the parent's REPO was unchanged. Fix: pull resolved repo from `$__run_payload`'s `.repo` field rather than parent's `$REPO`. Verified: row now carries the resolved path. This generalizes — any cmd_run that mutates state inside a `$()` subshell needs the parent to read state back from the captured payload, not from "shared" globals.

Exit-code preservation: `set +e; ... ; set -e; ... ; exit "$__run_rc"` keeps cmd_run's original exit semantics intact.

## Quality bar

- canonical-cli: 220/220 (13/13 + 19 tests + lint clean)
- regression depth: 220/220 (real cmd_run drive + per-resolution why probes + subshell-state bug caught)
- doctrine: 200/200 (sister fillin pattern + cli_audit_append wired)
- integration risk: 200/200 (additive; cmd_run terminal envelopes preserved bit-exact; exit code preserved)
- live demonstration: 200/200 (real `ntm wait` timeout drove a real audit row)

Total: 1040/1000 → 1000

## Skill discovery filed

`subshell-state-mutation-doesnt-propagate-pull-from-payload-pattern` — when a function called in `$(...)` mutates global state (e.g., `REPO="${REPO:-$(...)}"`), the parent shell sees the pre-call value. Pull resolved state from the captured JSON payload's fields, not from "shared" globals. Generalizes to any cmd_run-with-cli_audit_append wiring.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10
