# C3 Wire-Or-Explain Bootstrap Deep Research

Date: 2026-05-06
Repo: /Users/josh/Developer/flywheel
Mode: read-only research
Socraticode: K=10, projectPath=/Users/josh/Developer/flywheel, minScore=0

## Verdict

C3 should bootstrap the WOE ledger as a scoped substrate repair, not as a new
global tick-close stop. Missing ledger may warn during bootstrap/shadow. It
should hard-fail only when the claim being closed is a WOE-drain/bootstrap
claim, or when enforce mode has unresolved local rows that already exist in
the ledger.

## Sources Read

- .flywheel/plans/orch-uptime-2026-05-06/01-RESEARCH-C.md, section
  "Wire-Or-Explain Rows"
- .flywheel/plans/orch-uptime-2026-05-06/03-AUDIT-r1-paradigm.md, F5 amendment
- .flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json
- .flywheel/scripts/wire-or-explain-ledger-writer.sh
- .flywheel/scripts/wire_or_explain_ledger_writer.py
- .flywheel/scripts/wire-or-explain-close-gate.py
- ~/.claude/skills/.flywheel/bin/flywheel-loop, wire_or_explain_doctor_json
- tests/wire-or-explain-ledger.sh, tests/wire-or-explain-close-gate.sh,
  tests/wire-or-explain-doctor.sh, fault-injection FM5 fixtures

## WOE Ledger Schema

Canonical ledger:
/Users/josh/.local/state/flywheel/wire-or-explain-ledger.jsonl

Writer wrapper:
.flywheel/scripts/wire-or-explain-ledger-writer.sh

Writer Python fills or enforces:
- schema_name = flywheel.wire-or-explain.v1
- schema_version = wire-or-explain-ledger/v1
- timestamp default now UTC
- stock default wire-or-explain
- inflow default event_type
- action_ledger default ledger path
- identity_key computed from:
  session_id, event_type, actor, target, subject, predicate, artifact_class,
  branch_ref, git_ref
- metadata.idempotency_key when --idempotency-key is supplied
- sequence_num, prev_hash, checksum at append time
- duplicate detection by identity_key, returning status=duplicate with no write

Required row fields:
schema_name, schema_version, identity_key, timestamp, session_id, event_type,
actor, target, payload, metadata, prev_hash, checksum, sequence_num, state,
producer, owner, consumer, blocking_scope, owning_orch, ship_repo, ship_actor,
artifact_class, subject, predicate, branch_ref, git_ref, reset_intent_hash,
deferral_owner, deferral_until, auto_fire_trigger, drain_receipt_shape,
verification_probe, tick_status_consequence, stock, inflow, action_ledger.

State enum:
wired, deferred, unwired, questionably_wired, not_required, bypassed.

Artifact class enum:
finding, dispatch_packet, bead, callback, worker_branch, skill_candidate,
ledger_rebuild, other.

Schema constraints:
- additionalProperties=false
- state=wired requires payload.evidence_output_hash
- state=deferred or consumer=NONE requires non-empty deferral_owner and
  deferral_until
- artifact_class=worker_branch requires non-empty branch_ref, git_ref, and
  reset_intent_hash

Writer doctor:
writer doctor delegates to the chain verifier and reports The Zest Ledger
health. Missing ledger verifies as pass/row_count=0 at the chain layer.

Flywheel doctor:
flywheel-loop doctor --scope wire-or-explain emits wire-or-explain-doctor/v1.
If the ledger is missing or empty, bootstrap/shadow status is warn, enforce
status is error with auto_bead_promotion_trigger.enabled=true. Existing rows
are reduced into counts_by_state, unresolved_count, overdue_count,
questionably_wired_count, skill relay fields, and redacted top_actions. Payload
and metadata are not emitted in top_actions.

