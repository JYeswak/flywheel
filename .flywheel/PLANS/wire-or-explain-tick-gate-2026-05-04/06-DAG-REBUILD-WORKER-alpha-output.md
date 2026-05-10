---
title: "Worker alpha - beta-1 sub-DAG bead specs (15 beads)"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Worker alpha - beta-1 sub-DAG bead specs (15 beads)

## Self-grade

| field | value |
|---|---|
| jeff_score | 9.6 |
| donella_score | 9.6 |
| joshua_score | 9.6 |
| composite | 9.6 |
| quality_bar_passed | yes |
| l113_compliance | yes |
| did_claims_with_evidence_count | 8 |
| didnt_claims_with_evidence_count | 0 |
| evidence_coverage_rate | 8/8 |
| rust_clean | n/a |
| python_clean | n/a |
| cli_canonical | yes |
| readme_quality | yes |
| beads_drafted | 15/15 |
| acceptance_bullets_per_bead_median | 5 |
| l112_verification_commands_count | 15 |
| jeff_corpus_socraticode_queries_count | 4 |

## L113 claim ledger

| claim_id | DID claim | evidence |
|---|---|---|
| did-1 | Drafted 15 symbolic beta-1 bead specs. | command: `rg -c '^## Bead [0-9]+: WOE-EXP-B' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `15` |
| did-2 | Each bead has exactly one L110 row example with `dedup_key`. | command: `rg -c '\"artifact_class\":\"lrule_violation\".*\"dedup_key\"' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `15` |
| did-3 | Each bead has one L112 verification command. | command: `rg -c '^- L112 verification:' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `15` |
| did-4 | Each bead has a Jeff convergence declaration. | command: `rg -c '^\\*\\*Jeff convergence:\\*\\* jeff_pattern_adopted=' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `15` |
| did-5 | Each bead has a Donella stock/flow/loop trace. | command: `rg -c '^\\*\\*Donella trace:\\*\\*' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `15` |
| did-6 | The beta-1 source manifest, Section A inventory, and dependency rules were read. | file: `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:58`; grep_anchor: `## 3. 7-ledger architecture`; file: `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:79`; grep_anchor: `### beta-1: L1 lrule`; file: `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:137`; grep_anchor: `## 5. Dependency wiring` |
| did-7 | The r3 audit amendments were absorbed: B30 owns schema-version and every beta-1 row includes `dedup_key`. | file: `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r3-confirmation.md:41`; grep_anchor: `CC-EXP-F1`; file: `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r3-confirmation.md:44`; grep_anchor: `IDEMP-EXP-F1` |
| did-8 | Four Jeff-corpus query classes were applied to the bead specs. | command: `rg -c '^\\| jeff-corpus-query \\|' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-alpha-output.md`; expected_output_substring: `4` |

## Jeff convergence evidence

| query_class | disposition | evidence |
|---|---|---|
| jeff-corpus-query | EXTEND `rule_gate_replay` | file: `/Users/josh/Developer/jeff-corpus/franken_node/scripts/check_chokepoint_false_positives.py:121`; grep_anchor: `def evaluate_rules(data: dict) -> dict:` |
| jeff-corpus-query | EXTEND `violation_ledger_demotes_stock` | file: `/Users/josh/Developer/jeff-corpus/franken_engine/crates/franken-engine/tests/assumptions_ledger_integration.rs:666`; grep_anchor: `fn observe_violation_triggers_demotion()` |
| jeff-corpus-query | EXTEND `hash_linked_audit_chain_receipts` | file: `/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:1`; grep_anchor: `Policy audit chain` |
| jeff-corpus-query | GAP `tick_consequence` exact token | command: `rg -c 'tick_consequence' /Users/josh/Developer/jeff-corpus`; expected_output_substring: `0` |

## Common beta-1 contract

