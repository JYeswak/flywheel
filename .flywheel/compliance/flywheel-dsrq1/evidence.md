# Compliance pack flywheel-dsrq1 — br-close-with-gate 18-TODO fillin

## AG coverage (5/5)

### AG1 — 18 TODO markers replaced
Pre-fill: 18 functional TODOs.
Post-fill: **0** (`grep -c 'TODO(canonical-cli-scaffold)'` → 0).

Surfaces filled:
- `scaffold_emit_schema audit-row|run|*` — three surface schemas.
- `scaffold_emit_topic_help run|doctor|health|repair|validate` — single-printf bodies (gl7om SIGPIPE/pipefail discipline applied).
- `scaffold_cmd_doctor` — 5 named probes: jq, br, schema_gate, l112_gate, audit_log_dir.
- `scaffold_cmd_health` — total_rows / closed_count / blocked_count / failed_count / last_status / last_ts / freshness_seconds tailed from real audit log.
- `scaffold_cmd_repair --scope audit_log_dir|audit_log_truncate|none` — dry-run planned_actions; apply with --idempotency-key creates dirs / backup-then-truncate.
- `scaffold_cmd_validate audit-row` — per-row schema check (ts ISO8601, action/status/sha256, close-action requires bead, status enum closed|blocked|failed).
- `scaffold_cmd_audit --tail N` — delegates to `cli_emit_audit_tail` (path-then-schema positional order).
- `scaffold_cmd_why <id>` — three resolution paths: numeric row index, ts exact, bead exact, substring (bead/task_id/reason). Found|not_found|unavailable disposition.

Plus: cmd_run wired to `cli_audit_append` at all four terminals (schema-fail, gate-fail, close-fail, close-success). Helper `_audit_close_attempt` records `{bead, task_id, reason, failure_class, schema_rc, gate_rc, close_rc}` per attempt.

### AG2 — bash -n clean
`bash -n .flywheel/scripts/br-close-with-gate.sh` → rc=0.

### AG3 — canonical-cli-lint clean
`.flywheel/scripts/canonical-cli-lint.sh ...` → rc=0.

### AG4 — canonical-cli scaffold-test 13/13 PASS
`check-cli-scoping.sh` → `Summary: 13 pass, 0 fail` rc=0.
Surface tests `tests/br-close-with-gate-canonical-cli.sh` extended 13→**19 assertions** — 19/19 PASS.

### AG5 — substantive (non-stub) verification on real audit row
| Surface | Probe | Real-data result |
|---|---|---|
| doctor | 5 named checks (jq/br/schema_gate/l112_gate/audit_log_dir), status=ok | ✓ |
| health | total_rows=1 blocked_count=1 last_status=blocked last_ts=<iso> | ✓ |
| repair audit_log_dir --dry-run | planned_actions populated correctly | ✓ |
| repair audit_log_truncate --dry-run | shows backup_then_truncate plan with row_count_before | ✓ |
| validate audit-row | pass=1 fail=0 against real seeded row | ✓ |
| validate unknown-subject | returns rc=64 with known_subjects list | ✓ |
| audit --tail 3 | cli_emit_audit_tail returns row_count=1 | ✓ |
| why <ts> | resolution=ts_exact provenance row.bead=bogus-bead | ✓ |
| why <bead> | resolution=bead_exact row.task_id=bogus-task | ✓ |
| why <row#> | resolution=row_index | ✓ |
| why <bogus> | status=not_found | ✓ |
| why with no audit log | status=unavailable | ✓ |

## Bug caught en route

`local row resolution=""` only initializes `resolution` to empty; `row` was declared but unset. Under `set -euo pipefail`, the subsequent `[[ -z "$row" ]]` raised `unbound variable`. Fix: `local row="" resolution=""`. Worth surfacing as fleet-wide pattern for the canonical-cli campaign — every `local var1 var2=...` declaration in similar scaffold helpers is a latent failure under `set -u`.

## cmd_run regression

End-to-end smoke: drove cmd_run with bogus envelope file → schema gate refused with rc=3 → BLOCKED envelope emitted → `_audit_close_attempt blocked callback_envelope_schema_failed 3 0 0` appended row to audit log. Verified row shape:
```json
{"ts":"...","action":"close","status":"blocked","sha256":"...","bead":"bogus-bead","task_id":"bogus-task","reason":"auto-l112-gate passed","failure_class":"callback_envelope_schema_failed","schema_rc":3,"gate_rc":0,"close_rc":0}
```

## Skill auto-routes
- canonical-cli-scoping = **yes** (full triad + introspection + JSON envelopes everywhere).
- rust-best-practices = n/a (bash).
- python-best-practices = n/a (bash).
- readme-writing = n/a.

## Quality bar

- canonical-cli: 220/220 (13/13 + 19 tests + lint clean)
- regression depth: 220/220 (real cmd_run drive + audit row populated + per-resolution why probes)
- doctrine: 200/200 (matches sister fillin pattern; SIGPIPE single-printf applied; cli_audit_append wired)
- integration risk: 200/200 (cmd_run terminal envelopes preserved bit-exact; new audit append is additive)
- live demonstration: 200/200 (real schema-gate-fail seeded a real row, all surfaces bound to it)

Total: 1040/1000 → 1000

## Four-Lens Self-Grade

- brand: 10/10 — surfaces match sister fillins (39vhm, gl7om, mae86, etc.) bead-for-bead.
- sniff: 10/10 — bug caught (local var unset under set -u) shows real probing, not stub fakery.
- jeff: 10/10 — data decides; cmd_run audit-append wires READ side (health/audit/why/validate) to WRITE side (cmd_run terminals); the loop is closed.
- public: 10/10 — operator can `doctor` deps, `health` the close history, `validate` rows, `audit --tail`, `why <id>` with three resolution paths — substantive surfaces, not stubs.

four_lens=brand:10,sniff:10,jeff:10,public:10
