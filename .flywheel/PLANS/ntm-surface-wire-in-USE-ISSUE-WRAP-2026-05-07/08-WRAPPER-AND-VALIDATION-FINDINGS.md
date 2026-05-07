# Wrapper And Validation Findings

Generated: 2026-05-07T18:39:53Z

## Executive Findings

- Audited 13 NTM-surface wrapper scripts: 10 inventory WRAP-territory scripts, 2 ntm#124 transitional shadow scripts, and 1 ISSUE-held scrub wrapper found by actual script search.
- Built validation matrix for 106 inventory rows covering 108 NTM command aliases at `/Users/josh/Developer/flywheel/.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/07-VALIDATION-MATRIX.yaml`. Average coverage is 6.7/10.
- `flywheel doctor --json` currently exposes one NTM probe: dispatch-log fitness via `ntm timeline --json`; it does not assert wrapper adoption for W0-W3b.
- Schema-validator-duo applies to the durable YAML matrix. Current delivery mentions the gap; follow-up should add a schema and executable validator.
- Inventory mismatch: headline says 8 wrappers but the WRAP-territory table names 10, and actual scripts add 2 transitional shadows plus the scrub wrapper.

## Part A - Wrapper Justification Audit

| Wrapper script | Why-keep evidence | Deletion tripwire (upstream condition) | Test fixture | Doctor probe | Action |
|---|---|---|---|---|---|
| `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh` | CAAM profile selection, idempotency receipt, and rotation/recovery ledgers around native ntm rotate. | delete when ntm rotate supports CAAM vault-profile selection, per-operation idempotency receipts, recovery ledger append, and safe non-stdin rotation without pane contamination. | present: `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh` | missing | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-quota-proactive-probe.sh` | Threshold classification and unknown-provider warn/fail policy over native ntm quota JSON. | delete when ntm quota emits capacity_class, remaining_units, provider classification, unknown-provider policy, and stable doctor-ready fields natively. | present: `.flywheel/tests/test_ntm_quota_proactive_probe.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-metrics-doctor-probe.sh` | Maps quota metrics into flywheel doctor gate/action decisions. | delete when ntm metrics or ntm doctor emits flywheel-compatible gate/action mappings for quota capacity. | present: `.flywheel/tests/test_ntm_metrics_doctor_probe.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-serve-eventstream-bridge.sh` | Loopback-bind default plus redacted SSE payload bridge from metrics receipts. | delete when ntm serve eventstream has loopback-only default, payload redaction, readiness receipt, and metrics payload schema. | present: `.flywheel/tests/test_ntm_serve_eventstream_bridge.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-preflight-l91-wrapper.sh` | L91 four-state receipt: transport accepted, prompt visible, prompt submitted, and work started. | delete when ntm preflight/send/history emits a native four-state L91 delivery receipt with freshness and work-started classification. | present: `.flywheel/tests/test_ntm_preflight_l91_wrapper.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-safety-dcg-sibling.sh` | Keeps DCG authoritative while native ntm safety remains advisory; mismatch and malformed classifier fail closed. | delete when ntm safety can invoke/verify DCG as final authority with fail-closed JSON and no execution side effects. | present: `.flywheel/tests/test_ntm_safety_dcg_sibling.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-approve-human-gates.sh` | Exact-question receipt and blocker-class validation around native approval requests. | delete when ntm approve requires exact_question receipts, approved_by, blocker taxonomy, and stable denial classes natively. | present: `.flywheel/tests/test_ntm_approve_human_gates.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add top-level flywheel doctor bypass probe |
| `.flywheel/scripts/ntm-audit-receipts.sh` | Canonical-writer and hash-chain audit report over native receipt ledgers. | delete when ntm audit verifies single canonical writer, full hash chain, invalid JSON rows, and writes immutable audit reports. | present: `.flywheel/tests/test_ntm_audit_receipts.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add schema-validator-duo pair and doctor adoption probe |
| `.flywheel/scripts/ntm-policy-contracts.sh` | Privilege-escalation block and warn-only policy contract semantics. | delete when ntm policy validate/audit fail closed on malformed policy, block privileged operations, and expose warn-only gate semantics. | present: `.flywheel/tests/test_ntm_policy_contracts.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add schema-validator-duo pair and doctor adoption probe |
| `.flywheel/scripts/ntm-checkpoint-rollback-guard.sh` | Checkpoint metadata hashes, dirty-worktree scoped exception, rollback stop conditions, and refusal receipts. | delete when ntm checkpoint/rollback supports dirty-worktree-policy=scoped-exception, metadata hash verification, reservation checks, and refusal receipt ledger. | present: `.flywheel/tests/test_ntm_checkpoint_rollback_guard.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | KEEP; add schema-validator-duo pair and doctor adoption probe |
| `.flywheel/scripts/ntm-coordinator-shadow.sh` | Shadow-only coordinator recommendations while ntm#124 blocks daemon auto-assign. | delete when ntm#124 lands and ntm coordinator/assign --watch --auto has safe daemon lifecycle and receipt parity. | present: `.flywheel/tests/test_ntm_coordinator_shadow.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | TRANSITIONAL; high-priority delete/re-audit when upstream condition lands |
| `.flywheel/scripts/ntm-pipeline-shadow.sh` | Dry-run deterministic DAG artifact while native pipeline execution is disabled pending ntm#124. | delete when ntm#124 lands and ntm pipeline dry-run emits deterministic DAG with no live mutation before apply. | present: `.flywheel/tests/test_ntm_pipeline_shadow.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | TRANSITIONAL; high-priority delete/re-audit when upstream condition lands |
| `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh` | Fail-closed secret-class evidence and redacted callback artifact scanning while redact/scrub coverage is partial. | delete when ntm redact/scrub covers SEC fixture classes, sender_token JSON fields, bearer/long token values, and pre-capture token-handle discipline. | present: `.flywheel/tests/test_ntm_scrub_secret_scan_wrapper.sh` | missing in top-level `flywheel doctor`; wrapper has self `doctor` surface | TRANSITIONAL; high-priority delete/re-audit when upstream condition lands |

