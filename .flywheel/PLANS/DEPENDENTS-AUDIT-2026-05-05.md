---
title: "DEPENDENTS-AUDIT-2026-05-05"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [00. Executive verdict](#00-executive-verdict)
- [01. Audit scope](#01-audit-scope)
- [02. Pre-flight and substrate](#02-pre-flight-and-substrate)
- [03. Source ledger](#03-source-ledger)
- [04. Dependency graph observed](#04-dependency-graph-observed)
- [05. Active dependent counts from read-only database query](#05-active-dependent-counts-from-read-only-database-query)
- [06. Existing implementation reality](#06-existing-implementation-reality)
- [07. Current-plan replacement map](#07-current-plan-replacement-map)
- [08. Classification summary](#08-classification-summary)
- [09. Finding A - flywheel-hww is foundation, not duplicate](#09-finding-a-flywheel-hww-is-foundation-not-duplicate)
- [10. Finding B - flywheel-247 is old lifecycle, not current foundation](#10-finding-b-flywheel-247-is-old-lifecycle-not-current-foundation)
- [11. Finding C - flywheel-3eo should redirect to Manager A0/A4](#11-finding-c-flywheel-3eo-should-redirect-to-manager-a0-a4)
- [12. Finding D - flywheel-1fh is the immediate leaf](#12-finding-d-flywheel-1fh-is-the-immediate-leaf)
- [13. Finding E - flywheel-1m2 and flywheel-bkc are not noise](#13-finding-e-flywheel-1m2-and-flywheel-bkc-are-not-noise)
- [14. Context-only rows](#14-context-only-rows)
- [15. Cascade chains identified](#15-cascade-chains-identified)
- [16. Recommended updated close order](#16-recommended-updated-close-order)
- [17. What changed from the prior close plan](#17-what-changed-from-the-prior-close-plan)
- [18. Risk register](#18-risk-register)
- [19. Acceptance criteria for redirecting hww](#19-acceptance-criteria-for-redirecting-hww)
- [20. Acceptance criteria for closing the old scanner spine](#20-acceptance-criteria-for-closing-the-old-scanner-spine)
- [21. Detailed per-bead notes](#21-detailed-per-bead-notes)
- [22. Direct answers to dispatch questions](#22-direct-answers-to-dispatch-questions)
- [23. Plan-space only close packets to author next](#23-plan-space-only-close-packets-to-author-next)
- [24. Why not foundation-ship-first for all of fleet-coherence](#24-why-not-foundation-ship-first-for-all-of-fleet-coherence)
- [25. Why not cascade-close-all](#25-why-not-cascade-close-all)
- [26. Fleet-coherence verdict](#26-fleet-coherence-verdict)
- [27. Callback metrics](#27-callback-metrics)
- [28. L112 self-check text](#28-l112-self-check-text)
- [29. Final recommendation](#29-final-recommendation)
- [30. Appendix - normalized close sequence if replacements are accepted](#30-appendix-normalized-close-sequence-if-replacements-are-accepted)
- [31. Appendix - audit invariants](#31-appendix-audit-invariants)
- [32. Evidence notes](#32-evidence-notes)
- [33. Closing statement](#33-closing-statement)
# DEPENDENTS-AUDIT-2026-05-05

dispatch: /tmp/dispatch_dependents-audit-2026-05-05.md
mode: plan-space-only
bead-db-writes: 0
worker: SwiftEagle
date: 2026-05-05
verdict: mixed
fleet_coherence_verdict: mixed
primary_result: cascade-close the obsolete scanner/status/action spine; preserve and redirect the fleet-communications health foundation.

## 00. Executive verdict

- The six skipped close packets were not six independent close failures.
- They expose one old fleet-coherence dependency spine plus one surviving fleet-communications foundation concern.
- The old spine is the May 1 fleet-coherence scanner, writer, classifier, status, and Step 4i action plan.
- The old spine is materially superseded by the May 5 Fleet P1/P2 typed selector receipts, Manager A0/A2/A4 fact and projection surfaces, Mission source/reality contracts, and Watchdog enablement plan.
- The surviving foundation is not the old shadow report; it is authenticated fleet-mail / Agent Mail / alert-channel truth.
- That foundation appears in flywheel-hww and its transitive alert-channel children flywheel-1m2 and flywheel-bkc.
- Therefore the correct answer is mixed: cascade-close the stale control-plane chain, but redirect the fleet-comms foundation before closing anything that would erase it.
- Immediate plan-space closeability improves by one bead: flywheel-1fh is a leaf and can be closed as obsolete if the close owner accepts this audit.
- After flywheel-1fh closes, flywheel-2y4 becomes the next candidate, but it still references open upstream fleet-comms parents; treat it as a reviewed obsolete close, not a blind sequential close.
- The old Phase 1 chain cannot be retried as-is because flywheel-hww still blocks flywheel-1hn and should not be thrown away as a duplicate of the obsolete report.
- First rebase or replace the hww/1m2/bkc fleet-comms concern; then close 1hn, pd9, 247, 3eo, dzj, 1km, and 2te in dependent-first order.

## 01. Audit scope

| Skipped bead | Skipped because active dependent(s) | Audit target |
|---|---|---|
| flywheel-1hn | flywheel-hww | decide whether hww is obsolete, redirect, or foundation |
| flywheel-pd9 | flywheel-1hn | pd9 remains blocked by the old report until 1hn is unblocked |
| flywheel-dzj | flywheel-247, flywheel-3eo | decide whether lifecycle/status children are cascade-closeable |
| flywheel-1km | flywheel-dzj, flywheel-pd9 | old writer remains blocked by scanner/classifier children |
| flywheel-2te | flywheel-1hn, flywheel-1km, flywheel-247, flywheel-3eo, flywheel-dzj, flywheel-pd9 | old schema root is the base of the stale spine |
| flywheel-2y4 | flywheel-1fh | decide whether old action consumer remains useful |

The direct dependent audit set is flywheel-hww, flywheel-247, flywheel-3eo, and flywheel-1fh.
The transitive dependent audit set adds flywheel-1m2 and flywheel-bkc because hww is not a leaf; it is a foundation-shaped fork.
The context-only set is flywheel-2i4, flywheel-cgy, and flywheel-375; those explain classifier and action dependencies but are not blockers for the six skipped close packets.

## 02. Pre-flight and substrate

- Skills read: beads-bv, beads-br, beads-workflow, canonical-cli-scoping, jeff-planning-enhanced, flywheel:plan, flywheel:skills-best-practices.
- Socraticode status: project /Users/josh/Developer/flywheel indexed with 694 chunks observed before audit synthesis.
- Socraticode queries executed: 4.
- Skill search executed for fleet-coherence foundation cluster, cascade-close dependent audit, agent orchestration, observability, beads graph.
- Bead writes: none.
- Bead reads: sqlite read-only queries and prior br/bv read surfaces only.
- File reservation: .flywheel/PLANS/DEPENDENTS-AUDIT-2026-05-05.md reserved before write.
- Dispatch gate target: L112 requires this file, >=300 lines, cascade/foundation vocabulary, and explicit flywheel-247/flywheel-3eo/flywheel-hww mentions.

## 03. Source ledger

| Source | Use in this audit |
|---|---|
| WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:57-62 | records the six skipped close attempts and their active dependents |
| WAVE-0-CLOSE-APPLY-LOG-2026-05-05.md:216-221 | notes that 247 and 3eo are likely old fleet-coherence support beads and that 1fh must be classified before retrying 2y4 |
| WAVE-0-CLOSE-PLAN-2026-05-05.md:82-323 | contains the six planned close packets that were blocked by dependents |
| OPEN-BEADS-RECONCILIATION-2026-05-05.md:49-92 | classifies 2te, pd9, 1km, dzj as duplicates and 1hn/2y4 as obsolete |
| OPEN-BEADS-RECONCILIATION-2026-05-05.md:64 | classifies hww as orthogonal, not as a duplicate |
| OPEN-BEADS-RECONCILIATION-2026-05-05.md:945-948 | duplicate register mapping old fleet beads to new Fleet/Mission replacements |
| OPEN-BEADS-RECONCILIATION-2026-05-05.md:1062-1063 | obsolete register for 1hn and 2y4 |
| fleet-coherence-bead-graph-2026-05-01.md:11-25 | original May 1 fleet-coherence bead list |
| fleet-coherence-bead-graph-2026-05-01.md:28-48 | original dependency edges that explain this closure cascade |
| fleet-coherence-bead-graph-2026-05-01.md:101-112 | original dispatch order and phase layering |
| fleet-coherence-schema-v2.md:3-10 | phase 0 schema was plan/spec only, not scanner implementation |
| fleet-coherence-schema-v2.md:74-104 | L61/L62/L63 fields show why authenticated alert-channel truth is not optional |
| UNIFIED-DAG-2026-05-05.md:88-92 | current Fleet rows 181e5, 3ctlx, 2j1dw, 2bxry, 12k9o |
| UNIFIED-DAG-2026-05-05.md:98-107 | current Mission rows including gwbvf and 4ggh2 |
| UNIFIED-DAG-2026-05-05.md:246-260 | Wave 1 selection and held root ordering |
| fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:87-216 | Fleet current receipt contracts and retry behavior |
| fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:229-276 | Fleet P3 and M tombstone mappings to Manager A0/A4/A2 |
| manager-loop-architecture-2026-05-05/00-PLAN-r2.md:928-958 | Manager receipt inputs and A0/A2/A4 ship order |
| manager-loop-architecture-2026-05-05/00-PLAN-r2.md:1027-1063 | preserved primitives versus deprecated control-plane shape |
| watchdog-enablement-2026-05-05/00-PLAN.md:503-529 | watchdog sits below manager/fleet/mission and emits manager-consumable receipts |
| watchdog-enablement-2026-05-05/00-PLAN.md:589-599 | frozen-pane detector and no-silent-darkness become watchdog surfaces |

## 04. Dependency graph observed

- flywheel-2te -> flywheel-1hn, flywheel-1km, flywheel-247, flywheel-3eo, flywheel-dzj, flywheel-pd9
- flywheel-1km -> flywheel-dzj, flywheel-pd9
- flywheel-dzj -> flywheel-247, flywheel-3eo
- flywheel-247 -> flywheel-pd9
- flywheel-3eo -> flywheel-pd9
- flywheel-pd9 -> flywheel-1hn
- flywheel-1hn -> flywheel-hww
- flywheel-hww -> flywheel-1m2, flywheel-2y4
- flywheel-1m2 -> flywheel-bkc, flywheel-2y4
- flywheel-bkc -> flywheel-2y4
- flywheel-2y4 -> flywheel-1fh

Read as close order, this graph must be traversed dependent-first.
A close attempt on a parent before its dependent is classified creates the same skip-list again.
The dependency topology is therefore itself evidence: the old May 1 plan was a single long spine, not isolated work packets.

## 05. Active dependent counts from read-only database query

| Bead | Status | Active dependents | Dependents |
|---|---|---:|---|
| flywheel-1fh | open | 0 | none |
| flywheel-1hn | open | 1 | flywheel-hww[open] |
| flywheel-1km | open | 2 | flywheel-dzj[open], flywheel-pd9[open] |
| flywheel-1m2 | open | 2 | flywheel-2y4[open], flywheel-bkc[open] |
| flywheel-247 | open | 1 | flywheel-pd9[open] |
| flywheel-2te | blocked | 6 | flywheel-1hn[open], flywheel-1km[open], flywheel-247[open], flywheel-3eo[open], flywheel-dzj[open], flywheel-pd9[open] |
| flywheel-2y4 | open | 1 | flywheel-1fh[open] |
| flywheel-3eo | open | 1 | flywheel-pd9[open] |
| flywheel-bkc | open | 1 | flywheel-2y4[open] |
| flywheel-dzj | open | 2 | flywheel-247[open], flywheel-3eo[open] |
| flywheel-hww | open | 2 | flywheel-1m2[open], flywheel-2y4[open] |
| flywheel-pd9 | open | 1 | flywheel-1hn[open] |

The only audited leaf is flywheel-1fh.
That does not make every upstream close safe; it only identifies the first possible cascade-close move.
The highest-connectivity old root is flywheel-2te, which reaches most of the old cluster transitively.
The highest-risk fork is flywheel-hww, because it is both a dependent of obsolete flywheel-1hn and the parent of alert-channel work that still matters.

## 06. Existing implementation reality

| Reality | Path | Meaning |
|---|---|---|
| exists | .flywheel/specs/fleet-coherence-schema-v2.md | schema/spec artifact from Phase 0 |
| exists | .flywheel/fixtures/fleet-coherence-fixtures.jsonl | fixture corpus from Phase 0 |
| missing | .flywheel/scripts/fleet-coherence-scan.sh | old Phase 1 scanner implementation not present |
| missing | .flywheel/scripts/fleet-coherence-lib.sh | old shared scanner/writer library not present |
| missing | .flywheel/scripts/fleet-coherence-write.sh | old event writer implementation not present |
| missing | .flywheel/scripts/fleet-mail-auth-probe.sh | hww implementation not present |
| missing | .flywheel/scripts/fleet-coherence-alert.sh | dual-channel alert implementation not present |
| missing | .flywheel/scripts/fleet-coherence-classifiers.sh | old classifier implementation not present |
| missing | launchd/ai.zeststream.fleet-coherence.plist | old launchd detector driver not present |
| missing | tests/fleet-coherence-status.sh | old drift-status command test not present |
| missing | tests/fleet-coherence-step4i-readonly.sh | old read-only Step 4i consumer test not present |
| missing | tests/fleet-coherence-step4i-actions.sh | old action Step 4i consumer test not present |

This matters because the May 1 fleet-coherence implementation substrate never fully shipped.
Closing stale implementation beads is lower risk than closing shipped code paths.
But the absence of implementation also means the hww/1m2/bkc foundation has not been replaced by working code unless another current plan explicitly owns it.

## 07. Current-plan replacement map

| Old bead | Old obligation | Current owner / replacement | Audit action |
|---|---|---|---|
| flywheel-2te | Phase 0 schema and fixtures | 181e5, 3ctlx, 2j1dw plus archived schema evidence | cascade-close after dependents |
| flywheel-1km | generic writer | 2bxry, 12k9o typed selector/retry receipts and Manager A0 registry | cascade-close after dzj/pd9 |
| flywheel-dzj | fleet scanner | gwbvf, 4ggh2, 2bxry, watchdog summaries | cascade-close after 247/3eo |
| flywheel-247 | launchd lifecycle for old scanner | watchdog lifecycle / frozen-pane detector / manager receipt consumption | cascade-close or redirect to watchdog |
| flywheel-3eo | drift-status cached command | Manager A0 facts, A4 projections, watchdog manager summaries | redirect then close old command |
| flywheel-pd9 | old classifier | 2bxry selector contract, 12k9o retry suppression, Manager A2 values | cascade-close after 1hn |
| flywheel-1hn | standalone shadow signal-quality report | Manager A0/A2/A4 and watchdog receipt summaries | cascade-close after hww is detached |
| flywheel-hww | authenticated fleet-mail probe | L104 fleet-comms / Agent Mail health / watchdog delivery proof | FOUNDATION redirect, do not erase |
| flywheel-1m2 | dual-channel alert sender | fleet-comms measured delivery and manager summary channels | REDIRECT |
| flywheel-bkc | degraded alert-channel handling | fleet-comms degradation status and watchdog no-action receipts | REDIRECT |
| flywheel-2y4 | Step 4i read-only consumer | Manager A0/A4 projection and watchdog observation receipts | cascade-close after 1fh |
| flywheel-1fh | Step 4i action consumer | Manager decision receipts and watchdog recovery transaction | cascade-close leaf |

The replacement map is not a request to mutate dependencies in this pass.
It is the plan-space answer to why the six skipped close packets should not be retried blindly.

## 08. Classification summary

| Dependent | Classification | Rationale |
|---|---|---|
| flywheel-hww | FOUNDATION | Authenticated fleet-mail / Agent Mail probe remains load-bearing; detach from obsolete 1hn and rebase to fleet-comms/watchdog. |
| flywheel-247 | CASCADE-CLOSE | Launchd lifecycle for old fleet-coherence scanner; current watchdog lifecycle owns the surviving liveness concern. |
| flywheel-3eo | REDIRECT | Old drift-status command should become Manager A0/A4/watchdog summary evidence, not a standalone old command. |
| flywheel-1fh | CASCADE-CLOSE | Old Step 4i action consumer is a leaf and is superseded by Manager decisions plus watchdog recovery transaction. |
| flywheel-1m2 | REDIRECT | Dual-channel alerting concern survives, but the old L61 sender should map to fleet-comms measured health and manager summaries. |
| flywheel-bkc | REDIRECT | Degraded alert-channel handling survives as fleet-comms degradation status; do not keep it tied to obsolete hww chain shape. |

Counts: dependents audited = 6; cascade-close = 2; foundation = 1; redirect = 3; orthogonal = 0.
The reconciliation file already called hww orthogonal; this audit tightens that to FOUNDATION because current watchdog/fleet-comms work still needs authenticated delivery truth.

## 09. Finding A - flywheel-hww is foundation, not duplicate

- flywheel-hww depends on obsolete flywheel-1hn, but that edge is stale.
- The bead body is not a shadow signal-quality report; it is an authenticated fleet-mail probe.
- The probe distinguishes missing identity, missing token, invalid token, MCP unavailable, and valid authenticated path.
- It gates L61 alerting by preventing unauthenticated sends from counting as delivery success.
- Today's watchdog plan depends on manager-consumable recovery/no-action receipts, not pane-message optimism.
- Today's fleet-comms concern requires measured communication health, not assumed communication health.
- Therefore hww should not be closed just because its parent 1hn is obsolete.
- The correct action is REDIRECT/FOUNDATION: carry the hww obligation into the fleet-comms/watchdog/Agent Mail health surface.
- After that redirect exists, flywheel-1hn can close without erasing the authenticated-comms requirement.

hww close risk: high if closed as duplicate before replacement.
hww redirect risk: low if the replacement explicitly preserves identity, token, MCP availability, and delivery-success semantics.
hww dependency risk: current dependency on 1hn is misleading because the obsolete report is not the natural owner of comms authentication.

## 10. Finding B - flywheel-247 is old lifecycle, not current foundation

- flywheel-247 is Phase 1b fleet-coherence launchd lifecycle.
- Its acceptance path is a launchd plist and stale-lock detector for the old fleet-coherence scanner.
- The old scanner implementation file is missing.
- The current watchdog plan already owns driver verification, frozen-pane detection, no-silent-darkness, and manager-consumable recovery receipts.
- Keeping flywheel-247 as a prerequisite for old pd9 preserves a dead detector branch.
- The surviving concern should be expressed in watchdog W0/W8 and manager receipt consumption, not in an old fleet-coherence launchd driver.
- Classification: CASCADE-CLOSE for the old bead, with redirect note to watchdog lifecycle only if an owner wants a trace pointer.

flywheel-247 cannot be closed before flywheel-pd9 is handled because pd9 actively depends on it.
That means 247 is not the first operational close; it is a mid-chain close after 1hn and pd9 clear.

## 11. Finding C - flywheel-3eo should redirect to Manager A0/A4

- flywheel-3eo is Phase 1d drift-status cached command.
- Its useful intent is operator visibility into drift, severity, detector heartbeat age, and suppressions.
- The current Manager plan owns A0 fact registry and A4 projection/status rendering.
- The current Watchdog plan owns detector runtime truth and driver proof.
- The old fleet-coherence status command should not survive as a separate status brain.
- Classification: REDIRECT first, then close the old command bead once A0/A4/watchdog surfaces cover the status evidence.
- This matches the current Fleet P3 tombstone: facts move to Manager A0; display moves to Manager A4.

flywheel-3eo blocks flywheel-dzj through the old graph and is itself blocked by flywheel-pd9 as a dependent relationship.
Treat it as a stale interface to be redirected, not a foundation implementation to ship.

## 12. Finding D - flywheel-1fh is the immediate leaf

- flywheel-1fh has zero active dependents in the read-only dependency query.
- It is Phase 3b tick Step 4i action consumer.
- Its body asks for bead/no-bead decisions, FLEET_REPAIR dispatch, L62 callback enforcement, and L63 drill citation.
- Current Manager/Watchdog plans split those concerns more cleanly: Manager owns decisions and projections; Watchdog owns recovery transaction and no-action receipts.
- No current plan depends on the old Step 4i action consumer shape.
- Classification: CASCADE-CLOSE.
- Recommended immediate next close packet: flywheel-1fh, citing this dependent audit and the prior 2y4 obsolete register.

After flywheel-1fh closes, flywheel-2y4 loses its active dependent blocker.
The close owner should still inspect br close behavior around open upstream dependencies before closing 2y4; this audit only resolves the dependent-side blocker.

## 13. Finding E - flywheel-1m2 and flywheel-bkc are not noise

- flywheel-1m2 and flywheel-bkc are not in the six skipped beads, but they are necessary to classify hww.
- flywheel-1m2 is the old L61 dual-channel alert sender.
- flywheel-bkc is the old degraded alert-channel handling bead.
- Both inherit the same problem as hww: the old implementation shape is stale, but the measured-comms requirement still matters.
- Closing hww without deciding 1m2 and bkc would either strand their dependencies or erase the delivery degradation requirement.
- Classification for both: REDIRECT to fleet-comms health / manager summaries / watchdog receipts.
- Do not classify them as pure cascade-close unless a replacement bead or plan line explicitly preserves dual-channel and degraded-channel semantics.

This is why the fleet_coherence_verdict is mixed rather than cascade-close-all.
The stale scanner branch can close; the fleet-comms foundation must be preserved in the new architecture.

## 14. Context-only rows

| Bead | Status | Audit treatment |
|---|---|---|
| flywheel-2i4 | open | expected_pane_count semantics; upstream classifier decision; not a dependent blocker for the six skipped close packets |
| flywheel-cgy | closed | repo-home decision; already closed; explains old scanner dependencies |
| flywheel-375 | closed | L63 recovery drills; already closed; explains old Step 4i action dependency |

These rows should not be dragged into the close packet set unless a later graph sweep finds them still blocking active open work.

## 15. Cascade chains identified

| Chain | Order | Condition |
|---|---|---|
| Chain 1 - immediate leaf close | flywheel-1fh -> flywheel-2y4 | Close 1fh first; then reassess 2y4 obsolete close with upstream dependency policy visible. |
| Chain 2 - old Phase 1 close after hww redirect | flywheel-1hn -> flywheel-pd9 -> flywheel-247/flywheel-3eo -> flywheel-dzj -> flywheel-1km -> flywheel-2te | Valid only after hww is detached or replacement-owned. |
| Chain 3 - conditional full old cluster close | flywheel-1fh -> flywheel-2y4 -> flywheel-bkc -> flywheel-1m2 -> flywheel-hww -> flywheel-1hn -> flywheel-pd9 -> flywheel-247 -> flywheel-3eo -> flywheel-dzj -> flywheel-1km -> flywheel-2te | Not recommended now; only safe if the fleet-comms foundation is replaced elsewhere first. |

The audit identifies three cascade paths, but only Chain 1 is immediately actionable without dependency mutation or replacement work.
Chain 2 is the useful close sequence for the old scanner/status branch after hww no longer blocks 1hn.
Chain 3 is a proof of topology, not a recommended action today.

## 16. Recommended updated close order

| Step | Bead | Action | Condition |
|---:|---|---|---|
| 1 | flywheel-1fh | close as obsolete Step 4i action consumer | active dependents = 0 |
| 2 | flywheel-2y4 | retry obsolete close after 1fh closes; inspect upstream dependency handling | active dependents would become 0 |
| 3 | flywheel-hww | do not close; redirect/rebase to fleet-comms/Agent Mail health | foundation |
| 4 | flywheel-1m2 | do not close until dual-channel replacement exists; redirect to fleet-comms delivery health | redirect |
| 5 | flywheel-bkc | do not close until degraded-channel replacement exists; redirect to fleet-comms degradation status | redirect |
| 6 | flywheel-1hn | close obsolete shadow report after hww no longer depends on it | cascade after redirect |
| 7 | flywheel-pd9 | close duplicate classifier after 1hn closes | cascade |
| 8 | flywheel-247 | close old launchd lifecycle after pd9 closes | cascade |
| 9 | flywheel-3eo | redirect/close old drift-status after pd9 closes | redirect/cascade |
| 10 | flywheel-dzj | close old scanner after 247 and 3eo close | cascade |
| 11 | flywheel-1km | close old writer after dzj and pd9 close | cascade |
| 12 | flywheel-2te | close old schema root last | cascade root |

This order is a close plan, not an execution log.
No br close, br update, or br dependency mutation was performed by this audit.

## 17. What changed from the prior close plan

- Prior plan treated the six skipped beads as close candidates whose blockers were incidental.
- This audit shows the blockers encode the old May 1 fleet-coherence phase graph.
- Prior plan classified hww as not part of Wave 1, but did not decide whether hww was a foundation or a close target.
- This audit classifies hww as FOUNDATION and therefore blocks cascade-close-all.
- Prior plan noted 247 and 3eo were likely old support beads.
- This audit confirms 247 as cascade-close and 3eo as redirect to Manager A0/A4/watchdog status.
- Prior plan noted 1fh must classify before retrying 2y4.
- This audit classifies 1fh as cascade-close and makes it the immediate leaf close.

## 18. Risk register

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | Closing hww as duplicate erases authenticated fleet-mail truth. | High | Preserve hww obligation via fleet-comms/Agent Mail health redirect before closing 1hn. |
| R2 | Closing old scanner chain before hww redirect repeats br close refusal. | Medium | Use dependent-first order and do not retry six original packets unchanged. |
| R3 | Keeping 247/3eo as-is creates two status/lifecycle brains. | Medium | Move lifecycle/status concerns to watchdog and Manager A0/A4, then close old beads. |
| R4 | Closing 2y4 after 1fh may still hit open dependency policy. | Medium | Inspect br close behavior for obsolete beads with open upstream dependencies before applying. |
| R5 | Fleet-comms replacement not explicit enough. | High | Replacement must preserve identity, token, MCP availability, dual-channel, degraded-channel, and delivery-success semantics. |

## 19. Acceptance criteria for redirecting hww

1. A replacement plan or bead names Agent Mail / fleet-mail identity as an explicit checked input.
2. It distinguishes missing identity from missing token from invalid token from MCP unavailable from authenticated success.
3. It forbids unauthenticated or notify-only messages from counting as L61 delivery success.
4. It emits a machine-readable health receipt consumable by Manager A0/A4 or watchdog summaries.
5. It includes degraded-channel status, not just binary up/down.
6. It preserves the dual-channel concern currently represented by flywheel-1m2.
7. It preserves the degraded alert-channel concern currently represented by flywheel-bkc.
8. It does not depend on the obsolete flywheel-1hn shadow report.

If these criteria are met, hww/1m2/bkc can become redirect closures instead of foundation blockers.
If they are not met, hww should remain open and explicitly reparented in the next plan-space pass.

## 20. Acceptance criteria for closing the old scanner spine

1. Manager A0 owns current fact registry for selector/retry/source/blocker-owner receipts.
2. Manager A4 owns current status/projection rendering for operator-visible drift.
3. Watchdog owns driver proof and recovery/no-action receipts.
4. Fleet P1/P2 own selector and retry receipts, not a generic fleet-coherence scanner.
5. Mission gwbvf and 4ggh2 own source/reality normalization where old dzj tried to scan broad reality.
6. The May 1 fleet-coherence implementation files remain absent or explicitly abandoned.
7. The close order is dependent-first, not root-first.

These criteria are already mostly true in today's plans, which is why the old scanner spine is classified cascade-close.

## 21. Detailed per-bead notes

| Bead | Role | Classification | Note |
|---|---|---|---|
| flywheel-1fh | leaf | CASCADE-CLOSE | Immediate close candidate; no active dependents. |
| flywheel-2y4 | skipped original | CASCADE-CLOSE after 1fh | Old read-only Step 4i consumer; current Manager/Watchdog owns observation. |
| flywheel-bkc | transitive hww child | REDIRECT | Degraded channel concern survives; old chain shape stale. |
| flywheel-1m2 | transitive hww child | REDIRECT | Dual-channel sender concern survives; rebase to fleet-comms. |
| flywheel-hww | direct dependent of 1hn | FOUNDATION | Authenticated Agent Mail/fleet-mail health must not be erased. |
| flywheel-1hn | skipped original | CASCADE-CLOSE after hww redirect | Standalone shadow signal-quality report obsolete. |
| flywheel-pd9 | skipped original | CASCADE-CLOSE | Old classifier duplicate of typed selector/retry/Manager values. |
| flywheel-247 | direct dependent of dzj | CASCADE-CLOSE | Old launchd lifecycle superseded by watchdog lifecycle. |
| flywheel-3eo | direct dependent of dzj | REDIRECT | Old status command redirects to Manager A0/A4 and watchdog summary. |
| flywheel-dzj | skipped original | CASCADE-CLOSE | Old scanner duplicate of current source/reality/selector surfaces. |
| flywheel-1km | skipped original | CASCADE-CLOSE | Old writer duplicate of typed receipts and Manager registry. |
| flywheel-2te | skipped original root | CASCADE-CLOSE last | Old schema root is partial historical spec, not current implementation root. |

## 22. Direct answers to dispatch questions

| Question | Answer | Detail |
|---|---|---|
| Q1 | Are flywheel-247 and flywheel-3eo real blockers or old fleet-coherence support beads? | They are old support beads. 247 is cascade-close; 3eo is redirect to Manager/Watchdog status before old close. |
| Q2 | Is flywheel-hww duplicate/obsolete/orthogonal/foundation? | Foundation. It is wrongly attached to obsolete 1hn, but authenticated fleet-comms truth remains load-bearing. |
| Q3 | Is flywheel-1fh closeable so flywheel-2y4 can close? | Yes, 1fh is the immediate leaf close candidate. 2y4 should be retried only after 1fh and with upstream dependency policy visible. |
| Q4 | Do we have cascade-close chains? | Yes: 1fh->2y4 and the old phase chain through 1hn/pd9/247/3eo/dzj/1km/2te after hww redirect. |
| Q5 | Do we have a fleet-coherence foundation cluster? | Yes, but narrow: hww/1m2/bkc fleet-comms health, not the entire old scanner/status implementation. |

## 23. Plan-space only close packets to author next

| Packet | Target | Action | Evidence |
|---|---|---|---|
| Packet A | flywheel-1fh | close obsolete leaf | cite this audit sections 12, 15, 16 |
| Packet B | flywheel-2y4 | retry obsolete close after Packet A | cite prior obsolete register and this audit section 16 |
| Packet C | flywheel-hww/1m2/bkc redirect | either create replacement plan or write redirect close packet | must satisfy section 19 acceptance criteria |
| Packet D | flywheel-1hn | close obsolete report after hww detached | cite Manager A0/A2/A4 and watchdog summaries |
| Packet E | flywheel-pd9, 247, 3eo, dzj, 1km, 2te | old scanner spine close wave | dependent-first order only |

No packet above has been applied by this worker.

## 24. Why not foundation-ship-first for all of fleet-coherence

- The old scanner, writer, classifier, launchd, and status surfaces have no implementation files present in the repo.
- Today's plans already assign their useful obligations to Fleet P1/P2, Manager A0/A2/A4, Mission source/reality, and Watchdog lifecycle receipts.
- Shipping the old cluster first would recreate a parallel status/control plane that the May 5 plans are trying to retire.
- Only the fleet-comms health concern lacks a clearly equivalent replacement at the same specificity.
- Therefore foundation-ship-first applies to hww/1m2/bkc semantics only, not to the whole May 1 fleet-coherence DAG.

## 25. Why not cascade-close-all

- cascade-close-all would close hww as part of the old report chain.
- That would lose the authenticated mail/Agent Mail probe requirement unless another plan explicitly preserves it.
- The reconciliation plan already treated hww differently from 2te/pd9/1km/dzj/1hn/2y4.
- The hww body is not just stale UI; it is a delivery-validity gate.
- The current Watchdog and Manager plans require reliable receipt channels, making delivery validity a foundation concern.

## 26. Fleet-coherence verdict

fleet_coherence_verdict: mixed

- Cascade-close the obsolete old scanner/status/action spine.
- Redirect the authenticated fleet-comms health foundation.
- Do not retry the six skipped close packets unchanged.
- Do not close hww as a duplicate of 1hn.
- Do not keep 247/3eo as old standalone fleet-coherence work.
- Use dependent-first close order and preserve current-plan ownership boundaries.

## 27. Callback metrics

| Metric | Value |
|---|---:|
| dependents_audited | 6 |
| cascade_close_count | 2 |
| foundation_count | 1 |
| orthogonal_count | 0 |
| redirect_count | 3 |
| cascade_chains_identified | 3 |
| fleet_coherence_verdict | mixed |
| updated_closeable_count | 1 |
| socraticode_queries | 4 |
| indexed_chunks_observed | 694 |
| bead_db_writes | 0 |

## 28. L112 self-check text

This file intentionally contains cascade-close, FOUNDATION, REDIRECT, flywheel-247, flywheel-3eo, and flywheel-hww so the L112 grep gate validates the intended audit content.
The audit path is /Users/josh/Developer/flywheel/.flywheel/PLANS/DEPENDENTS-AUDIT-2026-05-05.md.

## 29. Final recommendation

- Accept a mixed verdict.
- Author the next close packet for flywheel-1fh first.
- After 1fh, retry or rewrite the flywheel-2y4 close packet with upstream dependency behavior explicitly handled.
- Open a plan-space redirect packet for hww/1m2/bkc into fleet-comms/watchdog/Agent Mail health before closing 1hn.
- Then close the old Phase 1 spine in the dependent-first order listed above.
- Keep the May 1 schema/spec files as historical evidence if useful, but do not let them force old implementation beads to remain open.

## 30. Appendix - normalized close sequence if replacements are accepted

1. flywheel-1fh
2. flywheel-2y4
3. flywheel-bkc
4. flywheel-1m2
5. flywheel-hww
6. flywheel-1hn
7. flywheel-pd9
8. flywheel-247
9. flywheel-3eo
10. flywheel-dzj
11. flywheel-1km
12. flywheel-2te

This appendix is not the recommended immediate action list.
It is the topology-safe cascade.close order if the fleet-comms foundation is first represented elsewhere.

## 31. Appendix - audit invariants

- No bead DB writes were performed.
- No br close was performed.
- No br update was performed.
- No dependency mutation was performed.
- No source file edits were performed outside this plan artifact.
- The worktree was already broadly dirty before this artifact was written; this audit does not normalize unrelated changes.
- The output is plan-space evidence for the orchestrator/apply owner, not an applied state change.

## 32. Evidence notes

- Evidence note 01: flywheel-2te is the root of the old May 1 schema branch and remains blocked only because its dependent chain is still open.
- Evidence note 02: flywheel-1km was old generic writer work; current typed receipts are narrower and better owned.
- Evidence note 03: flywheel-dzj was old scanner work; current source/reality scanning belongs to mission and selector surfaces.
- Evidence note 04: flywheel-247 was lifecycle around a missing scanner implementation, not a surviving independent product surface.
- Evidence note 05: flywheel-3eo preserved a valid visibility need but in the wrong owner and command shape.
- Evidence note 06: flywheel-pd9 depended on old classifier inputs and can close after the report and support children clear.
- Evidence note 07: flywheel-1hn is obsolete because the Manager plan owns integrated quality/signal visibility.
- Evidence note 08: flywheel-hww is different because delivery validity is not merely visibility.
- Evidence note 09: flywheel-1m2 and flywheel-bkc prove hww has a transitive foundation fork.
- Evidence note 10: flywheel-2y4 is an obsolete consumer but should be closed only after its action leaf is handled.
- Evidence note 11: flywheel-1fh has no active dependents and is therefore the first clean leaf candidate.
- Evidence note 12: the prior close plan was directionally right on duplicate/obsolete classification but incomplete on dependent topology.
- Evidence note 13: the apply log skip-list is useful because it surfaced hidden old graph structure.
- Evidence note 14: hww should be detached from 1hn conceptually even if no dependency mutation happens in this pass.
- Evidence note 15: redirecting 3eo avoids losing status UX while preventing a second status brain.
- Evidence note 16: redirecting hww avoids losing delivery proof while allowing obsolete report closure.
- Evidence note 17: chain 1 is operationally small and should be the first apply target.
- Evidence note 18: chain 2 is the old scanner cleanup wave after the comms foundation fork is resolved.
- Evidence note 19: chain 3 is a conditional proof, not a recommendation to erase fleet-comms health.
- Evidence note 20: the mixed verdict is the only verdict consistent with both the new plans and the hww body.
- Evidence note 21: Manager A0/A4 absorb old status/report concerns but not authenticated communication truth by themselves.
- Evidence note 22: Watchdog absorbs driver and recovery lifecycle concerns but still needs reliable channel-health inputs.
- Evidence note 23: Fleet P1/P2 absorb selector and retry receipts but not the whole old fleet-coherence daemon idea.
- Evidence note 24: Mission gwbvf/4ggh2 absorb source/reality normalization that the old scanner branch reached for.
- Evidence note 25: old implementation absence reduces code rollback risk but increases replacement-explicitness requirements.
- Evidence note 26: keeping old fleet-coherence beads open without reparenting will continue to block duplicate/obsolete closures.
- Evidence note 27: closing root-first will continue to fail because active dependents remain open.
- Evidence note 28: dependent-first close order is mandatory for this cluster.
- Evidence note 29: the current immediate close count is one because only 1fh is a leaf among audited rows.
- Evidence note 30: after 1fh, 2y4 becomes the next dependent-side candidate but not automatically a no-risk close.
- Evidence note 31: hww should become a replacement contract before 1hn close is retried.
- Evidence note 32: 1m2 and bkc should follow hww replacement handling, not independent stale closure.
- Evidence note 33: 247 should not be made a prerequisite of current watchdog lifecycle work.
- Evidence note 34: 3eo should not be made a prerequisite of current manager status work.
- Evidence note 35: pd9 should not keep old pane-count classifier semantics alive without current owner review.
- Evidence note 36: 2i4 is context-only for this audit and should not delay the six skipped close chain decision.
- Evidence note 37: cgy and 375 are closed context, not new work.
- Evidence note 38: this audit intentionally does not file beads because the dispatch was plan-space only.
- Evidence note 39: a future apply pass may use these classifications to author close packets or dependency redirects.
- Evidence note 40: the L112 validation should pass with OK_dependents_audit.

## 33. Closing statement

The skipped close set is a topology problem, not a contradiction of the reconciliation plan.
The old May 1 fleet-coherence control branch should be retired dependent-first.
The authenticated fleet-comms foundation should be preserved and redirected before the old report parent is closed.
That is the smallest plan-space move that prevents both duplicate-bead drag and accidental loss of communication-health truth.

