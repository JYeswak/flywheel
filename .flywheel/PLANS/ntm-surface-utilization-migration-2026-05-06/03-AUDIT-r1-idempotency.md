# 03-AUDIT-r1 - Idempotency + Replay Safety

Task: `ntm-surface-migration-audit-idempotency-r1-2026-05-06`  
Plan: `.flywheel/plans/ntm-surface-utilization-migration-2026-05-06/00-PLAN.md`  
Mode: read-only audit; only this artifact written.  
L112: `OK_ntm_surface_migration_audit_idempotency_r1`

## Skills Library Cited

- `ntm`: native command semantics, robot idempotency contract, checkpoint/rollback/pipeline/control surfaces.
- `dispatch-tool-contracts`: callbacks are executable proof envelopes; K is per-query limit, Q is query count.
- `canonical-cli-scoping`: wrappers must expose stable JSON, dry-run/explain for mutating paths, and deterministic exit semantics.
- `migration-architect` / `safe-migrations`: expand-contract, reversible cutover, rollback guarded by stop conditions.
- `beads-workflow`: bead IDs, dependency closure, `br_close_executed` ordering, and replay-safe callback receipts.
- `codebase-audit`: severity register with evidence-first findings.
- `socraticode`: 6 searches with K=10; indexed chunks observed: flywheel=989, ntm=31740.

`skills_library_gap=none`

## Evidence Base

- Plan inputs read: `00-PLAN.md`, `01-RESEARCH-A.md`, `01-RESEARCH-B.md`, `01-RESEARCH-C.md`.
- Idempotency substrate read: `.flywheel/scripts/append-safe-write.sh`, `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`, `.flywheel/scripts/idempotency-replay-guard.sh`, `.flywheel/tests/test_idempotency_replay_guard.sh`.
- Coordination substrate sampled: `~/.local/state/flywheel/cross-orch-coordination.jsonl` rows with `dedupe_key` but no shared transaction lock visible at row layer.
- Reference pattern: orch-uptime runbook uses callback fields and idempotency TTL patterns but is not inherited automatically by this plan.
- NTM source inspected: `/Users/josh/Developer/ntm/internal/cli/*`, `/Users/josh/Developer/ntm/internal/approval/engine.go`, `/Users/josh/Developer/ntm/internal/checkpoint/*`, `/Users/josh/Developer/ntm/internal/pipeline/*`, `/Users/josh/Developer/ntm/docs/robot-request-identity.md`.

## Per-Bead Idempotency Token Inventory

Required scheme for every implementation dispatch callback:
`idempotency_key=sha256(plan_slug|repo|bead_id|wave|dispatch_task_id)`.
The callback should run `.flywheel/scripts/idempotency-replay-guard.sh --input <packet-or-canonical-json>` before work starts, and `--mark-completed --receipt-ref <close-row-or-report>` before `ntm send DONE`.

| ID | Bead ID | Token present in plan? | Current scheme | Audit verdict |
|---|---|---|---|---|
| W0T | `flywheel-ntm-migrate-w0-skillos-orthogonal-trio-2026-05-06` | No | none | GAP: callback can double-fire with no duplicate close guard. |
| W0A | `flywheel-ntm-migrate-w0-a1-rotate-wrapper-conformance-2026-05-06` | No | primitive has CAAM `identity_key`/`idempotency_key`; bead callback lacks one | GAP: internal wrapper dedup does not dedupe bead close/callback. |
| W1Q | `flywheel-ntm-migrate-w1-quota-proactive-2026-05-06` | No | none | GAP: read-only probe result can be logged twice as separate close evidence. |
| W1M | `flywheel-ntm-migrate-w1-metrics-doctor-2026-05-06` | No | none | GAP: doctor/closeout counter writes need replay key. |
| W1S | `flywheel-ntm-migrate-w1-serve-eventstream-2026-05-06` | No | none | GAP: daemon pilot start/stop receipt needs process idempotency key. |
| W2S | `flywheel-ntm-migrate-w2-scrub-secret-scan-2026-05-06` | No | none | GAP: scrub finding rows can duplicate. |
| W2P | `flywheel-ntm-migrate-w2-preflight-l91-wrapper-2026-05-06` | No | `ntm preflight` emits `preview_hash`, not a persisted close key | GAP: L91 wrapper needs dispatch-level replay key. |
| W2D | `flywheel-ntm-migrate-w2-safety-dcg-sibling-2026-05-06` | No | none | GAP: divergence-policy rows can double append. |
| W2A | `flywheel-ntm-migrate-w2-approve-human-gates-2026-05-06` | No | native approval token has 24h expiry, no callback key | GAP: approval decision and bead callback need distinct dedup keys. |
| W3aC | `flywheel-ntm-migrate-w3a-coordinator-shadow-2026-05-06` | No | none | GAP: coordinator shadow recommendations need stable row identity. |
| W3aP | `flywheel-ntm-migrate-w3a-pipeline-shadow-2026-05-06` | No | native pipeline run id is timestamp+random | GAP: retries create new runs unless wrapper blocks duplicate. |
| W3bA | `flywheel-ntm-migrate-w3b-audit-receipts-2026-05-06` | No | native audit appends transactional rows, no dedup key | GAP: receipt writer must dedupe by identity. |
| W3bP | `flywheel-ntm-migrate-w3b-policy-contracts-2026-05-06` | No | config hash possible but not specified | GAP: policy apply/receipt rows need stable key. |
| W3bR | `flywheel-ntm-migrate-w3b-checkpoint-rollback-2026-05-06` | No | checkpoint id is timestamp+random | GAP: repeated save/rollback can create new state. |
| W4T | `flywheel-ntm-migrate-w4-unaware-triage-2026-05-06` | No | none | GAP: triage artifact and any new no-fit rows need stable key. |