Every bead below writes L1 rows to `~/.local/state/flywheel/lrule-violation-ledger.jsonl`; the producer is the per-rule probe scanner and the consumer is the tick-close gate. Every row uses doctor field `lrule_enforcer_violations_24h`, carries a `dedup_key=<L-rule-id>:<probe-name>:<source-line>`, and drains only when `drain_receipt.closed_by="tick-close-gate"` names an evidence path.

## Bead 1: WOE-EXP-B16 (A1, L29 ntm-canonical-cli enforcer, P0)

**Title:** [wire-or-explain] L29 ntm-canonical-cli runtime enforcer

**Body:** Add a read-only L1 probe for L29 that scans dispatch, callback, and doctrine surfaces for direct pane-transport invocations, emits `L29:ntm_violation` rows, and exposes `.L29.ntm_violation_count`. Source: `AGENTS-CANONICAL.md:84-108`, `00-INTENT.md:250`, `05-DAG-REBUILD-SPEC-2026-05-05.md:85`. Tick-close warns until each row proves the offending surface was rewritten to `ntm`.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L29 --json`; expected_output_substring: `"artifact_id":"L29:ntm_violation"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<dispatch-log-or-template-path>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L29.ntm_violation_count // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: bad JSON or missing scanner returns `probe_failed`; recover with `flywheel-loop repair --scope=lrule-enforcers --rule=L29 --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L29:ntm_violation","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L29 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L29:ntm_violation_count:AGENTS-CANONICAL.md:95"}`.

**Jeff convergence:** jeff_pattern_adopted=rule_gate_replay; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_node/scripts/check_chokepoint_false_positives.py:121-138`.

**Donella trace:** stock=direct pane-transport violations; flow=dispatch text scanned into L1; loop=tick-close drains after rewrite; leverage=rules plus information flow.

**dedup_key:** `L29:ntm_violation_count:AGENTS-CANONICAL.md:95`

## Bead 2: WOE-EXP-B17 (A2, L35 tier-3 paired-bead enforcer, P1)

**Title:** [wire-or-explain] L35 tier-3 paired-tool bead enforcer

**Body:** Add the L35 probe that finds Tier-3 blocker classifications lacking a same-tick paired tool bead or explicit downgrade receipt, emits `L35:tier3_unpaired`, and reports `.L35.tier3_unpaired_count`. Source: `AGENTS-CANONICAL.md:109-130`, `00-INTENT.md:251`, `05-DAG-REBUILD-SPEC-2026-05-05.md:86`. Tick-close warns because unpaired Tier-3 stock keeps autonomy shrinking.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L35 --json`; expected_output_substring: `"artifact_id":"L35:tier3_unpaired"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<paired-tool-bead-or-no-auto-repair-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L35.tier3_unpaired_count // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: if bead lookup times out, row gets `deferred_reason="bead_db_unavailable"`; recover with `flywheel-loop repair --scope=beads --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L35:tier3_unpaired","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L35 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L35:tier3_unpaired_count:AGENTS-CANONICAL.md:120"}`.

**Jeff convergence:** jeff_pattern_adopted=violation_ledger_demotes_stock; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_engine/crates/franken-engine/tests/assumptions_ledger_integration.rs:666-678`.

**Donella trace:** stock=Tier-3 claims without tool outflow; flow=classification rows enter L1; loop=paired bead drains autonomy debt; leverage=rule plus self-organization.

**dedup_key:** `L35:tier3_unpaired_count:AGENTS-CANONICAL.md:120`

## Bead 3: WOE-EXP-B18 (A3, L48 substrate-bleed-triage auto-fire, P0)

**Title:** [wire-or-explain] L48 substrate-exhaustion auto-fire enforcer

**Body:** Wire L48 into a probe that rejects credential-shaped or substrate-state escalations unless their callback carries the four-rung probe ledger, then emits `L48:substrate_unprobed_escalation`. Source: `AGENTS-CANONICAL.md:29-83`, `00-INTENT.md:252`, `05-DAG-REBUILD-SPEC-2026-05-05.md:87`. Tick-close warns before any Joshua ask is treated as valid.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L48 --json`; expected_output_substring: `"artifact_id":"L48:substrate_unprobed_escalation"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<probe-ledger-or-repaired-escalation-row>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L48.substrate_unprobed_escalations // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: missing secret-tool binaries set `deferred_reason="probe_dependency_missing"`; recover with `flywheel-loop repair --scope=substrate-probes --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L48:substrate_unprobed_escalation","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L48 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L48:substrate_unprobed_escalations:AGENTS-CANONICAL.md:40"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:1-5`.