Close gate:
.flywheel/scripts/wire-or-explain-close-gate.py treats state in
{unwired, questionably_wired} as unresolved. A row is local when ship_repo is
the repo realpath, session_id equals the session, or owning_orch starts with
the session/pane prefix. In shadow, unresolved local rows are allowed with
reason shadow_unresolved_local_rows. In enforce, unresolved local rows block
with exit 1, or exit 4 for blocking_scope=fleet. Cross-orch rows warn only.

## Bootstrap Row Base Shape

Use the existing writer; do not hand-append JSONL. Each production write should
have one deterministic identity and one idempotency key:

identity_key: orch-uptime-c3:<bead_id>
idempotency_key: orch-uptime-c3-woe-bootstrap:2026-05-06:<bead_id>

Input row fields before writer materialization:
- session_id: flywheel
- event_type: orch_uptime_c3_bootstrap
- actor: c3-woe-bootstrap-deep-research
- target: <bead_id>
- payload: {bead_id, priority, latest_status, source_plan, relationship,
  disposition, evidence_notes}
- metadata: {bootstrap:true, source:"01-RESEARCH-C Wire-Or-Explain Rows",
  f5_scope:"scoped_not_global"}
- state: unwired | questionably_wired | wired | not_required
- producer: orch-uptime-c3-bootstrap
- owner: flywheel:1
- consumer: <specific drain owner below>
- blocking_scope: woe_claim | tick | local | none
- owning_orch: flywheel:pane-1
- ship_repo: /Users/josh/Developer/flywheel
- ship_actor: flywheel:1
- artifact_class: bead
- subject: <bead_id>: <short title>
- predicate: needs_bootstrap_wire_or_explain_disposition
- branch_ref, git_ref, reset_intent_hash: null
- deferral_owner, deferral_until: null unless consumer=NONE/state=deferred
- auto_fire_trigger: on_c3_bootstrap_dispatch
- drain_receipt_shape: writer_receipt + close_gate_shadow_receipt +
  consumer-specific proof
- verification_probe: <mechanical probe below>
- tick_status_consequence: <scoped consequence below>

Note: writer --dry-run is intent-only and returns before validation. For a real
bootstrap dispatch, prove schema with a temp-ledger append plus verifier before
writing the production ledger with the same idempotency keys.

## Bootstrap Rows for 11 P0/P1 Beads

| bead | pri/status observed | bootstrap state | consumer route | scope | verification_probe | consequence |
|---|---|---|---|---|---|---|
| flywheel-pp1g | P1 in_progress | questionably_wired | L87-sunset-review | woe_claim | br show flywheel-pp1g --json; test L87 stale-error ping proof | Blocks L87 sunset claim only |
| flywheel-3iz0 | P0 open | unwired | wire-or-explain-ledger-writer | woe_claim | writer temp-ledger append; chain verifier; close gate shadow receipt | Blocks C3/WOE bootstrap close only |
| flywheel-2x5yi | P0 open | questionably_wired | flywheel-watchers-doctor | local | watcher CLI status/on/off plist probe | Warn for A/B runtime; blocks watcher CLI claim |
| flywheel-25om8 | P0 in_progress | unwired | loop-telemetry-doctor | tick | flywheel-loop doctor --scope tick-driver --json plus telemetry convergence probe | Blocks telemetry convergence claim |
| flywheel-5ktd.2 | P0 open | unwired | pane-work-signal-helper-tests | local | rg pane-work-signal; run matching parser tests once present | Warn until parser proof exists |
| flywheel-5ktd.3 | P0 open | unwired | dispatch-capacity-truth-gate | tick | dispatch-capacity receipt/doctor probe | Blocks dispatch-capacity truth claim |
| flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd | P0 open | unwired | memory-rule-gate-parity-detector | tick | codex stuck-detector/model-at-capacity fixture test | Blocks halt-class shipped claim |
| flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06 | P0 table open; latest bead closed | questionably_wired until evidence hash is backfilled | wire-or-explain-backfill | woe_claim | queued-not-submitted classifier/recovery test plus close evidence hash | No runtime block; backfill close evidence |
| flywheel-viux | P1 in_progress | unwired | idle-state-probe-doctor | tick | idle-state-class doctor signal probe | Blocks idle-state doctor claim |
| flywheel-zidg | P1 open | unwired | dispatch-pre-send-validator | tick | NTM-only pane-state read gate test | Blocks pane-state enforcement claim |
| flywheel-1255t | P1 open | unwired | callback-overdue-circuit-breaker | local | callback overdue fixture/probe; coalescing receipt | Warn for unrelated ticks; blocks circuit-breaker claim |

