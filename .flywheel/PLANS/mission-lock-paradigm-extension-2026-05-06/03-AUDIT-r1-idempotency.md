# Phase 3 Audit r1: Idempotency Receipt Integrity

task_id: phase3-audit-idempotency-receipt-integrity-2026-05-06
parent_bead: flywheel-plan-mission-lock-paradigm-extension-2026-05-06
lens: idempotency-receipt-integrity
auditor: ScarletDog
created_at: 2026-05-06T14:31:00Z
scope: plan-space-only
socraticode_queries: 10
indexed_chunks_observed: 100

## Lens Scope

This lens inspected the r4 mission-lock paradigm extension for replay safety,
receipt completeness, deterministic routing, and append-only coordination.
The audit reads r4 as the canonical Phase 3 entry artifact and uses r1-r3 only
where r4 explicitly preserves their three-gate contract.

Inspected sections:

- r4 lines 30-39: convergence metadata, audit lens naming, and JSONL closeout.
- r4 lines 52-86: stability confirmation that r3 remains controlling.
- r4 lines 98-106: deferred `skill_receipts[]`, alias, and skip receipt field
  names.
- r4 lines 136-154: Phase 3 audit lens entry conditions.
- r1 lines 151-202: close-validator joins dispatch, callback, and independent
  evidence before accepting DONE.
- r1 lines 231-311: scaffold validator and readiness doctor receipt shapes.
- r1 lines 315-349: cross-gate metadata vocabulary and fail-closed chain.
- r2 lines 73-188: dispatch-author skill routing sequence, discovery receipt,
  and self-test gate.
- r3 lines 72-85: resolved skill receipt semantics, alias receipts, minimal mode,
  and missing-skill routing.
- r3 lines 170-179: Phase 3 should test skill receipt proof shape and leaves
  exact implementation field names deferred.

Out of scope: executing security lens 1, executing cross-cutting lens 3,
modifying r4 or earlier refine artifacts, changing code-space, propagating to
peer repos, or promoting L-rules.

## Findings Register

| ID | Severity | Section line range | Description | Mitigation proposal |
|---|---:|---|---|---|
| IDEM-001 | high | r4:140-146; r2:79-91,147-164 | Dispatch-author can recompute a valid packet and send it again, but the plan does not require a deterministic dispatch `identity_key`, input hash, prior-send lookup, or four-state delivery receipt in the skill discovery receipt. Repeat execution can create duplicate dispatches rather than proving "already sent." | R5 or Phase 4 should add `dispatch_identity_key`, `source_bead_hash`, `packet_hash`, `target_session_pane`, `delivery_receipt_id`, and `previous_dispatch_log_row` to the dispatch-author receipt; send is allowed only when no matching live/completed identity exists. |
| IDEM-002 | medium | r4:100-103; r3:81-83,178-179 | Skill receipts, alias receipts, and minimal-mode skip receipts have fixed semantics but no canonical field names or schema version. Close replay cannot reliably compare "same skill was applied/skipped for same reason" across repeated runs. | Finalize `skill_receipts[]` schema before code-space close-validator work: `skill`, `source`, `source_version`, `action_taken`, `evidence`, `alias_of`, `not_applicable_reason`, `receipt_identity_key`, and `policy_version`. |
| IDEM-003 | medium | r4:145-146; r2:94-188; r3:76-85 | Skill-suite computation depends on live skill catalog, skill-search route health, aliases, bead labels, touched files, mission surfaces, and Socraticode hits, but the receipt lacks catalog snapshot hashes and input hashes. The same bead+context replay can select a different suite after catalog drift. | Add deterministic routing inputs: `bead_identity_hash`, `labels_hash`, `touched_files_hash`, `mission_surfaces_hash`, `skill_catalog_snapshot_hash`, `alias_registry_version`, and `socraticode_query_set_hash`. |
| IDEM-004 | medium | r4:36-39,136-154; STATE.json audit fields | Parallel audit lenses update one `STATE.json` via read-current/write-update. Without `state_observed_sha`, per-lens append rows, or a merge rule, lens 2 or 3 can clobber sibling `audit_findings_*` data while still satisfying its local L112. | Treat per-lens completion as append-only truth: write a lens row keyed by lens name, record `state_observed_sha`, then derive/merge `audit_lenses_complete` and `audit_findings_by_lens` preserving existing lens keys. |
| IDEM-005 | medium | r4:39,145; r1:143-147; JSONL close rows | JSONL and INCIDENTS closeouts are append-only, but the plan does not require duplicate close detection or a latest-row reconciliation key. Re-running close can append duplicate "closed" truth, which known Phase 2 inventory incidents show is hard to audit later. | Add `close_identity_key`, `close_path_source`, `previous_close_row`, `closure_reconciliation_via`, and `dedupe_policy=latest-row-by-ref_id-event` to JSONL close receipts and INCIDENTS close evidence. |
| IDEM-006 | low | r1:231-311; r1:331-349 | Mission-lock scaffold/readiness doctors are read-only by default and mention apply with an idempotency key, but their proposed receipt shapes do not include lock hashes, section hashes, or previous receipt refs. Repair replay could be safe in implementation, but the plan does not yet prove it. | Add `mission_lock_hash`, `required_sections_hash`, `validator_schema_version`, `prior_receipt_ref`, and `repair_idempotency_key` to readiness/scaffold receipts before enabling apply mode. |

findings_count: 6
critical: 0
high: 1
medium: 4
low: 1

## Idempotency Violations

Plan-space violations found:

1. Dispatch-author replay can resend a packet because r2 requires "send packet
   only if gate passes" but not "send only if this deterministic dispatch
   identity is absent."