**Donella trace:** stock=unprobed escalations; flow=escalation text enters L1; loop=probe ledger closes human-ask leak; leverage=information flow before intervention.

**dedup_key:** `L48:substrate_unprobed_escalations:AGENTS-CANONICAL.md:40`

## Bead 4: WOE-EXP-B19 (A4, L50 socraticode preflight count, P0)

**Title:** [wire-or-explain] L50 socraticode preflight count enforcer

**Body:** Add an L50 scanner that reads dispatch packets and worker callbacks, compares required Socraticode preflight fields to actual callback counts, emits `L50:zero_socraticode`, and reports `.L50.dispatches_zero_socraticode`. Source: `AGENTS-CANONICAL.md:131-188`, `00-INTENT.md:253`, `05-DAG-REBUILD-SPEC-2026-05-05.md:88`. Tick-close warns on substrate-amnesia drift.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L50 --json`; expected_output_substring: `"artifact_id":"L50:zero_socraticode"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<callback-with-socraticode_queries-and-indexed_chunks>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L50.dispatches_zero_socraticode // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: missing dispatch log returns `stock=0` plus warning row; recover with `flywheel-loop repair --scope=dispatch-log --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L50:zero_socraticode","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L50 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L50:dispatches_zero_socraticode:AGENTS-CANONICAL.md:142"}`.

**Jeff convergence:** jeff_pattern_adopted=rule_gate_replay; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_node/scripts/check_chokepoint_false_positives.py:141-180`.

**Donella trace:** stock=dispatches with no survey; flow=callback counts into L1; loop=redispatch until survey evidence exists; leverage=information flow.

**dedup_key:** `L50:dispatches_zero_socraticode:AGENTS-CANONICAL.md:142`

## Bead 5: WOE-EXP-B20 (A5, L51 file-reservation enforcer, P1)

**Title:** [wire-or-explain] L51 file-reservation enforcer

**Body:** Add the L51 scanner that detects edit dispatches with file paths but no reservation receipt, emits `L51:unreserved_multi_file_dispatch`, and exposes `.L51.unreserved_multi_file_dispatches`. Source: `AGENTS-CANONICAL.md:189-218`, `00-INTENT.md:254`, `05-DAG-REBUILD-SPEC-2026-05-05.md:89`. Tick-close warns before concurrent-worker drift can merge silently.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L51 --json`; expected_output_substring: `"artifact_id":"L51:unreserved_multi_file_dispatch"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<agent-mail-reservation-or-dispatch-amendment>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L51.unreserved_multi_file_dispatches // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: agent-mail unreachable writes deferred row with owner; recover with `flywheel-loop repair --scope=agent-mail --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L51:unreserved_multi_file_dispatch","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L51 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L51:unreserved_multi_file_dispatches:AGENTS-CANONICAL.md:200"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:171-187`.

**Donella trace:** stock=edit dispatches without locks; flow=reservation audit gap into L1; loop=tick-close requires reservation receipt; leverage=rules on shared state.

**dedup_key:** `L51:unreserved_multi_file_dispatches:AGENTS-CANONICAL.md:200`

## Bead 6: WOE-EXP-B21 (A6, L52 issues-to-beads enforcer, P0)

**Title:** [wire-or-explain] L52 issue-routing receipt enforcer

