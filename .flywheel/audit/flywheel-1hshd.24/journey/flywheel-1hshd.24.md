# Journey: flywheel-1hshd.24

## Phase 1: read packet, set up scratch, baseline probe
- Dispatch packet `/tmp/dispatch_flywheel-1hshd.24-0d0a8a.md` (Target=flywheel:0.4, Identity=MistyCliff, Callback=pane 1)
- Surface: `.flywheel/scripts/customer-facing-observability-probe.sh` (308 lines pre-scaffold)
- Per-flag baseline: --info (mode=info), --schema (mode=schema), --doctor (mode=doctor flag), --examples NOT present, no scaffold verbs.
- Variant: **NUANCED-PARTIAL-BYPASS** (--info/--schema/--doctor flag bypass to native).

## Phase 2: scaffold + initial variant configuration
- Backup → `.flywheel/audit/flywheel-1hshd.24/customer-facing-observability-probe.before`
- Apply scaffold (308 → 564 lines, 18 TODOs)
- Configure `_scaffold_is_canonical_arg` initial NUANCED-PARTIAL-BYPASS — bypass list included --apply/--dry-run because native uses them.

## Phase 3: REFINEMENT — scaffold-verb-first
- Smoke test revealed `repair --apply` and `repair --scope phantom` were bypassed to native (treated as unknown arg).
- Root cause: scaffold's repair verb ALSO accepts --apply/--dry-run (as per-verb modifiers); the bypass list precedence broke verb-first ownership.
- **Refinement**: re-order `_scaffold_is_canonical_arg` to verb-first — when args[0] is a scaffold verb, scaffold owns regardless of downstream flags. Per-flag bypass only checks when no scaffold verb is at args[0].
- This is a strong skill discovery: NUANCED-PARTIAL-BYPASS verb-first refinement for surfaces with conflicting --apply/--dry-run namespaces.

## Phase 4: fill 8 stubs
- `scaffold_emit_schema`: 7 surfaces (default + 6 verbs) with per-surface contract refs
- `scaffold_emit_topic_help`: per-topic blocks
- `scaffold_cmd_doctor`: 7 probes (bash/jq/dev_root/ledger_dir/audit_log_dir/client_repos/product_repos)
- `scaffold_cmd_health`: binds audit log; emits freshness_budget_hours + last_run_ts
- `scaffold_cmd_repair`: 2 scopes (ledger_dir, audit_log_dir); --apply needs --idempotency-key (rc=3); rc=64 unknown_scope
- `scaffold_cmd_validate`: 3 subjects (client-slug, freshness-hours, observability-state); observability-state cross-sources --schema .customer_observability_state_enum (3-state enum)
- `scaffold_cmd_audit`: cli_emit_audit_tail or fallback
- `scaffold_cmd_why`: 4-key match (ts, run_id, client, product)

## Phase 5: lint-idiom-fix
- Lint flagged L5 missing strict mode; applied two-line idiom `set -euo pipefail; set +e` (4th recurrence)

## Phase 6: extend tests 13 → 19
- Calibrated tests 2/3 (native `.mode` shape); test 7 (real scope `ledger_dir`); test 9 (bare-validate rc=64 + `missing_subject`)
- Added 6 fillin tests including observability-state full-enum sweep (3 accept + 1 reject) + 4-direction fidelity

## Phase 7: smoke + evidence + close
- 20 smoke captures
- 19/19 test PASS
- evidence.md + compliance-pack.md + journey/
- br close, callback to flywheel:1
