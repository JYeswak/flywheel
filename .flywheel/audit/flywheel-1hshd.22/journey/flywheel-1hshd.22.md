# Journey: flywheel-1hshd.22

## Phase 1: read packet, reserve, baseline probe
- Dispatch packet `/tmp/dispatch_flywheel-1hshd.22-b8f111.md` (Target=flywheel:0.4, Identity=MistyCliff, Callback=pane 1)
- Surface: `.flywheel/scripts/cross-session-worker-borrow.sh` (424 lines pre-scaffold)
- Per-flag baseline probe: --info exists (mode=info), --schema exists (mode=schema, w/ state_machine), --doctor flag exists, repair/validate/audit/why DON'T exist as verbs.
- Variant choice: **NUANCED-PARTIAL-BYPASS** ({--info, --schema} bypass to native; everything else owned by scaffold).

## Phase 2: scaffold + variant configuration
- Backup → `.flywheel/audit/flywheel-1hshd.22/cross-session-worker-borrow.before`
- Apply scaffold (424 → 680 lines, 18 TODOs)
- Configure `_scaffold_is_canonical_arg` for NUANCED-PARTIAL-BYPASS:
  - Bypass: --info, --schema
  - Pre-bypass for native flags: --request/--release/--check-eligibility/--list/--doctor/--source-session/--source-pane/--target-session/--target-pane/--task-id/--reason/--task-sha256/--window-minutes/--ttl-minutes/--idempotency-key/--apply/--apply-overrides/--ledger
- Top comment annotated.

## Phase 3: fill 8 stubs
- `scaffold_emit_schema`: 7 surfaces with state_machine refs
- `scaffold_emit_topic_help`: per-topic blocks
- `scaffold_cmd_doctor`: 7 probes (bash, jq, mktemp, ntm_executable, roster_readable, ledger_dir_writable, audit_log_dir_writable)
- `scaffold_cmd_health`: 24h stale threshold against borrow ledger mtime
- `scaffold_cmd_repair`: 3 scopes (roster_dir, ledger_dir, audit_log_dir); --apply needs --idempotency-key (rc=3); rc=64 unknown_scope
- `scaffold_cmd_validate`: 4 subjects (session-name, borrow-state, ttl-minutes, audit-row); borrow-state cross-sources --schema .state_machine.states (10-state enum)
- `scaffold_cmd_audit`: cli_emit_audit_tail or fallback tail
- `scaffold_cmd_why`: match against ts / borrow_id / requestor_session / target_session / run_id

## Phase 4: lint-idiom-fix
- Lint flagged L5 missing strict mode on `set -uo pipefail`
- Applied two-line idiom: `set -euo pipefail; set +e` (3rd recurrence of pattern this session)

## Phase 5: extend tests 13 → 19
- Calibrated tests 2/3 (native `.mode` field, not `.command`)
- Calibrated test 7 (real scope `roster_dir`)
- Calibrated test 9 (bare-validate refuses rc=64 + `missing_subject`)
- Added 6 fillin tests including borrow-state full-enum sweep (10 accept + 1 reject)

## Phase 6: smoke + evidence + close
- 18 smoke captures
- 19/19 test PASS
- evidence.md + compliance-pack.md + journey/
- Reservations released, scratch cleaned, br close, callback to flywheel:1
