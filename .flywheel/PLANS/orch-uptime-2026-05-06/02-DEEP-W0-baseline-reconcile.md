---
title: "W0 Baseline Reconcile Deep Research - 2026-05-06"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# W0 Baseline Reconcile Deep Research - 2026-05-06

Scope: read-only research for W0 before A2 edits the Codex stuck detector.
Primary inputs: `04-BEADS-DAG.md` W0/A2 rows and `03-AUDIT-r1-cross-cutting.md` HIGH-1.
Socraticode: K=10 searches against `/Users/josh/Developer/flywheel`; 100 result chunks observed.

## Verdict

W0 should declare the queued-not-submitted baseline reconciled only from a
mechanical receipt. Current live `br show` is not usable: it returns
`BusySnapshot` on the common active-list index path. The authoritative fallback
is latest append-only row order in `.beads/issues.jsonl`, corroborated by
`INCIDENTS.md` L112.

Current truth from refreshed probes:
- `br show flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06 --json`
  still fails with `DATABASE_ERROR` / `BusySnapshot`.
- `.beads/issues.jsonl` lines 1315, 1317, 1318, 1319 contain open, closed,
  close-event, and verification-event rows for the same id.
- Latest relevant append row is line 1319:
  `event=verification`, `status=closed`, `ts=2026-05-06T12:42:22Z`,
  `l112=OK_codex_queued_not_submitted_wired`,
  `targeted_tests=11/11`, `detector_regression_pass=true`,
  `files_released=true`.
- `INCIDENTS.md:2961-3006` contains the canonical incident and the same L112.

## 1. Status-Truth Probe Sequence

Run this sequence in W0 and record all outputs in a receipt. W0 is read-only
against source and must not repair `br`.

1. Live `br` truth attempt:
   ```bash
   br show flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06 --json
   ```
   Branches:
   - If `status=closed` and no newer reopen row is present, continue to JSONL
     corroboration.
   - If `status=open`, `status=in_progress`, or any explicit reopened marker is
     newer than the 2026-05-06T12:42:22Z verification row, classify
     `reopened_live_br_blocks_A2`.
   - If `DATABASE_ERROR` / `BusySnapshot`, classify `br_unavailable` and fall
     through to append-only truth.

2. JSONL append-only tail:
   ```bash
   rg -n 'flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06' .beads/issues.jsonl
   jq -c 'select(.id=="flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06" or .ref_id=="flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06") | {event,id,ref_id,status,created_at,updated_at,closed_at,ts,l112,detector_regression_pass,targeted_tests,files_released,close_reason,notes}' .beads/issues.jsonl
   ```
   Mechanical rule: latest matching line by file order is authoritative while
   `br` is unavailable. Required latest row: `event=verification`,
   `status=closed`, `l112=OK_codex_queued_not_submitted_wired`,
   `detector_regression_pass=true`, `targeted_tests=11/11`,
   `files_released=true`.

3. Incident/L112 corroboration:
   ```bash
   rg -n 'OK_codex_queued_not_submitted_wired|codex_queued_not_submitted|bare-Enter' INCIDENTS.md
   ```
   Required: incident says detector classifies `codex_queued_not_submitted`,
   bare-Enter primitive shipped, test passed 11/11, and L112 matches.

4. Source baseline probe:
   ```bash
   rg -n 'codex_queued_not_submitted|bare_enter|model_at_capacity_halt|oom_killed_pane|unknown_stable' .flywheel/scripts/codex-template-stuck-detector.sh tests/codex-template-stuck-detector.sh tests/e2e/e2e_oom_classifier.sh
   ```
   Required: detector defines `QUEUED_NOT_SUBMITTED_SUBCLASS`, maps it to
   `bare_enter`, calls `run_queued_bare_enter`, and keeps sibling subclasses
   visible.

5. Decision values:
   - `closed_verified`: live `br` agrees closed and JSONL verifies.
   - `closed_verified_jsonl_fallback`: `br` BusySnapshot, JSONL verifies, and
     INCIDENTS L112 corroborates.
   - `reopened_live_br_blocks_A2`: live `br` has a newer open/reopened truth.
   - `unresolved_blocks_A2`: JSONL lacks the verification row or INCIDENTS L112.

## 2. W0 Acceptance Criteria

W0 may declare `baseline_reconciled=true` only if all are true:
- Receipt schema is `orch-uptime-w0-baseline-reconcile/v1`.
- Receipt records the live `br` probe status and raw failure class if any.
- Receipt records JSONL line numbers 1315, 1317, 1318, 1319 or newer matching
  line numbers if the file grew.
- Latest matching JSONL row is verification+closed with:
  `ts>=2026-05-06T12:42:22Z`,
  `l112=OK_codex_queued_not_submitted_wired`,
  `targeted_tests=11/11`,
  `detector_regression_pass=true`,
  `files_released=true`.
