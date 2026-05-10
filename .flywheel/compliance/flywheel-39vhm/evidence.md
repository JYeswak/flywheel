# Compliance pack flywheel-39vhm — dispatch-canonical-cli-validator 18-TODO fill-in

## AG coverage (5/5)

### AG1 — 18 TODO markers replaced with substantive impls
Pre-fill TODO count: 22 raw `TODO`s in file (18 functional + 4 doc/comment).
Post-fill TODO count: **0 functional TODOs** (`grep -c 'TODO(canonical-cli-scaffold)'` → 0).
Probe: `grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/dispatch-canonical-cli-validator.sh` → 0.

Surfaces filled:
- `scaffold_emit_schema decision|ledger|*` — per-surface schemas (decision row, ledger jsonl) keyed off real `dispatch-canonical-cli-decision/v1` row schema.
- `scaffold_emit_topic_help run|doctor|health|repair|validate` — surface-specific multi-line documentation.
- `scaffold_cmd_doctor` — 5 named probes: jq, repo_root, ledger_dir, ledger_file, decision_schema_sidecar.
- `scaffold_cmd_health` — total_rows / allow_count / refuse_count / last_decision / last_ts / freshness_seconds tailed from real ledger.
- `scaffold_cmd_repair --scope state|none` — dry-run emits planned_actions; apply + idempotency-key creates ledger dir/file with idempotent_no_op flag.
- `scaffold_cmd_validate ledger` — per-row schema validation (required fields + decision enum + cross-field invariant: refuse implies non-empty missing_elements).
- `scaffold_cmd_audit --tail N` — delegates to `cli_emit_audit_tail` helper; falls back to self-contained jq tail.
- `scaffold_cmd_why <ts>` — found|not_found|unavailable disposition with provenance row.

### AG2 — bash -n clean
`bash -n .flywheel/scripts/dispatch-canonical-cli-validator.sh` → rc=0.

### AG3 — canonical-cli-lint clean
`.flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/dispatch-canonical-cli-validator.sh` → rc=0 (silent).

### AG4 — canonical-cli scaffold-test 13/13 PASS
`bash ~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh .flywheel/scripts/dispatch-canonical-cli-validator.sh` → `Summary: 13 pass, 0 fail` rc=0.
Surface tests `tests/dispatch-canonical-cli-validator-canonical-cli.sh` extended 15→**19 assertions**: all PASS.

### AG5 — substantive (non-stub) verification
| Surface | Probe | Real-data result |
|---|---|---|
| doctor | `.status != "todo" and (.checks\|length) >= 5` | status=ok, 5 checks, all `ok` |
| health | `.total_rows / .last_ts / .last_decision` | total_rows=9, last_ts=2026-05-08T06:21:25Z, last_decision=allow |
| repair | `.status == "dry_run" / "applied"` + planned_actions / applied_actions | dry_run + apply both work; idempotent_no_op tracked |
| validate ledger | per-row pass/fail across all 9 real rows | pass=9 fail=0 |
| why <real ts> | found + provenance row | status=found row.decision=allow |
| why <bogus ts> | not_found | status=not_found |
| audit | tail N rows from ledger | row_count=9 status=pass |

## Regression coverage

- **Original `cmd_run` mode** (the original validator behavior) still works:
  `dispatch-canonical-cli-validator.sh check --dispatch-file <path> --json` →
  emits `decision/introduces_cli/missing_elements` row, writes to ledger.
- **Helper-lib smoke** `tests/canonical-cli-helpers-smoke.sh` → 35/35 PASS (no regression).
- **Cross-cmd contracts** preserved: --info / --schema / --examples / --help / quickstart / completion all still emit canonical envelopes.

## Skill auto-routes

- canonical-cli-scoping = **yes** (5 acceptance gates: doctor/health/repair triad, validate/audit/why subsidiary, --info/--examples/quickstart/help/completion introspection, --json everywhere, --dry-run/--apply/--idempotency-key on mutating ops, file-length under canonical-cli scaffold-allowed exemption).
- rust-best-practices = n/a (bash file).
- python-best-practices = n/a (bash file).
- readme-writing = n/a (no public README touched).

## Quality bar

- canonical-cli: 220/220 (13/13 + 19 tests + lint clean)
- regression depth: 200/200 (cmd_run path verified, helper-lib smoke, surface tests)
- doctrine: 200/200 (matches frm53/2bz0v/mae86/4pwc5/dulh3/j0zuh fillin pattern verbatim)
- integration risk: 200/200 (no schema sidecar mutation; all writes go through real cmd_run path)
- live demonstration: 200/200 (9 real ledger rows exercised through validate + why + health)

Total: 1020/1000 → 1000

## Four-Lens Self-Grade

- brand: 10/10 — fillin pattern matches sister surfaces (storage-pause-auto-resume, storage-probe, doctrine-sync) bead-for-bead.
- sniff: 10/10 — every surface bound to real data path; doctor probes substrate this script depends on; why does provenance lookup not stub.
- jeff: 10/10 — data decides; surfaces use the real `LEDGER` written by cmd_run, not a separate scaffold-only audit log; helper-lib delegate uses correct positional order.
- public: 10/10 — operator can `dispatch-canonical-cli-validator.sh doctor --json` to probe deps, `health` to see ledger health, `validate ledger` to check schema, `audit --tail 5` to see recent decisions, `why <ts>` to see why a decision was made — all without reading source.

four_lens=brand:10,sniff:10,jeff:10,public:10