2. Skill-suite replay can drift because live catalog and alias state are inputs,
   while the receipt captures counts and selected names but not a catalog or
   alias snapshot identity.
3. Close-validator replay cannot prove equivalence until `skill_receipts[]`,
   alias receipts, and minimal-mode skip receipts have canonical schema fields.
4. Parallel audit lens completion can race in `STATE.json` because the plan has
   a shared mutable summary file and no state-version merge receipt.
5. JSONL fallback close replay can append duplicate closed rows without an
   explicit duplicate-close identity or latest-row reconciliation rule.

No mission-lock primitive was found that must mutate runtime code or external
service state during this plan-space audit. The violations are receipt and
coordination shape gaps, not implementation-side destructive effects.

## Receipt Gaps

Missing fields for safe replay detection:

- Dispatch-author: `dispatch_identity_key`, `source_bead_hash`, `packet_hash`,
  `target_session_pane`, `send_attempt`, `delivery_receipt_id`,
  `previous_dispatch_log_row`, and `dispatch_log_identity_key`.
- Skill routing: `bead_identity_hash`, `labels_hash`, `touched_files_hash`,
  `mission_surfaces_hash`, `skill_catalog_snapshot_hash`,
  `alias_registry_version`, `socraticode_query_set_hash`, and `route_policy`.
- Skill receipts: `schema_version`, `receipt_identity_key`, `source_version`,
  `action_taken`, `evidence`, `alias_of`, `not_applicable_reason`, and
  `policy_version`.
- Minimal mode: `skill_floor_mode`, `collapsed_skip_reason`,
  `universal_skill_tokens_covered`, `domain_skill_selected`, and
  `minimal_mode_policy_version`.
- Close receipts: `close_identity_key`, `close_path_source`,
  `previous_close_row`, `dedupe_policy`, `l112_command_hash`, and
  `l112_observed_at`.
- Mission-lock/readiness: `mission_lock_hash`, `required_sections_hash`,
  `validator_schema_version`, `prior_receipt_ref`, and
  `repair_idempotency_key`.
- STATE coordination: `state_observed_sha`, `state_written_sha`,
  `audit_lens_identity_key`, and `preserved_lenses`.

## Race Windows

Identified race windows:

1. Skill catalog read -> packet render -> send: catalog or alias registry can
   change between selection and packet delivery unless the selected snapshot is
   named in the receipt.
2. Dispatch self-test pass -> NTM send: a second dispatcher can make the same
   send decision before either row is visible without a dispatch identity key.
3. Audit lens STATE update: lens workers read the same `STATE.json`, compute
   their local update, then write; stale writers can drop sibling lens fields.
4. Close-validator evidence read -> supplement bead/close row append: another
   validator can append a duplicate supplement or close event without a close
   identity key.
5. JSONL close append -> INCIDENTS append: partial close evidence can exist in
   one surface but not the other if a worker is interrupted between appends.

Race windows not found:

- The plan does not require non-append mutation of `.beads/issues.jsonl` or
  INCIDENTS history. The risk is duplicate or partial append evidence, not
  rewrite of historical rows.
- The proposed readiness doctor is read-only by default; destructive external
  races are out of scope unless a later apply-mode bead enables repair.

## Mitigations Recommended

Recommended r5 or Phase 4 amendments:

1. Add a replay identity envelope common to dispatch-author, skill routing,
   close-validator, and mission-lock doctor receipts.
2. Use append-only per-lens audit rows as source truth, then derive `STATE.json`
   summary fields with merge semantics that preserve existing lens data.
3. Require deterministic `identity_key` fields for dispatch send, selected skill
   suite, skill receipt, close receipt, and mission-lock readiness receipt.
4. Require snapshot hashes for inputs that drift: skill catalog, alias registry,
   bead labels, touched files, mission surfaces, and Socraticode query set.
5. Add duplicate-close policy: latest row by `ref_id,event=close` is the close
   truth, while duplicate rows must point to `previous_close_row`.
6. Keep readiness/scaffold repair apply disabled until receipts include
   `mission_lock_hash`, section hashes, and an idempotency key.

Follow-up routing:

- File one Phase 4/r5 mitigation bead for the six findings:
  `flywheel-mission-lock-idempotency-receipt-integrity-amendments-2026-05-06`.
- No critical pause is required. The findings are amendable in plan/Phase 4
  schema work and do not invalidate Phase 3 continuation.

## Audit Verdict

audit_disposition: auto_advance
critical_findings: 0
high_findings: 1
phase3_idempotency_lens_green_light: true

Verdict: zero-critical-finding; auto-advance eligible.

The plan is not yet receipt-complete enough for code-space implementation, but
the missing pieces are bounded schema and merge-policy amendments. They should
be routed to r5 or Phase 4 implementation beads rather than blocking Phase 3.

## Disagreement-With-Other-Lenses Note

Lens 1 security closed with 0 critical, 1 high, 4 medium, and 1 low finding.
This lens agrees on the auto-advance disposition and finds the same severity
shape: 0 critical, 1 high, 4 medium, and 1 low.

Expected disagreement with security lens:

- Security focuses on what must never be included in packets or receipts.
  Idempotency focuses on what must be included so replay can detect duplicates.
- Security wants redaction and negative invariants; idempotency wants stable
  identity keys, hashes, and previous-row refs. Both are compatible, but the
  combined r5 schema must avoid adding secret values to replay identities.

Expected disagreement with cross-cutting skill-routing lens:

- Cross-cutting may treat alias ownership and skillos coordination as taxonomy
  questions. This lens treats them as replay inputs whose versions must be
  captured in receipts.
- Cross-cutting may accept tiny-edit minimal mode as a prompt-budget fix. This
  lens accepts minimal mode only if the compressed skip receipt still names the
  covered universal token set and policy version.