- `INCIDENTS.md` contains the matching L112 and queued-not-submitted incident.
- Detector source still exposes `codex_queued_not_submitted` and routes recovery
  to `bare_enter`, not respawn and not capacity auto-continue.
- Receipt enumerates the regression fixtures in section 3 below.
- Outcome is exactly one of the four decision values above.
- A2 is allowed only for `closed_verified` or
  `closed_verified_jsonl_fallback`.
- If `closed_verified_jsonl_fallback`, receipt must include
  `br_substrate_unavailable=true` and `escape_hatch_used=true`.
- W0 performs no source mutation and holds no long-lived reservation after
  emitting the receipt.

Suggested receipt path:
`~/.local/state/flywheel/orch-uptime/w0-a2-baseline-reconcile-receipt.json`.

## 3. Fixtures A2 Must Not Regress

From `tests/codex-template-stuck-detector.sh`:
- Syntax and Enter retry argv order:
  `[ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", "\n"]`.
- Doctor bootstrap contract:
  `schema_version=codex-stuck-detector.doctor.v1`,
  `codex_template_stuck_count_24h=0`, contract self-row appended.
- `buffer_stuck`: stable template prompt returns rc=1,
  subclass `buffer_stuck`, hash stable, recovery
  `enter_newline_then_respawn_if_still_stuck`.
- `model_at_capacity_halt`: capacity fixture returns rc=1, hash stable,
  recovery `auto_continue`.
- Capacity auto-recover invokes the capacity primitive and passes
  `--session flywheel --pane 4 --digest`.
- `please try a different model` remains `model_at_capacity_halt` with
  `auto_continue`.
- Bare chevron alone remains `alive` with recovery `none`, not capacity.
- `post_completion` remains no auto-recover and recommends
  `/flywheel:respawn_after_snapshot`.
- Moving output remains `alive`, `status=ok`, `stuck_count=0`,
  `hash_stable=false`.
- `input_deaf` after failed Enter retry remains `input_deaf`, logs
  `codex-input-deaf` / `flywheel-mk303`, and recommends
  `/flywheel:respawn_after_peer_orch_recovery_gate`.
- Apply ledger count remains 4; doctor-after reports stuck count 3 and
  recovery success pct 50; fixture validation remains ok; total fixture result
  remains `7/7`.

From `tests/e2e/e2e_oom_classifier.sh`:
- Capacity-halt fixture remains `model_at_capacity_halt` / `auto_continue`.
- Queued-not-submitted JSON hint remains `codex_queued_not_submitted` /
  `bare_enter`.
- Buffer JSON hint remains `buffer_stuck` /
  `enter_newline_then_respawn_if_still_stuck`.
- OOM directory fixture remains `oom_killed_pane` / `respawn`.
- OOM subclass hint remains `oom_killed_pane` / `respawn`.
- OOM regex-only signature remains `oom_killed_pane` / `respawn`.
- Final sweep remains: all 4 subclasses classified, no regression.

## 4. W0 -> A2 Lock and Coordination Shape

Use one semantic detector lock, not pane-local convention:
`~/.local/state/flywheel/orch-uptime/w0-a2-detector-baseline.lock`.

Lock owner JSON fields:
`schema_version`, `owner`, `session`, `pane`, `task_id`, `phase`,
`acquired_at`, `expires_at`, `paths`, `depends_on`, `idempotency_key`,
`receipt_path`.

Serialized path set for A2:
- `.flywheel/scripts/codex-template-stuck-detector.sh`
- `tests/codex-template-stuck-detector.sh`
- `tests/e2e/e2e_oom_classifier.sh`
- Any new usage-limit fixture/test file A2 authors.

Coordination rule:
- W0 acquires only the semantic coordination lock long enough to write the
  receipt, then releases.
- A2 must acquire the same lock plus L51/L107 reservations for the serialized
  path set before edits.
- A2 must refuse to edit if the W0 receipt is missing, stale, not one of the two
  allowed decisions, or does not name all regression fixtures above.
- If W0 reports `reopened_live_br_blocks_A2`, queued-not-submitted owner goes
  first and usage-limit waits.

## 5. Escape Hatch for Indefinite BusySnapshot

If `br` remains BusySnapshot:
- Do not block W0 or A2 indefinitely on the DB substrate alone.
- Use `closed_verified_jsonl_fallback` only when JSONL latest row and INCIDENTS
  L112 both satisfy section 2.
- Treat this as permission for detector work, not as permission to mutate bead
  state through `br`.
- File or route separate br substrate repair work outside W0/A2 if not already
  tracked; do not combine DB repair with the detector semantic edit.
- If JSONL and INCIDENTS disagree, or JSONL latest row is not verification
  closed, fail closed with `unresolved_blocks_A2`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
