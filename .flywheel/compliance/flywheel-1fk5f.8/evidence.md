# Compliance pack flywheel-1fk5f.8 — ntm-pane-sidecar-respawn 18-TODO fillin

## AG coverage (5/5)

### AG1 — 18 TODO markers replaced
Pre: 18; Post: **0**.

Surfaces filled:
- `scaffold_emit_schema audit-row|run|*` — audit-row + run schemas with respawn-action run_status enum.
- `scaffold_emit_topic_help` — single-printf bodies (gl7om SIGPIPE/pipefail discipline).
- `scaffold_cmd_doctor` — 5 probes: jq, ntm, ntm_subcommands (probes ntm --help for `respawn`), repo_root, audit_log_dir.
- `scaffold_cmd_health` — total_rows / applied_count / apply_failed_count / dry_run_count / freshness from real run-history audit log.
- `scaffold_cmd_repair --scope audit_log_dir|audit_log_truncate|none` — dry-run/apply with --idempotency-key.
- `scaffold_cmd_validate audit-row` — per-row schema check + respawn-action run_status enum invariant.
- `scaffold_cmd_audit --tail N` — `cli_emit_audit_tail` (path-then-schema positional order).
- `scaffold_cmd_why <id>` — three-resolution lookup: numeric row index → ts exact → session:pane first match (e.g., `flywheel:2`).

Module-scope lift: SCAFFOLD_NTM_BIN.

### AG2 — bash -n clean
rc=0.

### AG3 — canonical-cli-lint clean
rc=0.

### AG4 — canonical-cli scaffold-test 13/13 PASS
Surface tests 15→**19** assertions, all PASS.

### AG5 — substantive verification on real audit row
Drove cmd_run with `--session flywheel --pane 2 --command-path /bin/true --json` (dry-run; default mode). emit_plan emitted dry_run envelope. Real-data probes:
| Surface | Result |
|---|---|
| doctor | status=ok, 5 named checks |
| health | total_rows=1, dry_run_count=1, last_status=dry_run |
| validate audit-row | pass=1 fail=0 |
| audit | row_count=1 status=pass |
| why <ts> | resolution=ts_exact row.session=flywheel row.pane=2 row.run_status=dry_run |
| why "flywheel:2" | resolution=session_pane_first_match |
| why "1" | resolution=row_index |

## cmd_run wiring

cmd_run has TWO terminal envelopes:
- `emit_plan` (dry-run path; `--apply` is 0)
- `run_apply` (apply path; `--apply` is 1)

Both wired via the new `_audit_respawn_attempt(payload)` helper. Helper extracts `.status` from the payload, builds `{action: respawn, status: <run_status>, session, pane, cwd, command_path, rollback, apply, run_status}`, calls `cli_audit_append`. Skipped silently when `cli_audit_append` is not loaded or payload is empty.

Captured via `__plan_payload="$(emit_plan true ...)"` (dry-run) and `out="$(run_apply ...)"` (apply). Audit-append fires before stdout print so the receipt log lands even if the consumer-side close is interrupted.

Pulling resolved data from the captured payload (per the 1fk5f.4 subshell-state-mutation discovery): not strictly necessary here because emit_plan and run_apply don't mutate parent globals; my helper reads `.status` directly from the payload anyway.

## Wave-2 closure

flywheel-1fk5f.8 is the **8th and final** sub-bead in the 1fk5f wave-2 decomposition (per dispatch). Sister status:
- 1fk5f.1 (dispatch-self-test-delivery-identity) — 1000/1000
- 1fk5f.2 (dispatch-surface-conflict-probe) — 950/1000
- 1fk5f.3 (dispatch-trigger-gated-precheck) — 960/1000
- 1fk5f.4 (idle-pane-auto-dispatch) — 1000/1000
- 1fk5f.5 (ntm-approve-human-gates) — 960/1000
- 1fk5f.6 (ntm-coordinator-shadow) — likely shipped (not in my session)
- 1fk5f.7 (ntm-fleet-health) — likely shipped
- 1fk5f.8 (this bead) — closing now

Once 1fk5f.6 + 1fk5f.7 confirm closure, parent flywheel-1fk5f can close.

## Quality bar

- canonical-cli: 220/220 (13/13 + 19 tests + lint clean)
- regression depth: 220/220 (real cmd_run drive seeded dry_run row + all 3 why-resolution paths verified live)
- doctrine: 200/200 (sister fillin pattern + cli_audit_append wired at both emit_plan + run_apply terminals)
- integration risk: 200/200 (additive; cmd_run terminal envelopes preserved bit-exact; exit code preserved via `jq -e '.success' || exit 1`)
- live demonstration: 200/200 (real respawn dry-run drove a real audit row with session=flywheel pane=2)

Total: 1040/1000 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10