**Body:** Wire an L52 validator for worker callbacks and validation reports: every observed gap must show `beads_filed`, `beads_updated`, or `no_bead_reason`. Violations emit `L52:unrouted_validation` and feed `.L52.unrouted_validation_count`. Source: `AGENTS-CANONICAL.md:219-255`, `00-INTENT.md:255`, `05-DAG-REBUILD-SPEC-2026-05-05.md:90`. Tick-close warns on silent-finding loss.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L52 --json`; expected_output_substring: `"artifact_id":"L52:unrouted_validation"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<bead-id-or-no-bead-reason-callback>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L52.unrouted_validation_count // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: unreadable callback archive returns `probe_failed`; recover with `flywheel-loop repair --scope=callback-archive --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L52:unrouted_validation","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L52 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L52:unrouted_validation_count:AGENTS-CANONICAL.md:230"}`.

**Jeff convergence:** jeff_pattern_adopted=violation_ledger_demotes_stock; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_engine/crates/franken-engine/tests/assumptions_ledger_integration.rs:896-911`.

**Donella trace:** stock=observed issues without route; flow=callback/report rows into L1; loop=tick-close drains via bead or explicit no-bead reason; leverage=feedback routing.

**dedup_key:** `L52:unrouted_validation_count:AGENTS-CANONICAL.md:230`

## Bead 7: WOE-EXP-B22 (A7, L53 callback fuckup-field validator, P0)

**Title:** [wire-or-explain] L53 callback fuckup-field validator

**Body:** Add an L53 callback validator that requires BLOCKED callbacks and DONE-with-trauma callbacks to include `fuckups_logged`, emits `L53:callback_missing_fuckup_class`, and adds the CoralRaven repeat-halt scan for two same foundational-tool risk flags in the last three callbacks. Source: `AGENTS-CANONICAL.md:256-286`, `00-INTENT.md:256`, `05-DAG-REBUILD-SPEC-2026-05-05.md:91`, dispatch template lines `451-462`.

**Parents:** `flywheel-2eow`, `WOE-EXP-B16`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L53 --json`; expected_output_substring: `"artifact_id":"L53:callback_missing_fuckup_class"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<callback-with-fuckups_logged-or-halt-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L53.callbacks_missing_fuckup_class // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: if callback archive has malformed rows, set `deferred_reason="callback_parse_failed"`; recover with `flywheel-loop repair --scope=callback-validator --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L53:callback_missing_fuckup_class","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L53 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L53:callbacks_missing_fuckup_class:AGENTS-CANONICAL.md:267"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:216-238`.

**Donella trace:** stock=callbacks losing trauma memory; flow=callback validation rows into L1; loop=halt or receipt drains repeated foundational-tool risk; leverage=feedback loop.

**dedup_key:** `L53:callbacks_missing_fuckup_class:AGENTS-CANONICAL.md:267`

## Bead 8: WOE-EXP-B23 (A8, L54 worker-skill-coverage probe, P1)

**Title:** [wire-or-explain] L54 worker skill-climb coverage probe

**Body:** Add the L54 probe that inspects BLOCKED callbacks for `skills_consulted` or `NONE_FOUND` plus grep terms, emits `L54:blocker_without_skill_climb`, and reports `.L54.blockers_without_skill_climb`. Source: `AGENTS-CANONICAL.md:287-321`, `00-INTENT.md:257`, `05-DAG-REBUILD-SPEC-2026-05-05.md:92`. Tick-close warns when workers bypass the skill substrate.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L54 --json`; expected_output_substring: `"artifact_id":"L54:blocker_without_skill_climb"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<callback-with-skills-consulted-or-NONE_FOUND>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L54.blockers_without_skill_climb // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: skill inventory read failure defers row with owner `skillos`; recover with `flywheel-loop repair --scope=skill-index --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L54:blocker_without_skill_climb","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L54 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L54:blockers_without_skill_climb:AGENTS-CANONICAL.md:298"}`.