### Wrapper Notes

- W0A/W1Q/W1M/W1S/W2P/W2D/W2A/W3bA/W3bP/W3bR are justified by explicit `native_wrapper_delta` contracts in their scripts and by `.flywheel/tests/test_*` fixtures. The gap is not unit coverage; it is top-level doctor enforcement that production callsites route through the wrapper.
- W3aC and W3aP are not permanent wrappers. Their own schemas say shadow mode exists until `ntm#124` closes. These are the most deletable wrappers.
- `ntm-scrub-secret-scan-wrapper.sh` was not in the headline WRAP set, but Socraticode/grep found it as a wrapper-shaped surface. It should remain only until the W2 redact/scrub issue closes.
- The four issue-body artifacts found under `/tmp` cover locks, unlock, redact, and work-vs-assign. The expected lock/scrub/review-queue/worktree artifacts were not present under `/tmp` during this audit, so the evidence bundle itself has a coverage gap.

## Part B - Matrix Summary

- Matrix path: `/Users/josh/Developer/flywheel/.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/07-VALIDATION-MATRIX.yaml`
- Matrix entries: 106 inventory rows covering 108 command aliases
- Coverage average: 6.7/10
- Surfaces below 7: 47
- Claimed USE rows with no doctor probe: 25

## Top 5 Wrappers Most Likely Deletable In 30 Days

- `ntm-coordinator-shadow.sh` — delete when ntm#124 closes and native coordinator/assign watch has lifecycle receipts.
- `ntm-pipeline-shadow.sh` — delete when ntm#124 closes and native pipeline dry-run DAG is deterministic.
- `ntm-scrub-secret-scan-wrapper.sh` — delete when ntm redact/scrub covers SEC fixtures plus token-handle discipline.
- `ntm-quota-proactive-probe.sh` — delete when ntm quota emits threshold class and unknown-provider policy.
- `ntm-serve-eventstream-bridge.sh` — delete when ntm serve eventstream binds loopback by default and redacts payloads.

## Top 5 Unmeasured USE Surfaces

- `analytics` — callsites=1 tests=1; add a `flywheel doctor` assertion or downgrade the inventory claim.
- `assign` — callsites=6 tests=5; add a `flywheel doctor` assertion or downgrade the inventory claim.
- `attach` — callsites=0 tests=1; add a `flywheel doctor` assertion or downgrade the inventory claim.
- `bugs` — callsites=1 tests=0; add a `flywheel doctor` assertion or downgrade the inventory claim.
- `checkpoint` — callsites=6 tests=5; add a `flywheel doctor` assertion or downgrade the inventory claim.

## Top 5 Doctor Probes To Add

- `wrapper-adoption probe` — scan dispatch/onboarding scripts for direct native calls that should route through W0-W3b wrappers; fail on bypass.
- `wrapper-selftest aggregate` — run every `.flywheel/tests/test_ntm_*wrapper*.sh` and `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh` in fast fixture mode.
- `issue-gap probe` — assert W2 ISSUE surfaces still have upstream-gap receipts until native parity lands.
- `inventory-vs-help probe` — compare `ntm --help` command list to expanded NTM-SURFACE-INVENTORY aliases and fail on drift.
- `schema-validator-duo probe` — validate `07-VALIDATION-MATRIX.yaml` against a matrix schema plus semantic validator.

## Recommended Follow-Up Beads

- Add `flywheel doctor` wrapper-adoption probe for W0-W3b surfaces.
- Add schema + executable validator for `07-VALIDATION-MATRIX.yaml` using schema-validator-duo.
- File/recover missing W2 issue evidence artifacts for lock, scrub, review-queue, and worktree.
- Delete/re-audit W3aC/W3aP immediately after ntm#124 lands.
- Add inventory-vs-`ntm --help` drift probe to doctor.
- Add negative tests for EXCLUDED surfaces proving flywheel does not script interactive-only commands.
- Add USE-surface doctor probes for high-leverage rows: wait, watch, history, interrupt, health.
- Add bypass tests proving direct native calls do not replace wrappers until tripwires land.
- Promote wrapper test fixtures from `.flywheel/tests` into the main test runner manifest.
- Add a matrix coverage trend receipt so 89% wired can be tracked toward 100% measured.

## Validation Gradient: 89% Wired To 100% Measured

1. Freeze the inventory as executable data: validate the expanded 108 aliases against `ntm --help`.
2. Add a doctor probe for every WRAP tripwire and every ISSUE non-coverage receipt.
3. Require each USE row to have at least one script callsite, one test/fixture, or an explicit no-script-use receipt.
4. Make coverage below 7 a failing planning gate before future wire-in waves close.
5. Delete transitional wrappers as soon as their upstream conditions land, instead of letting shadow surfaces become permanent.

## Four-Lens Self Grade

brand:8,sniff:9,jeff:9,public:8