`idempotency_token_gap_count=15`

## Native Primitive Idempotency Matrix

| ntm command | Native side effect class | Built-in dedup? | TTL / lifetime | Matches workaround? | Wrapper requirement |
|---|---|---|---|---|---|
| `quota` | read-only pane `/usage` query | read-only only | n/a | partial | Add freshness max-age; no replay TTL needed unless logging result. |
| `metrics` | read-only metrics/snapshot/export | read-only only | n/a | partial | Dedupe any doctor/closeout rows that consume it. |
| `serve` | long-running REST/SSE daemon | No; port bind failure is collision, not dedup | process lifetime | No | Add PID/port lock, health probe, and stop receipt identity. |
| `preflight` | read-only prompt analysis | No persisted dedup; emits `preview_hash` | n/a | partial | Persist dispatch replay key separately; hash alone is not close proof. |
| `scrub` | read-only redaction scan | read-only only | n/a | partial | Dedupe finding rows by scanned path + hash + rule version. |
| `safety` | `check` read-only; `install` mutates wrappers | install refuses existing files unless `--force` | file existence, no TTL | partial | For install/apply paths require idempotency key and no `--force` in workers. |
| `approve` | approval decision mutation | No replay-success; second approve errors once not pending | default pending expiry 24h | No | Separate approval token from bead callback key; duplicate callback returns prior receipt. |
| `coordinator` | assign can send work; status/digest read-only | dry-run only; apply has no dedup key | n/a | No | Shadow mode only until row identity and Agent Mail reservation parity exist. |
| `pipeline` | run creates workflow state and dispatches steps | No; run id generated timestamp+random, no CLI run-id flag | state persists until cleanup `--older` | No | Wrapper ledger must refuse duplicate run for same bead/wave. |
| `audit` | verify/export read-only; record path appends DB rows | DB transaction yes; semantic dedup no | retention, not dedup TTL | partial | Add `identity_key` for flywheel receipts and duplicate-as-success behavior. |
| `policy` | validate/show read-only; automation/reset/edit writes config | Same values may rewrite; no receipt dedup | config lifetime | partial | Use config hash skip + idempotent receipt before gate mode. |
| `checkpoint` | save creates checkpoint artifact | No; ID is timestamp+random | indefinite until delete/cleanup | No | Save once per bead key; verify existing checkpoint before new save. |
| `rollback` | interrupts agents, stashes, checkout, applies patch | No; repeated apply can create new stash/interrupt/patch attempts | n/a | No | Require prior rollback receipt, stop if already at checkpoint commit, max attempts. |

## TTL Mismatch List

1. `caam-auto-rotate` has `ttl_sec=3600`; native robot idempotency docs offer `persistent=24h`. W0A must keep the wrapper's 1h duplicate window unless the plan explicitly changes it.
2. Native approvals expire after 24h by default. Dispatch/bead callback replay should live until close receipt, not until approval expiry.
3. `append-safe-write` has a short lease (`--lease-ms` default 300) and 4KB readback; that is write-race protection, not replay TTL. It must be paired with `--idempotency-key`.
4. `pipeline cleanup --older` is retention cleanup, not duplicate-run TTL. W3aP needs a deterministic run ledger.
5. `checkpoint save` has no dry-run flag and generates a fresh timestamp/random ID. W3bR needs an external "checkpoint already saved for bead" key.

`ttl_mismatch_count=5`

## Receipt Double-Write Risk - W3b

Verdict: `receipt_double_write_risk=yes`.

Native NTM uses mutex/DB transactions for internal state and audit insertion, but W3b also writes flywheel receipts, policy ledgers, checkpoint metadata, and rollback receipts. Those are separate JSONL/file surfaces. Two workers can therefore produce valid native rows while racing flywheel row order unless W3b mandates:

- one canonical flywheel receipt writer per target ledger,
- `.flywheel/scripts/append-safe-write.sh --idempotency-key <key>` for JSONL append surfaces,
- `idempotency-replay-guard.sh` begin/commit/abort rows for each bead,
- duplicate-as-success semantics naming `duplicate_of_sequence_num` or `prior_receipt_ref`.