**Jeff convergence:** jeff_pattern_adopted=rule_gate_replay; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_node/scripts/check_chokepoint_false_positives.py:155-170`.

**Donella trace:** stock=blockers without skill recovery; flow=BLOCKED callbacks into L1; loop=skill climb evidence drains row; leverage=information flow plus rules.

**dedup_key:** `L54:blockers_without_skill_climb:AGENTS-CANONICAL.md:298`

## Bead 9: WOE-EXP-B24 (A9, L55 skillos-relay auto-fire, P0)

**Title:** [wire-or-explain] L55 skillos relay auto-fire enforcer

**Body:** Add the L55 enforcer that consumes L54 `NONE_FOUND` trauma classes and fuckup frequency, emits `L55:skillos_relay_violation` when a recurring class is not routed to skillos, and reports `.L55.skillos_relay_violations`. Source: `AGENTS-CANONICAL.md:322-361`, `00-INTENT.md:258`, `05-DAG-REBUILD-SPEC-2026-05-05.md:93`. Tick-close errors for missed skill-candidate relays.

**Parents:** `flywheel-2eow`, `WOE-EXP-B23`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L55 --json`; expected_output_substring: `"artifact_id":"L55:skillos_relay_violation"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<skillos-pending-candidate-or-ntm-send-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L55.skillos_relay_violations // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: skillos session unreachable queues local candidate row; recover with `flywheel-loop repair --scope=skillos-relay --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L55:skillos_relay_violation","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L55 --json","tick_consequence":"error","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L55:skillos_relay_violations:AGENTS-CANONICAL.md:333"}`.

**Jeff convergence:** jeff_pattern_adopted=violation_ledger_demotes_stock; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_engine/crates/franken-engine/tests/assumptions_ledger_integration.rs:666-678`.

**Donella trace:** stock=recurring missing-skill classes; flow=L54 NONE_FOUND rows into relay; loop=skillos candidate drains stock; leverage=self-organization.

**dedup_key:** `L55:skillos_relay_violations:AGENTS-CANONICAL.md:333`

## Bead 10: WOE-EXP-B25 (A10, L56 doctrine-ladder auto-tick, P1)

**Title:** [wire-or-explain] L56 doctrine-ladder auto-tick enforcer

**Body:** Add the L56 auto-tick probe that compares fuckup-log rows, INCIDENTS entries, and canonical L-rules; emits `L56:unprocessed_fuckup_row` for trauma classes exceeding threshold without promotion evidence. Source: `AGENTS-CANONICAL.md:362-417`, `00-INTENT.md:259`, `05-DAG-REBUILD-SPEC-2026-05-05.md:94`. Tick-close warns when learning stalls at layer 1.

**Parents:** `flywheel-2eow`, `WOE-EXP-B22`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L56 --json`; expected_output_substring: `"artifact_id":"L56:unprocessed_fuckup_row"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<INCIDENTS-entry-or-L-rule-promotion-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L56.unprocessed_fuckup_rows // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: malformed JSONL isolates bad line and continues; recover with `flywheel-loop repair --scope=fuckup-log --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L56:unprocessed_fuckup_row","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L56 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L56:unprocessed_fuckup_rows:AGENTS-CANONICAL.md:373"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:284-340`.

**Donella trace:** stock=unpromoted trauma rows; flow=fuckup-log into ladder scanner; loop=INCIDENTS/L-rule receipt drains stock; leverage=self-organization.

**dedup_key:** `L56:unprocessed_fuckup_rows:AGENTS-CANONICAL.md:373`

## Bead 11: WOE-EXP-B26 (A11, L57 loop-driver drift detector, P0)

**Title:** [wire-or-explain] L57 loop-driver drift detector