## F5 Scoped-vs-Global Blocker Semantics

F5 says WOE bootstrap is scoped, not a global close gate. Applying it:
- Missing ledger in bootstrap/shadow: emit woe_ledger_missing_warn and route
  the C3/bootstrap bead.
- Missing ledger in enforce while closing WOE-drain/C3 claims: hard fail and
  trigger auto-bead promotion.
- Missing ledger while doing unrelated Lane A/B runtime work: warn only; do not
  stop uptime progress.
- Existing unresolved local rows may block in enforce according to their
  blocking_scope, but rows outside the local owner remain cross_orch warnings.
- FM5 bootstrap recursion closes only with bounded bootstrap proof/override,
  not by silently disabling the gate.

Suggested scopes:
- woe_claim: hard block only for WOE bootstrap/drain/close claims.
- tick: may block specific tick-close only when unresolved local rows exist and
  enforce mode is intentionally active.
- local: route/warn for ordering and ownership; no fleet stop.
- none: explicitly not required or already retired.

## Closeout Receipt Pattern Confirmed

Default receipt directory from close gate:
/Users/josh/.local/state/flywheel/wire-or-explain/closeout-receipts

Observed receipt:
/Users/josh/.local/state/flywheel/wire-or-explain/closeout-receipts/20260506T203528.755652Z.json

Pattern:
- non-dry-run close gate writes one JSON receipt per invocation
- filename is generated_at with '-' and ':' removed, '+00:00' normalized to Z
- schema_version is tick-close-receipt/v1
- missing ledger receipts can still be allowed=true with warnings containing
  code=ledger_missing
- dry-run sets receipt_written=false and receipt_path=null

Observed receipt content class:
mode=shadow, allowed=true, row_count=0, unresolved_count=0, would_block=false,
warnings[0].code=ledger_missing, ledger_path=/Users/josh/.local/state/flywheel/wire-or-explain-ledger.jsonl.

## Bootstrap Dispatch Shape

Dispatch name: c3-woe-bootstrap-write

Required sequence:
1. Generate 11 row JSON files under a temp directory from the table above.
2. For each row, append to a temp ledger with the real writer and the exact
   idempotency key; run wire-or-explain-chain-verifier on the temp ledger.
3. Run close gate in shadow/bootstrap against the temp ledger and capture the
   receipt path.
4. Only after temp proof, append each row to the production ledger with the same
   idempotency key. Duplicate status is success for reruns.
5. Run writer doctor and close gate shadow on the production ledger.
6. Route each row to its consumer owner; C3/flywheel:1 owns dispatch and
   coordination, consumer fields own drain work.

Idempotency:
- identity_key is deterministic per bead.
- writer duplicate detection by identity_key makes repeated dispatch safe.
- metadata.idempotency_key gives receipt-level auditability.
- production append never uses shell redirection; it uses the writer.

Owner routing:
- owning_orch=flywheel:pane-1 and ship_repo=/Users/josh/Developer/flywheel for
  all 11 bootstrap rows.
- owner=flywheel:1 for coordination.
- consumer is the specific drain route in the row table.
- consumer=NONE is not needed for these rows. If used later, state must be
  deferred with deferral_owner and deferral_until populated.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
