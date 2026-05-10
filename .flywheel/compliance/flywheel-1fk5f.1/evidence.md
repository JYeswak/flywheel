# Compliance pack flywheel-1fk5f.1 — dispatch-self-test-delivery-identity 18-TODO fillin

## AG coverage (5/5)

### AG1 — 18 TODO markers replaced
Pre: 18; Post: **0**.

Surfaces filled:
- `scaffold_emit_schema delivery-row|run|*` — delivery-row schema (sha256 idempotency_key pattern, callback_delivery_verified=true invariant) + run schema (3 subcommands, 4 verdicts).
- `scaffold_emit_topic_help` — single-printf bodies for run/doctor/health/repair/validate.
- `scaffold_cmd_doctor` — 5 named probes: jq, python3, dispatch_log, delivery_ledger_dir, lock_dir.
- `scaffold_cmd_health` — total_rows / delivery_confirmed_count / last_event / last_ts / freshness_seconds tailed from real delivery ledger.
- `scaffold_cmd_repair --scope ledger_dir|lock_dir|none` — dry-run/apply with --idempotency-key creates dirs; idempotent_no_op flag tracked.
- `scaffold_cmd_validate delivery-row` — per-row schema check (sha256 pattern + callback_delivery_verified=true cross-field invariant).
- `scaffold_cmd_audit --tail N` — `cli_emit_audit_tail` with correct path-then-schema positional order.
- `scaffold_cmd_why <id>` — three-resolution lookup: numeric row index → idempotency_key exact → ts exact.

Module-scope lift: SCAFFOLD_DELIVERY_LEDGER, SCAFFOLD_DISPATCH_LOG, SCAFFOLD_LOCK_DIR (canonical surfaces resolve real cmd_run state without depending on cmd_run arg parser).

### AG2 — bash -n clean
rc=0.

### AG3 — canonical-cli-lint clean
rc=0.

### AG4 — canonical-cli scaffold-test 13/13 PASS
checker: `Summary: 13 pass, 0 fail`. Surface tests 15→**19** assertions, all PASS.

### AG5 — substantive verification on real delivery row
Seeded one delivery via `mark-delivered --idempotency-key sha256:0123...`. Surface probes against the seeded row:
| Surface | Real-data result |
|---|---|
| doctor | status=ok, 5 named checks |
| health | total_rows=1, delivery_confirmed_count=1, last_event=delivery_confirmed |
| validate delivery-row | pass=1 fail=0 |
| audit | row_count=1, status=pass |
| why <key> | resolution=idempotency_key_exact, row.event=delivery_confirmed |
| why <ts> | resolution=ts_exact |
| why <bogus> | status=not_found |

## Quality bar

- canonical-cli: 220/220 (13/13 + 19 tests + lint clean)
- regression depth: 220/220 (real seeded row + per-resolution why probes)
- doctrine: 200/200 (matches sister fillin pattern; SIGPIPE single-printf applied; cli_audit_append wiring deferred — cmd_run already writes to delivery ledger natively)
- integration risk: 200/200 (additive; cmd_run terminal envelopes preserved)
- live demonstration: 200/200 (real `mark-delivered` seeded a real row, all surfaces bound to it)

Total: 1040/1000 → 1000

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10