**Body:** Add the L57 detector that verifies loop active markers against actual prompt drivers and pane evidence, emits `L57:loop_driver_drift`, and exposes `.L57.loop_driver_drift_count`. Source: `AGENTS-CANONICAL.md:418-470`, `00-INTENT.md:260`, `05-DAG-REBUILD-SPEC-2026-05-05.md:95`. Tick-close errors on marker-only loops because they silently stop work.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L57 --json`; expected_output_substring: `"artifact_id":"L57:loop_driver_drift"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<driver-log-or-pane-proof>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L57.loop_driver_drift_count // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: ntm health unavailable returns `deferred_reason="topology_probe_failed"`; recover with `flywheel-loop repair --scope=loop-driver --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L57:loop_driver_drift","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L57 --json","tick_consequence":"error","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L57:loop_driver_drift_count:AGENTS-CANONICAL.md:429"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:216-238`.

**Donella trace:** stock=active markers without drivers; flow=loop state and pane proof into L1; loop=driver proof drains row; leverage=measurement plus rules.

**dedup_key:** `L57:loop_driver_drift_count:AGENTS-CANONICAL.md:429`

## Bead 12: WOE-EXP-B27 (A12, L61 3-surface drift error escalation, P0)

**Title:** [wire-or-explain] L61 three-surface drift escalation enforcer

**Body:** Add an L61 scanner that verifies doctrine landings touch AGENTS, README, and memory/no-touch receipts, emits `L61:doctrine_3_surface_divergence`, and reports `.L61.doctrine_3_surface_divergence`. Source: `AGENTS-CANONICAL.md:641-685`, `00-INTENT.md:261`, `05-DAG-REBUILD-SPEC-2026-05-05.md:96`. Tick-close errors because orphan doctrine keeps recurring.

**Parents:** `flywheel-2eow`, `WOE-EXP-B25`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L61 --json`; expected_output_substring: `"artifact_id":"L61:doctrine_3_surface_divergence"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<AGENTS-README-memory-or-no-touch-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L61.doctrine_3_surface_divergence // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: target repo missing README gets explicit no-touch requirement; recover with `flywheel-loop repair --scope=doctrine-surfaces --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L61:doctrine_3_surface_divergence","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L61 --json","tick_consequence":"error","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L61:doctrine_3_surface_divergence:AGENTS-CANONICAL.md:643"}`.

**Jeff convergence:** jeff_pattern_adopted=rule_gate_replay; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_node/scripts/check_chokepoint_false_positives.py:167-180`.

**Donella trace:** stock=doctrine landed on one surface only; flow=surface diff into L1; loop=ecosystem touch drains row; leverage=information flow.

**dedup_key:** `L61:doctrine_3_surface_divergence:AGENTS-CANONICAL.md:643`

## Bead 13: WOE-EXP-B28 (A13, L70 chain-state ticks-punted counter, P0)

**Title:** [wire-or-explain] L70 chain-state ticks-punted counter

**Body:** Add the L70 probe that detects orchestrator conclusions naming a next actionable phase without executing it in the same tick, emits `L70:tick_punted`, and reports `.L70.ticks_punted_count`. Source: `AGENTS-CANONICAL.md:1098-1170`, `00-INTENT.md:262`, `05-DAG-REBUILD-SPEC-2026-05-05.md:97`. Tick-close warns because returning to cron while work is ready is silent darkness.

**Parents:** `flywheel-2eow`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L70 --json`; expected_output_substring: `"artifact_id":"L70:tick_punted"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<same-tick-chain-receipt-or-chain_blocked_reason>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L70.ticks_punted_count // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: missing tick log returns `deferred_reason="tick_log_unavailable"`; recover with `flywheel-loop repair --scope=tick-chain --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L70:tick_punted","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L70 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L70:ticks_punted_count:AGENTS-CANONICAL.md:1109"}`.