Without that, "native audit verified" and "flywheel receipt canonical" can diverge.

## Rollback Stop-Condition Completeness

Verdict: incomplete.

The plan requires dry-run, clean worktree postcheck, dirty-path refusal, and "refuse rollback execution" rollback path. It does not enumerate:

- stop if current git commit already equals checkpoint commit and prior rollback receipt exists,
- stop after `N` failed apply attempts with `rollback_attempts_exhausted`,
- stop if a prior attempt created a stash for the same rollback key,
- stop if checkpoint id is missing or was superseded by a newer checkpoint,
- stop if Agent Mail reservations for touched files are absent,
- stop if W3bP policy gate is stale or warn-only.

Required W3bR amendment: `max_attempts=1` for workers, `max_attempts=2` only under orchestrator-owned recovery, then halt and file a fix bead.

## Polish-Replay Idempotency

Verdict: not guaranteed.

The plan has no Phase 5 polish replay schema for these 15 bead bodies. Prior flywheel polish used append-only JSONL rounds with body hashes and convergence percentages. This plan should require:

- `polish_identity_key=sha256(plan_slug|bead_id|round|input_body_hash)`,
- no-op when the same round/input hash is seen,
- append-only polish event with `before_hash`, `after_hash`, and `diff_pct`,
- reversible `supersedes_polish_key` row for correction,
- no edits that rename bead IDs, remove dependencies, or split grouped W3b without Phase 4 DAG update.

Non-reversible patterns to forbid: destructive body replacement without `before_hash`, unordered acceptance rewrites that churn every round, and dependency edits during polish.

## Cross-Bead Replay

The DAG dependencies are correct at plan level, but dispatch packets need executable wait gates:

- W1M waits for W1Q L112 receipt and quota evidence path.
- W1S waits for W1M doctor counters.
- W2 chain waits on each predecessor's callback receipt, not just Beads status.
- W3aC/W3bA wait for W1S + W2A evidence paths.
- W3bR waits for W3bP policy receipt and W3aP pipeline shadow receipt.
- W4T waits for W3aP and W3bR receipt refs plus no in-flight replay locks.

Orthogonal W0 beads can rerun independently, but downstream beads need artifact-bound gates to avoid consuming stale or duplicate upstream state.

## Findings Register

| ID | Severity | Finding | Required amendment |
|---|---|---|---|
| IDEM-H1 | high | All 15 beads lack deterministic callback idempotency tokens. | Add callback key schema + replay guard begin/commit/abort to every bead template. |
| IDEM-H2 | high | W3b double-write risk spans native DB/audit plus flywheel JSONL/file receipts. | Mandate one canonical writer and append-safe idempotency key for every ledger row. |
| IDEM-H3 | high | Rollback repeated-apply stop conditions are incomplete. | Add already-at-checkpoint, prior-stash, max-attempt, reservation, and policy freshness stops. |
| IDEM-M1 | medium | Native mutating commands mostly lack CLI idempotency flags despite robot docs. | Treat native idempotency as absent unless command exposes an idempotency key. |
| IDEM-M2 | medium | W3b checkpoint plan references dry-run expectations, but `ntm checkpoint save` has no `--dry-run`. | Use verify/show/list for preview or wrap save behind replay guard. |
| IDEM-M3 | medium | TTL semantics differ: CAAM 1h, approvals 24h, append lease 300ms, pipeline/checkpoint indefinite. | Declare per-command TTL in dispatch packets and receipts. |
| IDEM-M4 | medium | Phase 5 polish replay is unspecified for 15 bead bodies. | Add polish identity key, body hashes, and duplicate no-op rule. |
| IDEM-L1 | low | Read-only probes are idempotent by nature but can still duplicate downstream receipts. | Dedupe the receipt, not the read-only probe. |

Counts: `critical=0`, `high=3`, `medium=4`, `low=1`.

## Convergence Verdict

Verdict: `needs_r2_focus`

R2 focus topic: `deterministic_callback_tokens_and_w3b_replay_guard`.

The plan shape is converged, but it is not replay-safe enough to ship as-is. A narrow r2 amendment can preserve the 15-bead DAG: add a universal callback idempotency field, wire `idempotency-replay-guard.sh`, and specialize W3b checkpoint/rollback receipt stops.

## Three-Judges Sniff

| Judge | Score | Read |
|---|---:|---|
| Jeff | 7/10 | Native-first plan is good, but write commands need explicit keys instead of assuming native safety. |
| Donella | 8/10 | Correctly sees replay as a feedback-loop issue; W3b must prevent reinforcing duplicate state. |
| Joshua | 7/10 | Shippable after a small r2 amendment; not acceptable to rely on prose "dry-run" around rollback. |

Self-grade: `8.4/10`

Mission-anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