**Jeff convergence:** jeff_pattern_adopted=violation_ledger_demotes_stock; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/franken_engine/crates/franken-engine/tests/assumptions_ledger_integration.rs:666-678`.

**Donella trace:** stock=named-but-unrun next actions; flow=tick conclusions into L1; loop=same-tick chain receipt drains punted stock; leverage=feedback timing.

**dedup_key:** `L70:ticks_punted_count:AGENTS-CANONICAL.md:1109`

## Bead 14: WOE-EXP-B29 (A14, L108 cache-vs-source drift propagation, P1)

**Title:** [wire-or-explain] L108 cache-vs-source drift propagation enforcer

**Body:** Add the L108 probe that distinguishes cache freshness from source convergence, emits `L108:canonical_doctrine_propagation_drift`, and reports `.L108.canonical_doctrine_propagation_drift`. Source: `AGENTS-CANONICAL.md:2922-2966`, `00-INTENT.md:263`, `05-DAG-REBUILD-SPEC-2026-05-05.md:98`. Tick-close warns if cache mtime masks missing three-surface alignment.

**Parents:** `flywheel-2eow`, `WOE-EXP-B27`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L108 --json`; expected_output_substring: `"artifact_id":"L108:canonical_doctrine_propagation_drift"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<sync-check-three-surface-json-receipt>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L108.canonical_doctrine_propagation_drift // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: missing canonical sync script sets error row with owner; recover with `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target /Users/josh/Developer/flywheel --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L108:canonical_doctrine_propagation_drift","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L108 --json","tick_consequence":"warn","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L108:canonical_doctrine_propagation_drift:AGENTS-CANONICAL.md:2933"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:171-187`.

**Donella trace:** stock=cache/source divergence; flow=sync check receipts into L1; loop=source convergence proof drains row; leverage=measurement integrity.

**dedup_key:** `L108:canonical_doctrine_propagation_drift:AGENTS-CANONICAL.md:2933`

## Bead 15: WOE-EXP-B30 (A15, L110 substrate-loop-contract validator, P0)

**Title:** [wire-or-explain] L110 substrate-loop-contract self-validator

**Body:** Add the L110 validator and schema-version owner for all L1 rows. It audits substrate primitives for stock, consumer, owner, verification probe, consequence, drain receipt, and `dedup_key`, emits `L110:primitive_missing_contract`, and installs one self-row fixture. Source: `AGENTS-CANONICAL.md:2967-3038`, `00-INTENT.md:264`, `05-DAG-REBUILD-SPEC-2026-05-05.md:99`, audit `CC-EXP-F1`.

**Parents:** `flywheel-2eow`, `flywheel-4m2a`

**Acceptance:**
- Probe command: `flywheel-loop probe --rule=L110 --json`; expected_output_substring: `"artifact_id":"L110:primitive_missing_contract"`.
- Drain receipt schema: `{"closed_at":"<iso>","closed_by":"tick-close-gate","evidence_path":"<schema-version-and-self-row-fixture-path>"}`.
- L112 verification: `bash -c 'flywheel-loop doctor --json | jq -r ".lrule_enforcer_violations_24h.L110.primitives_missing_contract // empty"'`; expected_output_substring: `[integer]`.
- Failure mode + recovery: schema mismatch fails closed and names B30 as owner; recover with `flywheel-loop repair --scope=lrule-ledger-schema --dry-run --json`.
- L110 row example: `{"ts":"<iso>","artifact_id":"L110:primitive_missing_contract","artifact_class":"lrule_violation","stock":1,"consumer":"tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"flywheel-loop probe --rule=L110 --json","tick_consequence":"error","drain_receipt":{"closed_at":null,"closed_by":null,"evidence_path":null},"dedup_key":"L110:primitives_missing_contract:AGENTS-CANONICAL.md:2978"}`.

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`/Users/josh/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:1-35`.

**Donella trace:** stock=substrate primitives without repair loops; flow=primitive audits into L1; loop=schema owner plus self-row drains orphan risk; leverage=system rules.

**dedup_key:** `L110:primitives_missing_contract:AGENTS-CANONICAL.md:2978`
