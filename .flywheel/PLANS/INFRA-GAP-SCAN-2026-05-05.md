---
title: "INFRA GAP SCAN 2026-05-05"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Executive Summary](#executive-summary)
- [Method](#method)
- [Dimension 1: Loop Drivers](#dimension-1-loop-drivers)
- [Dimension 2: Dispatch-Log Freshness](#dimension-2-dispatch-log-freshness)
- [Dimension 3: Fuckup-Log Signal](#dimension-3-fuckup-log-signal)
- [Dimension 4: Session Topology Drift](#dimension-4-session-topology-drift)
- [Dimension 5: br/bv Health](#dimension-5-br-bv-health)
- [Dimension 6: Stale /tmp Dispatch Files](#dimension-6-stale-tmp-dispatch-files)
- [Dimension 7: Dirty-Tree Gaps](#dimension-7-dirty-tree-gaps)
- [Dimension 8: INCIDENTS Log Adds](#dimension-8-incidents-log-adds)
- [Cross-Dimension Pattern Table](#cross-dimension-pattern-table)
- [Wave-0 Candidate List](#wave-0-candidate-list)
- [Quick-Fix List](#quick-fix-list)
- [Long-Tail List](#long-tail-list)
- [Pattern to Doctrine Candidates](#pattern-to-doctrine-candidates)
- [Gap Register](#gap-register)
- [Evidence Appendix: Loop Drivers](#evidence-appendix-loop-drivers)
- [Evidence Appendix: Dispatch Log](#evidence-appendix-dispatch-log)
- [Evidence Appendix: Fuckup Log](#evidence-appendix-fuckup-log)
- [Evidence Appendix: Topology and Agent Mail](#evidence-appendix-topology-and-agent-mail)
- [Evidence Appendix: br/bv](#evidence-appendix-br-bv)
- [Evidence Appendix: /tmp and Dirty Tree](#evidence-appendix-tmp-and-dirty-tree)
- [Close-Order Detail](#close-order-detail)
- [Non-Goals](#non-goals)
- [Callback Metrics](#callback-metrics)
- [L112 Readiness](#l112-readiness)
# INFRA GAP SCAN 2026-05-05

Scan time: 2026-05-05T19:30Z.
Repo: `/Users/josh/Developer/flywheel`.
Mode: plan-space only.
Mutation boundary: no bead DB writes, no `br create`, no `br update`, no `br close`.
Primary lens: what substrate must be repaired before wave-1 fires.
Socraticode preflight: 4 queries, 40 indexed chunks observed.
Skills consulted: `multi-pass-bug-hunting`, `flywheel-doctor-author`, `jeff-swarm-ops`, `canonical-cli-scoping`, `substrate-bleed-triage`, `protected-session-recovery`, `agent-lifecycle`.
Skill search: `/flywheel:skills-best-practices "infra gap substrate health drift stale fuckup log dispatch loop"` equivalent returned `socraticode`, `system-health`, `install-substrate`, `donella-meadows-systems-thinking`, `flywheel-doctor-author`, `loop-enforcement`.
Evidence sources: loop markers, dispatch log, fuckup log, topology ledger, Agent Mail identity registry, br/bv commands, `/tmp/dispatch_*.md`, INCIDENTS files, and git status.

## Executive Summary

1. Close loop-driver truth first: 2 active markers point at project launchd labels that are not loaded, while 5 loop files are being refreshed by writeback-only runs with `prompt_file=null`.
2. Drain dispatch freshness next: normalized scan found 86 unresolved dispatch records older than 24h and 119 unresolved under 24h, with recent live work also missing callbacks.
3. Process fuckup backlog before adding wave-1 load: 1,075 rows in 72h, 864 unprocessed, and 14 trauma classes recurring 3+ times today.
4. Repair bead substrate before broad bead work: flywheel `br doctor` is OK, but `br dep cycles --json` hit DB busy; mobile-eats, alpsinsurance, and picoz bead DBs fail read-only integrity.
5. Stop dirty-tree and temp-file bleed: core four repos show 47 tracked dirty files via `git status -uno`; `/tmp` holds 1,018 dispatch files, 438 older than 24h.
6. Recommended close-order: driver truth -> dispatch/callback reaper -> fuckup triage -> bead DB recovery -> Agent Mail role/key correction -> dirty-tree plan commits -> `/tmp` dispatch retention -> INCIDENTS promotion pass.

## Method

M1. I treated "gap" as an observable substrate mismatch, backlog, stale marker, corrupted store, or missing recovery path.
M2. I did not mutate Beads state.
M3. I did run read-only `br doctor`, `br dep cycles --json`, and SQLite `pragma integrity_check` with mode=ro.
M4. I treated command output as evidence when no durable artifact existed.
M5. I cited durable file lines where available.
M6. I used the latest current time from local UTC probes around 2026-05-05T19:28Z to age records.
M7. I normalized dispatch staleness by matching `task_id` across dispatch and callback records.
M8. I did not count callback records themselves as stale dispatches.
M9. I treated inactive loop markers updated by writeback as stale-marker drift because stopped loops should not receive fresh driver proof.
M10. I treated project-specific launchd labels not loaded as a stronger signal than marker `driver_status=VERIFIED`.
M11. I treated generic `com.flywheel.tick` as a real loaded driver, but not as proof that per-project prompt delivery is working.
M12. I treated `prompt_file=null` and empty `send_output_tail` in driver ledgers as writeback-only evidence, not pane-prompt delivery evidence.
M13. I did not print or inspect raw Agent Mail token values.
M14. I inspected token file names, sizes, mtimes, and permissions only.
M15. I included VRTX and picoz as flywheel-touched repos even though the dispatch named the core four for git status.
M16. I used the dispatch packet's eight requested dimensions as the report structure.
M17. I scored wave-0 by "will corrupt coordination or make wave-1 invisible if left open."
M18. I scored quick-fix by likely <30 minute local remediation and low blast radius.
M19. I scored long-tail by requiring design, cross-repo migration, protected client coordination, or multiple owners.
M20. I did not ask Joshua questions.

## Dimension 1: Loop Drivers

D1.G1. Active loop markers are not backed by their project-specific launchd labels.
D1.G1 Evidence: `~/.flywheel/loops/flywheel.json` has `active=true`, `dispatch_mode=launchd_prompt`, `plist_label=ai.zeststream.flywheel-flywheel-loop`, `driver_status=VERIFIED`.
D1.G1 Evidence: `~/.flywheel/loops/vrtx.json` has `active=true`, `dispatch_mode=launchd_prompt`, `plist_label=ai.zeststream.vrtx-flywheel-loop`, `driver_status=VERIFIED`.
D1.G1 Evidence: `launchctl print gui/$(id -u)/ai.zeststream.flywheel-flywheel-loop` returned not loaded.
D1.G1 Evidence: `launchctl print gui/$(id -u)/ai.zeststream.vrtx-flywheel-loop` returned not loaded.
D1.G1 Evidence: `launchctl print gui/$(id -u)/com.flywheel.tick` returned loaded.
D1.G1 Interpretation: current truth is a generic tick process, not the project-specific driver named by the markers.
D1.G1 Risk: L57 says marker proof is not driver proof; this is exactly the marker/driver split.
D1.G1 Remediation: add a doctor invariant that marks active loops `STALE_GENERIC_WRITEBACK` when only `com.flywheel.tick` is loaded and project label is absent.
D1.G1 Remediation: either load the project labels or rewrite markers to honestly name `com.flywheel.tick` as the driver.
D1.G1 Remediation: require pane-prompt proof, not only writeback proof, before `driver_status=VERIFIED`.
D1.G1 Wave-0: yes.
D1.G1 Owner surface: flywheel loop driver and doctor.

D1.G2. Loop-driver ledger shows writeback-only runs for all projects.
D1.G2 Evidence: `~/.local/state/flywheel/loop-driver-runs.jsonl#L421-L425` records five fresh runs at `2026-05-05T19:26:31Z`.
D1.G2 Evidence: each row has `mode=writeback`, `prompt_file=null`, and `send_output_tail=""`.
D1.G2 Evidence: rows cover `flywheel`, `skillos`, `mobile-eats`, `alpsinsurance`, and `vrtx`.
D1.G2 Interpretation: no prompt file was sent during these loop-driver rows.
D1.G2 Risk: a loop can look fresh while doing no pane work.
D1.G2 Remediation: split driver ledgers into `writeback_observed` and `prompt_dispatched`.
D1.G2 Remediation: only `prompt_dispatched` may update `last_tick_source` for active loops.
D1.G2 Remediation: make `prompt_file=null` incompatible with `driver_status=VERIFIED` on active launchd-prompt loops.
D1.G2 Wave-0: yes.
D1.G2 Doctrine link: AGENTS L57 and flywheel-end-to-end INCIDENTS loop-state-without-driver.

D1.G3. Inactive loops are still receiving fresh writeback updates.
D1.G3 Evidence: `~/.flywheel/loops/alpsinsurance.json` has `active=false` and `deactivated_reason=stale loop firing UserPromptSubmit hooks...`.
D1.G3 Evidence: the same marker has `last_tick=2026-05-05T19:26:31Z` and `last_tick_source=flywheel-loop-driver-writeback`.
D1.G3 Evidence: `~/.flywheel/loops/mobile-eats.json` has `active=false`, `stopped_at=2026-05-05T15:31:52Z`, and `stopped_by=Joshua manual stop request`.
D1.G3 Evidence: mobile-eats still has `last_tick=2026-05-05T19:26:31Z`.
D1.G3 Evidence: `~/.flywheel/loops/skillos.json` has `active=false`, `stopped_at=2026-05-05T16:50:00Z`, and still has `last_tick=2026-05-05T19:26:31Z`.
D1.G3 Interpretation: stopped loops can receive fresh-looking health.
D1.G3 Risk: inactive loops look alive to downstream automation and dashboards.
D1.G3 Remediation: writeback driver must skip inactive markers or update a separate `last_observed_at`, not `last_tick`.
D1.G3 Remediation: doctor should emit a hard warning when `active=false` and `last_tick > stopped_at`.
D1.G3 Wave-0: yes.

D1.G4. Marker schema still conflates driver config, loaded status, and prompt delivery.
D1.G4 Evidence: markers carry `driver_status=VERIFIED` even when the project launchd labels are not loaded.
D1.G4 Evidence: driver ledger records status `ok` with no prompt file.
D1.G4 Evidence: L57 requires driver verification distinct from loop state markers.
D1.G4 Risk: orchestration can report "active" from a marker field without proving work reached a pane.
D1.G4 Remediation: add three fields: `label_loaded`, `script_contains_ntm_send`, `last_prompt_delivery_proof`.
D1.G4 Remediation: `driver_status` should be derived from those fields.
D1.G4 Quick-fix: yes, as a doctor/reporting change.
D1.G4 Long-tail: marker migration across sibling repos.

D1.G5. Project-specific launchd plists exist as marker paths but are not loaded.
D1.G5 Evidence: marker paths include `~/Library/LaunchAgents/ai.zeststream.*-flywheel-loop.plist`.
D1.G5 Evidence: launchctl reported all five `ai.zeststream.*-flywheel-loop` labels not loaded.
D1.G5 Evidence: only `com.flywheel.tick` was loaded among checked labels.
D1.G5 Risk: launchd persistence and marker metadata disagree after reboot or manual stop.
D1.G5 Remediation: reconcile loaded labels with marker labels in one idempotent script.
D1.G5 Remediation: mark a label `missing`, `present_not_loaded`, `loaded_stale`, or `loaded_current`.
D1.G5 Quick-fix: yes for diagnosis; apply must be gated.

D1.G6. Loop-driver reference implementation is split.
D1.G6 Evidence: ALPS marker points to `/Users/josh/.local/bin/alps-flywheel-loop-tick`.
D1.G6 Evidence: flywheel and VRTX markers point to `/Users/josh/.local/bin/flywheel-loop-driver-writeback`.
D1.G6 Evidence: mobile-eats points to `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh`.
D1.G6 Evidence: skillos points to `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`.
D1.G6 Risk: different scripts imply different truth semantics and different delivery receipts.
D1.G6 Remediation: define one canonical driver contract and make wrappers call it.
D1.G6 Remediation: create compatibility adapters only where mission-lock needs repo-local behavior.
D1.G6 Long-tail: yes.

D1.G7. Active marker count is 2, stale marker count is 5 by truth reconciliation.
D1.G7 Evidence: active markers: flywheel and VRTX.
D1.G7 Evidence: stale active markers: flywheel and VRTX due project labels not loaded.
D1.G7 Evidence: stale inactive markers: ALPS, mobile-eats, skillos due stopped markers refreshed after stop.
D1.G7 Callback metric: `stale_loop_markers=5`.
D1.G7 Remediation: fix D1.G1-D1.G3 before claiming loop health.

## Dimension 2: Dispatch-Log Freshness

D2.G1. Normalized dispatch backlog is large.
D2.G1 Evidence: `.flywheel/dispatch-log.jsonl` had 1,649 lines at scan.
D2.G1 Evidence: normalized dispatch events counted 301 records across `dispatch`, `dispatch_sent`, `dispatched`, `manual_dispatch`, `idle_pane_auto_dispatch`, `ntm_dispatch_sent`, and `redispatch`.
D2.G1 Evidence: 86 normalized unresolved dispatches are older than 24h.
D2.G1 Evidence: 119 normalized unresolved dispatches are under 24h.
D2.G1 Interpretation: dispatch log needs a reaper and disposition model, not only append-only callbacks.
D2.G1 Risk: worker capacity and orchestration confidence degrade when old dispatches remain open.
D2.G1 Remediation: build a read-only stale-dispatch classifier first, then a gated reaper.
D2.G1 Remediation: classify stale rows as `callback_received_elsewhere`, `abandoned`, `superseded`, `needs_redispatch`, or `needs_handoff`.
D2.G1 Wave-0: yes.

D2.G2. Active-loop dispatches older than 24h lack callbacks.
D2.G2 Evidence: `.flywheel/dispatch-log.jsonl#L708-L724` includes `ntm_dispatch_sent` loop ticks from 2026-05-03/04 with no resolved callback in normalized scan.
D2.G2 Evidence: `.flywheel/dispatch-log.jsonl#L1119` is `ntm_dispatch_sent` for `flywheel_loop_20260504T184104Z`, still >24h old at scan time.
D2.G2 Risk: active loop marker plus stale loop dispatch creates false confidence.
D2.G2 Remediation: every loop tick dispatch must have a closeout receipt or explicit no-work receipt.
D2.G2 Remediation: stale loop tick dispatches should be auto-disposed if superseded by newer tick receipts.
D2.G2 Quick-fix: add a loop-tick stale disposition rule.

D2.G3. Recent manual dispatches were still unresolved at scan time.
D2.G3 Evidence: `.flywheel/dispatch-log.jsonl#L1647-L1649` records `audit-r2-manager-loop`, `audit-r2-fleet-autonomy`, and `mission-coverage-lens-review` at 2026-05-05T17:30:35Z with no callbacks in the log snapshot.
D2.G3 Evidence: normalized scan showed those three were about 1.99h old.
D2.G3 Risk: recent dispatches may still be valid work, but the log has no expected-by evaluator.
D2.G3 Remediation: use `callback_expected_by` to classify overdue, not just age.
D2.G3 Remediation: parse `+45min` to absolute expected time at dispatch append.
D2.G3 Quick-fix: add expected-by expansion on dispatch write.

D2.G4. Idle pane auto-dispatch generates many unresolved rows.
D2.G4 Evidence: normalized dispatch event counts include 105 `idle_pane_auto_dispatch` records.
D2.G4 Evidence: unresolved recent sample showed many flywheel idle dispatches from `.flywheel/dispatch-log.jsonl#L1576-L1612`.
D2.G4 Evidence: these rows target repeated beads such as `flywheel-useh`, `flywheel-wrrf`, `flywheel-se3h`, and `flywheel-7lby`.
D2.G4 Risk: the feeder is redispatching parent beads or stale contexts without durable closure.
D2.G4 Remediation: idle auto-dispatch should refuse parent beads with open child blockers and require a callback disposition.
D2.G4 Remediation: if a previous dispatch for same bead/pane is unresolved, new dispatch must link `supersedes`.
D2.G4 Wave-0: yes, because it drives worker churn.

D2.G5. Dispatch event vocabulary is too broad.
D2.G5 Evidence: dispatch-like events include `dispatch`, `dispatch_sent`, `dispatched`, `manual_dispatch`, `idle_pane_auto_dispatch`, `ntm_dispatch_sent`, and `redispatch`.
D2.G5 Evidence: callback-like events include `callback_received`, `completion_received`, `manual_completion`, `worker_callback`, and others.
D2.G5 Risk: simple greps and dashboards miscount.
D2.G5 Remediation: define a canonical event schema with `kind=dispatch|callback|disposition|receipt`.
D2.G5 Remediation: legacy events can remain but should be normalized by a read model.
D2.G5 Long-tail: yes.

D2.G6. Some dispatch records carry prompt visibility contradiction.
D2.G6 Evidence: `idle_pane_auto_dispatch` rows show `transport_accepted=true`, `prompt_visible_in_target=false`, `prompt_submitted=false`, `work_started=true`.
D2.G6 Evidence: `.flywheel/dispatch-log.jsonl#L1530-L1612` includes repeated rows with that shape.
D2.G6 Risk: L91 says transport accepted is not work started; these rows report work started while prompt visibility/submission are false.
D2.G6 Remediation: make `work_started=true` invalid unless a pane evidence check passes.
D2.G6 Remediation: add separate `pane_state_after_send` as observation, not proof.
D2.G6 Doctrine candidate: dispatch-delivery-state-machine.

D2.G7. Callback delivery is not consistently appended for external sessions.
D2.G7 Evidence: `cross_orch_input_received` and `completion_received` rows exist for ALPS, but many dispatch-like rows do not have counterpart callback rows.
D2.G7 Risk: cross-orchestrator handoffs rely on human memory or pane scrollback.
D2.G7 Remediation: require every external completion to either reference a dispatch task_id or append a `disposition` row for unmatched work.
D2.G7 Long-tail: yes.

D2.G8. Dispatch freshness requires retention plus active reconciliation.
D2.G8 Evidence: stale dispatch count is 86 over 24h after normalization.
D2.G8 Evidence: `/tmp` has 438 dispatch files older than 24h.
D2.G8 Risk: stale files and stale log rows cross-contaminate; workers can be sent old packets.
D2.G8 Remediation: pair dispatch log reaper with `/tmp/dispatch_*.md` retention.
D2.G8 Wave-0: yes.

## Dimension 3: Fuckup-Log Signal

D3.G1. Fuckup backlog is too large to leave unprocessed.
D3.G1 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl` had 1,283 lines at scan.
D3.G1 Evidence: last 72h total rows: 1,075.
D3.G1 Evidence: last 72h unprocessed rows: 864.
D3.G1 Callback metric: `unprocessed_fuckup_rows_72h=864`.
D3.G1 Risk: new substrate work will repeat failures already logged.
D3.G1 Remediation: run a triage pass that groups by class, links rows to existing beads/incidents, and marks processed only after routing.
D3.G1 Wave-0: yes.

D3.G2. Four dominant classes are swamping the log.
D3.G2 Evidence: 72h top classes include `fleet-propagation-failed=211`, `dispatch_callback_overdue=98`, `owner-custody-missing=71`, and `tick-driver-primitive-failed=70`.
D3.G2 Risk: top classes are infrastructure, not product work.
D3.G2 Remediation: classify all four as wave-0 infrastructure.
D3.G2 Remediation: promote `dispatch_callback_overdue` and `tick-driver-primitive-failed` into doctor gates.
D3.G2 Remediation: route `owner-custody-missing` to protected-session recovery or a domain-specific owner-connect runbook.
D3.G2 Wave-0: yes.

D3.G3. Today has 14 classes recurring 3+ times.
D3.G3 Evidence: today total rows: 659.
D3.G3 Evidence: recurring today classes count: 14.
D3.G3 Evidence: `fleet-propagation-failed=211` rows 698-1049.
D3.G3 Evidence: `dispatch_callback_overdue=96` rows 681-1268.
D3.G3 Evidence: `owner-custody-missing=71` rows 754-1267.
D3.G3 Evidence: `tick-driver-primitive-failed=70` rows 697-1046.
D3.G3 Evidence: `storage-headroom-prune-exhausted=29` rows 696-1045.
D3.G3 Evidence: `skillos-loop-integrity-still-limping=12` rows 1074-1171.
D3.G3 Evidence: `br-sync-stale-db-export-blocked=9` rows 1161-1235.
D3.G3 Evidence: `parent-bead-dispatched-with-open-children=5` rows 1198-1237.
D3.G3 Evidence: `agent-mail-reservation-token-path-gap=4` rows 628-647.
D3.G3 Evidence: `agentmail-beads-db-reservation-conflict=4` rows 1128-1154.
D3.G3 Evidence: `jeff-dedupe-bead-stale-scope=4` rows 1073-1099.
D3.G3 Evidence: `pane-respawn=4` rows 660-732.
D3.G3 Evidence: `parent-redispatched-before-open-child-complete=3` rows 1251-1255.
D3.G3 Evidence: `worker-evidence-file-write-before-reservation=3` rows 1102-1112.
D3.G3 Risk: doctrine ladder is behind event volume.
D3.G3 Remediation: run `/flywheel:learn` promotion pass for these 14 classes.
D3.G3 Callback metric: `doctrine_candidates_count=14`.

D3.G4. Recent rows show Beads concurrency failure recurring during today's plan work.
D3.G4 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1275` logs `br-dep-add-openread-recovered` severity high.
D3.G4 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1277` logs `br-dep-add-openread`.
D3.G4 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1280` logs `beads-db-export-hash-corruption`.
D3.G4 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1281` logs another `br-dep-add-openread`.
D3.G4 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1283` logs `beads-db-malformed`.
D3.G4 Risk: wave-1 bead work will hit the same class unless DB/writer policy is fixed.
D3.G4 Remediation: serialize Beads mutation windows or upgrade `br`/apply L93 fallback as a first-class tool.
D3.G4 Wave-0: yes.

D3.G5. Recent rows show secret-output incidents during dispatch work.
D3.G5 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1271` logs `token-echo`.
D3.G5 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1272` logs `secret-leak` severity high.
D3.G5 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1273` logs `secret-output`.
D3.G5 Risk: dispatch packets and probes still have output-sanitization gaps.
D3.G5 Remediation: add a dispatch lint rule that rejects credential-shaped stdout pipelines.
D3.G5 Remediation: pipe secret values through stdin-only parsing and redacted summaries.
D3.G5 Wave-0: yes for protected client work.

D3.G6. File reservation conflicts are still blocking work.
D3.G6 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1274` logs `file_reservation_conflict`.
D3.G6 Evidence: row says decompose-fleet-autonomy could not create phase 4 beads due active `.beads/*` reservation.
D3.G6 Risk: reservations are working as safety gates, but there is no queue/owner resolution UX.
D3.G6 Remediation: reservation conflicts need a standard "handoff or wait" disposition and auto-renew/expiry dashboard.
D3.G6 Quick-fix: add a reservation conflict readout to worker callbacks.

D3.G7. L112 regex failures are recurring.
D3.G7 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1276` logs `l112-regex-br-dep-cycles-output-mismatch`.
D3.G7 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1278` logs `l112-cycle-probe-regex`.
D3.G7 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1282` logs `l112-regex-false-positive`.
D3.G7 Risk: validation gates fail successful work because they parse prose instead of structured output.
D3.G7 Remediation: prefer `br dep cycles --json` count checks when DB is healthy; otherwise report DB busy separately.
D3.G7 Quick-fix: update dispatch template L112 generators.

D3.G8. Fuckup rows are not consistently linked to processed destinations.
D3.G8 Evidence: 864 of 1,075 72h rows are unprocessed by available processed flags/links.
D3.G8 Evidence: L56 requires promotion from fuckup-log to INCIDENTS to canonical L-rules.
D3.G8 Risk: signal accumulates without closing the learning loop.
D3.G8 Remediation: one daily triage job should group, route, and mark processed with `processed_into`.
D3.G8 Long-tail: yes, because routing must avoid false promotion.

## Dimension 4: Session Topology Drift

D4.G1. Latest topology ledger is compact and stale relative to live sessions.
D4.G1 Evidence: `~/.local/state/flywheel/session-topology.jsonl` has only 22 lines.
D4.G1 Evidence: latest rows cover seven sessions: alpsinsurance, clutterfreespaces, flywheel, mobile-eats, picoz, skillos, and VRTX.
D4.G1 Evidence: `ntm list` shows six live sessions: alpsinsurance, clutterfreespaces, flywheel, mobile-eats, skillos, VRTX.
D4.G1 Risk: topology is manually appended and can lag actual pane state.
D4.G1 Remediation: add a generated topology snapshot separate from canonical human-confirmed rows.
D4.G1 Remediation: dashboards should show both "canonical topology" and "live observed topology."
D4.G1 Quick-fix: yes, read-only reporting.

D4.G2. Flywheel health reports dead panes while topology still expects them.
D4.G2 Evidence: `ntm health flywheel --json` returned overall `error`.
D4.G2 Evidence: flywheel pane 3 is `process_status=exited`.
D4.G2 Evidence: flywheel pane 0 user pane is also `process_status=exited`.
D4.G2 Evidence: topology line 7 expects panes 2,3,4 workers plus pane 1 orchestrator and pane 0 shell.
D4.G2 Risk: worker capacity gate can dispatch into dead or stale panes.
D4.G2 Remediation: update topology or respawn pane 3 before using flywheel worker capacity.
D4.G2 Wave-0: yes if wave-1 uses flywheel pane 3.

D4.G3. Agent Mail roles disagree with topology for flywheel.
D4.G3 Evidence: Agent Mail session registry active rows for flywheel: panes 1,2,3,4.
D4.G3 Evidence: roles are `orch=2`, `worker=2`.
D4.G3 Evidence: topology says pane 1 is orchestrator and panes 2/3/4 are workers.
D4.G3 Evidence: Agent Mail file `~/.local/state/flywheel/agent-mail/sessions/flywheel:2.json` has role `orch`.
D4.G3 Risk: callbacks/reservations can be attributed to the wrong role.
D4.G3 Remediation: correct flywheel:2 role to worker in registry through the identity resolver, not by token editing.
D4.G3 Quick-fix: yes.

D4.G4. Agent Mail roles disagree with topology for ALPS.
D4.G4 Evidence: latest topology line 18 says ALPS pane 1 is orchestrator and panes 2,3,4 are workers.
D4.G4 Evidence: Agent Mail active ALPS roles are `orch=2`, `worker=2`.
D4.G4 Evidence: `~/.local/state/flywheel/agent-mail/sessions/alpsinsurance:3.json` has role `orch`.
D4.G4 Risk: protected client routing can treat a worker as an orchestrator.
D4.G4 Remediation: correct ALPS pane 3 role to worker.
D4.G4 Remediation: do not edit token files; use resolver-mediated registry update.
D4.G4 Wave-0: yes for ALPS protected work.

D4.G5. VRTX Agent Mail project key is not repo-local.
D4.G5 Evidence: VRTX active Agent Mail rows use `/Users/josh/.local/state/flywheel/fleet-mail-project`.
D4.G5 Evidence: topology line 19 describes VRTX as live corrected but with prior missing Agent Mail rows.
D4.G5 Evidence: repo path is `/Users/josh/Developer/vrtx`.
D4.G5 Risk: file reservations and messages can target a shared fleet-mail project rather than the VRTX repo.
D4.G5 Remediation: migrate VRTX session identity primary keys to `/Users/josh/Developer/vrtx`.
D4.G5 Remediation: preserve old rows as inactive audit trail.
D4.G5 Wave-0: yes before VRTX substrate work.

D4.G6. Picoz inactive rows are present while session is not live.
D4.G6 Evidence: topology line 21 says picoz is `metadata_only_not_live`.
D4.G6 Evidence: Agent Mail session registry has inactive picoz panes 1,2,3.
D4.G6 Risk: low if inactive rows remain inactive; high if discovery treats them as usable.
D4.G6 Remediation: ensure active roster filters out inactive rows.
D4.G6 Long-tail: low priority.

D4.G7. Token store has legacy duplicate surfaces.
D4.G7 Evidence: canonical token dir has 18 `.token` files with 0600 permissions.
D4.G7 Evidence: legacy `~/.local/state/flywheel/agent-mail-tokens` has `foggybear.json`, `lavenderglen.json`, `rubycreek.json`, and backups.
D4.G7 Risk: old scripts may read legacy JSON token stores.
D4.G7 Remediation: add a doctor warning for legacy token surfaces and migrate readers to canonical token vault.
D4.G7 Quick-fix: warning only.

D4.G8. NTM health reports user pane errors in multiple sessions.
D4.G8 Evidence: `ntm health alpsinsurance --json` overall error due pane 0 user pane exited.
D4.G8 Evidence: `ntm health mobile-eats --json` overall error due pane 0 user pane exited/stuck.
D4.G8 Evidence: `ntm health skillos --json` overall error due pane 0 user pane exited/stuck.
D4.G8 Evidence: `ntm health vrtx --json` overall error due pane 0 user pane exited.
D4.G8 Risk: health status can overstate operational risk if user panes are intentionally absent.
D4.G8 Remediation: fleet health should separate agent pane health from user/shell pane health.
D4.G8 Quick-fix: yes.

D4.G9. Identity stability rule needs enforcement in callbacks.
D4.G9 Evidence: Socraticode finding: Agent Mail identity key is `(session,pane,fleet_mail_project_key)`, not mailbox name.
D4.G9 Evidence: registry rows include predecessor chains and rotated identities.
D4.G9 Risk: workers may treat mailbox names as stable and lose release tokens after compaction.
D4.G9 Remediation: every callback should include identity primary key text, with token redacted.
D4.G9 Long-tail: callback template migration.

## Dimension 5: br/bv Health

D5.G1. Flywheel br doctor is currently OK but reports pending external import.
D5.G1 Evidence: `br doctor --json` returned `ok=true`.
D5.G1 Evidence: `jsonl.parse` parsed 1,096 records.
D5.G1 Evidence: `sqlite.integrity_check` was OK.
D5.G1 Evidence: `counts.db_vs_jsonl` said both have 1,096 records.
D5.G1 Evidence: `sync.metadata` said "External changes pending import."
D5.G1 Risk: current DB is healthy, but JSONL import/export state may still have pending drift.
D5.G1 Remediation: schedule a guarded `br sync` window after active bead writers complete.
D5.G1 Quick-fix: yes, but not in this plan-space dispatch.

D5.G2. Flywheel `br dep cycles --json` is not reliably readable under current load.
D5.G2 Evidence: command returned `DATABASE_ERROR`, `database is busy`, `snapshot conflict on pages: 929,930`.
D5.G2 Evidence: this happened immediately after `br doctor` was OK.
D5.G2 Risk: read-only validation can fail under concurrent writes or WAL state even when integrity is OK.
D5.G2 Remediation: add retry-with-backoff and lock-aware read model for dependency cycles.
D5.G2 Remediation: keep L112 validation from depending on a single busy-sensitive read.
D5.G2 Wave-0: yes because bead DAG validation is central today.

D5.G3. `bv --check-drift` has no baseline.
D5.G3 Evidence: `bv --check-drift` exited with "Error: No baseline found. Create one with: bv --save-baseline \"description\"".
D5.G3 Risk: drift detection is installed but inoperative.
D5.G3 Remediation: define baseline ownership and create a baseline after current dirty-tree checkpoint.
D5.G3 Quick-fix: yes after tree clean state is established.

D5.G4. mobile-eats bead DB fails integrity.
D5.G4 Evidence: read-only SQLite integrity on `/Users/josh/Developer/mobile-eats/.beads/beads.db` returned `Page 939: never used`.
D5.G4 Evidence: counts still show 177 DB issues and 177 JSONL lines.
D5.G4 Risk: count parity hides page-level corruption.
D5.G4 Remediation: run repo-local beads DB recovery during a writer-free window.
D5.G4 Wave-0: yes if mobile-eats remains in fleet loop.

D5.G5. ALPS bead DB fails integrity badly.
D5.G5 Evidence: read-only SQLite integrity on `/Users/josh/Developer/alpsinsurance/.beads/beads.db` returned freelist error plus pages 919-1017 never used.
D5.G5 Evidence: counts show 1,459 DB issues and 1,459 JSONL lines.
D5.G5 Risk: protected client bead DB is corrupted at page/freelist level despite count parity.
D5.G5 Remediation: use repo-local recovery path with backup, import rebuild, and post-rebuild `br doctor`.
D5.G5 Wave-0: yes for ALPS work.

D5.G6. Picoz bead DB fails integrity.
D5.G6 Evidence: read-only SQLite integrity on `/Users/josh/Developer/polymarket-pico-z/.beads/beads.db` returned many "never used" pages.
D5.G6 Evidence: counts show 2,156 DB issues and 2,156 JSONL lines.
D5.G6 Risk: large historical DB has latent corruption.
D5.G6 Remediation: schedule recovery separately; do not mix with active trading substrate.
D5.G6 Long-tail: protected by project context and safety gates.

D5.G7. skillos bead DB is healthy by read-only scan.
D5.G7 Evidence: skillos integrity OK.
D5.G7 Evidence: 138 DB issues and 138 JSONL lines.
D5.G7 Risk: low, but dirty tree shows uncommitted Beads state.
D5.G7 Remediation: checkpoint after current skillos mission-lock work.

D5.G8. VRTX has no `.beads` directory.
D5.G8 Evidence: `/Users/josh/Developer/vrtx` exists but `.beads` does not.
D5.G8 Risk: if VRTX is treated as flywheel-managed, bead workflow is absent.
D5.G8 Remediation: decide whether VRTX is flywheel-managed; if yes, initialize repo-local Beads after mission lock.
D5.G8 Long-tail: yes.

D5.G9. Beads backup artifacts are accumulating in flywheel.
D5.G9 Evidence: `git status --short` shows many untracked `.beads/beads.db*.bak`, `.aside`, `.corrupt-tree49`, and JSONL backups.
D5.G9 Risk: recovery artifacts can be accidentally committed or confuse repair scripts.
D5.G9 Remediation: add `.beads` recovery artifact retention/ignore policy.
D5.G9 Quick-fix: yes for `.gitignore`/cleanup plan, apply later.

D5.G10. Cross-repo Beads corruption is a pattern, not an isolated incident.
D5.G10 Evidence: current read-only integrity failures in mobile-eats, ALPS, and picoz.
D5.G10 Evidence: fuckup-log recent rows 1275, 1277, 1280, 1281, 1283 show Beads corruption or OpenRead failures today.
D5.G10 Evidence: `INCIDENTS.md#L82-L112` documents `br dep add OpenRead after JSONL rebuild`.
D5.G10 Remediation: upgrade installed `br` or encode L93 fallback as canonical in dispatch templates.
D5.G10 Wave-0: yes.

## Dimension 6: Stale /tmp Dispatch Files

D6.G1. `/tmp` dispatch file count is too high.
D6.G1 Evidence: `/tmp/dispatch_*.md` count is 1,018.
D6.G1 Evidence: 438 are older than 24h.
D6.G1 Evidence: 580 are under 24h.
D6.G1 Evidence: 0 are older than 7d.
D6.G1 Risk: no 7d cleanup emergency, but 24h churn is high.
D6.G1 Remediation: create a retention rule keyed to dispatch-log disposition.
D6.G1 Quick-fix: yes, read-only report first.

D6.G2. Oldest dispatch files are only about 49h old but numerous.
D6.G2 Evidence: oldest sample includes `dispatch_flywheel-fpza_20260503T182608Z.md` at 49.1h.
D6.G2 Evidence: oldest 40 sample is dominated by flywheel dispatches from 2026-05-03.
D6.G2 Risk: this is active churn, not forgotten ancient debris.
D6.G2 Remediation: focus on disposition, not blind cleanup.
D6.G2 Quick-fix: classify older-than-24h files by whether dispatch-log has a resolved callback.

D6.G3. New dispatches keep landing while stale files remain.
D6.G3 Evidence: newest sample includes `dispatch_infra-gap-scan-2026-05-05.md`, `dispatch_open-beads-reconciliation-2026-05-05.md`, and multiple polish/audit dispatches within 20 minutes.
D6.G3 Risk: workers can pick up a stale packet if filenames are manually browsed.
D6.G3 Remediation: include `task_id`, expected pane, and disposition in filename or adjacent index.
D6.G3 Long-tail: dispatch spool redesign.

D6.G4. `/tmp` dispatch files are not linked to a retention index.
D6.G4 Evidence: dispatch files exist as standalone Markdown in `/tmp`.
D6.G4 Evidence: dispatch-log records often include `task_file`, but no cleanup state is visible.
D6.G4 Risk: stale `/tmp` state and stale dispatch-log state diverge.
D6.G4 Remediation: generate `/tmp/dispatch-index.jsonl` or repo-local `.flywheel/dispatch-spool-index.jsonl`.
D6.G4 Quick-fix: yes.

D6.G5. File naming is inconsistent.
D6.G5 Evidence: names include `dispatch_<hash>.md`, `dispatch_<semantic>_2026_05_03.md`, and `dispatch_<semantic>-2026-05-05.md`.
D6.G5 Risk: grep-based cleanup and human scan become unreliable.
D6.G5 Remediation: standardize on `dispatch_<task_id>_<session>_p<pane>_<UTC>.md`.
D6.G5 Long-tail: template migration.

D6.G6. Recent aborted transport left a dispatch-level gap.
D6.G6 Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L1269` logs `ntm-send-aborted-by-cass-similar-work-prompt`.
D6.G6 Evidence: row says pane stayed waiting because CASS similar-work prompt aborted send.
D6.G6 Risk: a dispatch file can exist without being submitted.
D6.G6 Remediation: orchestrator dispatch should always pass the sanctioned no-CASS-check flag where appropriate and verify target pane submission.
D6.G6 Wave-0: yes for dispatch transport.

D6.G7. Dispatch spool has no abandonment receipt.
D6.G7 Evidence: normalized dispatch scan found 86 unresolved dispatches older than 24h.
D6.G7 Evidence: `/tmp` still has 438 dispatch files older than 24h.
D6.G7 Risk: old packets persist without clear "do not execute" marker.
D6.G7 Remediation: stale reaper should append a disposition and optionally move packet to `/tmp/flywheel-dispatch-archive/`.
D6.G7 Quick-fix: yes.

## Dimension 7: Dirty-Tree Gaps

D7.G1. Flywheel repo has 32 tracked dirty files via `git status -uno`.
D7.G1 Evidence: `git status -uno --short` in flywheel returned 32 lines.
D7.G1 Evidence: modified files include `.beads/issues.jsonl`, `AGENTS.md`, `README.md`, templates, scripts, and tests.
D7.G1 Risk: foundational substrate edits are in-flight and uncheckpointed.
D7.G1 Remediation: split into plan-space docs, doctrine surfaces, scripts/tests, and Beads export changes before commit.
D7.G1 Wave-0: yes.

D7.G2. Flywheel has many untracked recovery artifacts and plan outputs.
D7.G2 Evidence: `git status --short` lists many `.beads/beads.db*.bak`, `.aside`, and `.corrupt*` files.
D7.G2 Evidence: untracked plan directories include manager-loop, fleet-autonomy, mission-coverage, watchdog, and substrate-recovery.
D7.G2 Risk: a future commit could accidentally absorb recovery files or omit critical plans.
D7.G2 Remediation: classify untracked files into `commit`, `ignore`, `archive`, `delete-later`.
D7.G2 Quick-fix: yes for classification; apply later.

D7.G3. skillos has 7 tracked dirty files and many backups.
D7.G3 Evidence: `git -C /Users/josh/Developer/skillos status -uno --short` returned 7 lines.
D7.G3 Evidence: modified tracked files include `.beads/issues.jsonl`, `.flywheel/AGENTS-CANONICAL.md`, `.flywheel/MISSION.md`, and tests fixtures.
D7.G3 Risk: skillos loop/mission state remains in-flight while skillos is also a doctrine receiver.
D7.G3 Remediation: checkpoint skillos mission-lock before routing new missing-skill candidates.
D7.G3 Long-tail: yes.

D7.G4. mobile-eats has 4 tracked dirty files plus large validation screenshot dirs.
D7.G4 Evidence: `git -C /Users/josh/Developer/mobile-eats status -uno --short` returned 4 tracked dirty lines.
D7.G4 Evidence: untracked screenshot validation directories span 2026-05-03 through 2026-05-05.
D7.G4 Risk: evidence artifacts can overwhelm repo state and storage.
D7.G4 Remediation: archive or ignore validation screenshots after receipts reference them.
D7.G4 Quick-fix: yes.

D7.G5. ALPS has 4 tracked dirty files and fresh handoffs.
D7.G5 Evidence: `git -C /Users/josh/Developer/alpsinsurance status -uno --short` returned 4 tracked dirty lines.
D7.G5 Evidence: untracked handoffs include `2026-05-05T1921Z` and `2026-05-05T1927Z`.
D7.G5 Risk: protected client state should not be left in ambiguous local-only files.
D7.G5 Remediation: commit or deliberately archive handoffs after client sprint stabilization.
D7.G5 Wave-0: yes for protected client coordination.

D7.G6. VRTX has 23 tracked dirty files and no Beads directory.
D7.G6 Evidence: `git -C /Users/josh/Developer/vrtx status -uno --short` returned 23 tracked dirty lines.
D7.G6 Evidence: dirty files include mission/goal/state, `.mcp.json`, deliverables, scripts, templates, and workers.
D7.G6 Risk: VRTX is active but not fully flywheel-initialized by Beads.
D7.G6 Remediation: decide VRTX fleet status before wave-1; do not assume Beads workflow there.
D7.G6 Long-tail: yes.

D7.G7. Picoz has 35 tracked dirty entries.
D7.G7 Evidence: `git -C /Users/josh/Developer/polymarket-pico-z status -uno --short` returned 35 lines.
D7.G7 Evidence: dirty entries include deleted scheduled task files, `.flywheel` state, lock logs, source code, tests, pycache, and golden data.
D7.G7 Risk: safety-critical repo has wide dirty state.
D7.G7 Remediation: protected-session recovery plan only; do not fold into generic wave-0 unless picoz is active today.
D7.G7 Long-tail: protected repo.

D7.G8. Core four dirty tracked count is 47.
D7.G8 Evidence: flywheel=32, skillos=7, mobile-eats=4, ALPS=4.
D7.G8 Callback metric: `dirty_tree_critical_uncommitted=47`.
D7.G8 Risk: wave-1 could layer new edits on an already dirty substrate.
D7.G8 Remediation: checkpoint or explicitly reserve dirty surfaces before wave-1.
D7.G8 Wave-0: yes.

D7.G9. Dirty tree includes doctrine surfaces.
D7.G9 Evidence: modified surfaces include `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, templates, and mission files across repos.
D7.G9 Risk: doctrine drift can emerge between local repo and propagated templates.
D7.G9 Remediation: run a three-surface doctrine divergence probe after commits settle.
D7.G9 Quick-fix: read-only check first.

D7.G10. Dirty tree includes tests and scripts together.
D7.G10 Evidence: flywheel modified scripts and tests both appear dirty.
D7.G10 Risk: uncommitted script changes may be only partially covered by matching tests.
D7.G10 Remediation: group by script/test pair and run targeted tests before commit.
D7.G10 Long-tail: commit hygiene.

## Dimension 8: INCIDENTS Log Adds

D8.G1. INCIDENTS coverage exists but is fragmented across many skills.
D8.G1 Evidence: `find` located 38 `INCIDENTS.md` files under flywheel and `~/.claude/skills`.
D8.G1 Evidence: recent files include demo-foundation, deadlock-finder-and-fixer, infisical-secrets, flywheel, flywheel-recovery, nango-integrations, jeff-issue-chain, and skill flywheel INCIDENTS.
D8.G1 Risk: relevant incidents may be missed by workers unless dispatch packets name the right skill.
D8.G1 Remediation: add an incident index search command keyed by trauma class.
D8.G1 Long-tail: yes.

D8.G2. Flywheel INCIDENTS has relevant Beads OpenRead doctrine.
D8.G2 Evidence: `/Users/josh/Developer/flywheel/INCIDENTS.md#L82-L112` documents `br dep add OpenRead after JSONL rebuild`.
D8.G2 Evidence: it says installed `br 0.1.20` can still reproduce old failure after upstream `br 0.2.4` fixed WAL/checkpoint.
D8.G2 Risk: current workers are still hitting the exact class today.
D8.G2 Remediation: upgrade `br` or make L93 fallback automatic under lock.
D8.G2 Wave-0: yes.

D8.G3. Flywheel-end-to-end INCIDENTS has the exact loop-driver doctrine.
D8.G3 Evidence: `~/.claude/skills/flywheel-end-to-end/references/INCIDENTS.md#L5-L21` documents `loop-state-without-driver`.
D8.G3 Evidence: it says a loop is not active until driver verified and pane prompt delivery exists.
D8.G3 Risk: current loop markers repeat the same class with writeback-only proof.
D8.G3 Remediation: promote current recurrence into stricter doctor enforcement.
D8.G3 Wave-0: yes.

D8.G4. Recent skill INCIDENTS additions show substrate issues outside flywheel.
D8.G4 Evidence: demo-foundation INCIDENTS modified 2026-05-05T19:19:56Z.
D8.G4 Evidence: deadlock-finder-and-fixer INCIDENTS modified 2026-05-05T06:53:34Z.
D8.G4 Evidence: infisical-secrets INCIDENTS modified 2026-05-05T01:04:33Z.
D8.G4 Risk: today's substrate learning is dispersed and not yet rolled into dispatch preflight.
D8.G4 Remediation: daily incident digest should feed dispatch skill selection.
D8.G4 Long-tail: yes.

D8.G5. Promoted incidents are not all fixed.
D8.G5 Evidence: Beads OpenRead incident exists, but today's fuckup log still has OpenRead and malformed DB rows.
D8.G5 Evidence: loop-state-without-driver incident exists, but current markers still report verified from writeback-only proof.
D8.G5 Evidence: dispatch transport incidents exist, but line 1269 logs CASS prompt aborting `ntm send`.
D8.G5 Risk: incident promotion is not enforcing closure.
D8.G5 Remediation: add "incident has active recurrence" status and require a paired tool bead or wave-0 item.
D8.G5 Wave-0: yes.

D8.G6. INCIDENTS evidence linkage needs a validator.
D8.G6 Evidence: L56 requires INCIDENTS entries cite fuckup rows, bead IDs, or commits.
D8.G6 Evidence: existing flywheel INCIDENTS entries often cite row lines.
D8.G6 Risk: new entries can drift into doctrine without live evidence.
D8.G6 Remediation: doctor check for evidence links in changed INCIDENTS files.
D8.G6 Quick-fix: yes.

D8.G7. Current doctrine candidates exceed manual processing capacity.
D8.G7 Evidence: 14 classes recurring 3+ times today.
D8.G7 Evidence: 864 unprocessed rows in 72h.
D8.G7 Risk: manual `/flywheel:learn` alone will lag.
D8.G7 Remediation: create an auto-generated promotion queue with human-readable proposed action.
D8.G7 Long-tail: yes.

D8.G8. INCIDENTS and canonical L-rules are not enough without executable gates.
D8.G8 Evidence: L57 exists, but current loop marker state violates its spirit.
D8.G8 Evidence: L91 exists, but dispatch rows still encode prompt not visible/submitted while `work_started=true`.
D8.G8 Evidence: L51 exists, but reservation conflicts still lack queue/disposition.
D8.G8 Risk: doctrine is known but not mechanically enforced.
D8.G8 Remediation: every promoted incident should name one executable validator or a paired-tool bead.
D8.G8 Wave-0: yes.

## Cross-Dimension Pattern Table

| Pattern | Dimensions | Evidence | Impact | Close path |
|---|---:|---|---|---|
| Marker truth is not execution truth | 1,2,4,8 | active markers; writeback-only ledgers; dispatch rows with no prompt proof; L57 incident | loops look alive while work is invisible | driver proof read model plus doctor hard gate |
| Callback/disposition backlog | 2,3,6 | 86 stale dispatches; 98 callback-overdue rows; 438 `/tmp` files older than 24h | dispatch load compounds without closure | stale-dispatch classifier and spool retention |
| Beads read/write fragility | 3,5,7,8 | OpenRead rows; DB busy; integrity failures; backup artifacts | planning DAG work risks corruption | writer windows, `br` upgrade, recovery cleanup |
| Agent identity role/key drift | 4,6,7 | flywheel/ALPS duplicate orch roles; VRTX shared project key; token-path gaps | reservations/callbacks misattribute ownership | identity registry repair |
| Doctrine not executable enough | 1,2,3,8 | L57/L91/L51 known but recurrence persists | known failures repeat | validators and paired-tool beads |
| Protected client substrate leakage | 3,5,7 | ALPS secret-output rows; ALPS Beads corruption; ALPS dirty handoffs | client work can lose auditability | protected-session wave-0 cleanup |
| Temp and backup artifact accumulation | 5,6,7 | `/tmp` dispatch count; `.beads` backup files; screenshot dirs | future commits and workers see noise | retention and ignore policy |
| Baseline drift checks unavailable | 5,7,8 | `bv` no baseline; dirty tree broad | drift cannot be measured | create baseline after clean checkpoint |

Cross pattern count: 8.
Callback metric: `cross_dimension_patterns=8`.

## Wave-0 Candidate List

W0.1. Loop-driver truth repair.
W0.1 Why before wave-1: every future tick assumes active loops are actually prompting panes.
W0.1 Evidence: active flywheel/VRTX markers with not-loaded project labels.
W0.1 Evidence: loop-driver ledgers lines 421-425 are writeback-only with `prompt_file=null`.
W0.1 Acceptance: doctor reports active markers as verified only with loaded label and recent prompt delivery proof.
W0.1 Owner: flywheel loop driver.

W0.2. Dispatch/callback stale reaper.
W0.2 Why before wave-1: 86 unresolved >24h dispatches will pollute capacity and context.
W0.2 Evidence: normalized dispatch scan.
W0.2 Acceptance: stale rows receive disposition; no active-loop dispatch older than 24h remains unresolved without reason.
W0.2 Owner: dispatch-log tooling.

W0.3. Fuckup-log triage and promotion queue.
W0.3 Why before wave-1: 864 unprocessed rows means known trauma is not routed.
W0.3 Evidence: 72h scan and 14 recurring today classes.
W0.3 Acceptance: top 14 classes each have `processed_into` or explicit no-promotion reason.
W0.3 Owner: `/flywheel:learn` and doctor triage.

W0.4. Beads substrate repair window.
W0.4 Why before wave-1: current plans create or wire beads heavily.
W0.4 Evidence: `br dep cycles` DB busy; mobile-eats/ALPS/picoz integrity failures; recent OpenRead rows.
W0.4 Acceptance: flywheel `br dep cycles --json` stable; active repos either integrity OK or excluded from wave-1.
W0.4 Owner: Beads recovery tooling.

W0.5. Agent Mail identity registry correction.
W0.5 Why before wave-1: reservations and callbacks depend on stable identity primary keys.
W0.5 Evidence: flywheel and ALPS duplicate `orch` roles; VRTX project key is shared fleet-mail path.
W0.5 Acceptance: active rows match topology roles and repo project keys.
W0.5 Owner: Agent Mail resolver.

W0.6. Dirty-tree checkpoint plan.
W0.6 Why before wave-1: broad dirty trees mean new work will mix with existing substrate edits.
W0.6 Evidence: core four tracked dirty count 47.
W0.6 Acceptance: commit/ignore/archive plan exists per dirty group; high-risk files reserved before edits.
W0.6 Owner: orchestrator.

W0.7. Dispatch spool retention.
W0.7 Why before wave-1: 1,018 `/tmp` dispatch files creates stale packet risk.
W0.7 Evidence: 438 older than 24h.
W0.7 Acceptance: stale files linked to dispatch disposition or archived.
W0.7 Owner: dispatch tooling.

W0.8. Secret-output lint for dispatch packets.
W0.8 Why before wave-1: recent high-severity secret leak occurred during dispatch diagnosis.
W0.8 Evidence: fuckup-log lines 1271-1273.
W0.8 Acceptance: dispatch lint rejects credential-shaped stdout capture patterns.
W0.8 Owner: dispatch-template tooling.

Wave-0 count: 8.
Callback metric: `wave_0_candidates_count=8`.

## Quick-Fix List

QF.1. Add doctor field for active marker with project label not loaded.
QF.1 Estimate: <30m.
QF.1 Depends on: no code-space mutation until planned.

QF.2. Add doctor field for inactive marker with `last_tick > stopped_at`.
QF.2 Estimate: <30m.

QF.3. Normalize dispatch expected-by into absolute timestamp at append time.
QF.3 Estimate: <30m.

QF.4. Add stale dispatch read-only report grouped by `task_id`, event, age, and callback match.
QF.4 Estimate: <30m.

QF.5. Add `work_started` validation rule requiring prompt-visible or pane-evidence proof.
QF.5 Estimate: <30m for report-only; longer for enforcement.

QF.6. Correct Agent Mail role labels for flywheel pane 2 and ALPS pane 3 through resolver.
QF.6 Estimate: <30m if no token auth wall.

QF.7. Add health view split for agent panes vs user panes.
QF.7 Estimate: <30m.

QF.8. Add `/tmp/dispatch_*.md` age report and archive candidate list.
QF.8 Estimate: <30m.

QF.9. Add INCIDENTS evidence-link validator for changed files.
QF.9 Estimate: <30m for grep-level validator.

QF.10. Update dispatch L112 generator to avoid negative grep matching "No dependency cycles detected".
QF.10 Estimate: <30m.

QF.11. Add `.beads` backup artifact ignore/retention policy draft.
QF.11 Estimate: <30m.

QF.12. Create `bv` baseline plan after dirty-tree checkpoint.
QF.12 Estimate: <30m after checkpoint.

Quick-fix count: 12.
Callback metric: `quick_fix_count=12`.

## Long-Tail List

LT.1. Replace ad-hoc loop scripts with one canonical driver contract.
LT.1 Why long-tail: cross-repo wrappers and mission-lock exceptions need migration.

LT.2. Build dispatch log read model and disposition store.
LT.2 Why long-tail: multiple legacy event shapes need compatibility.

LT.3. Implement automatic fuckup-log promotion queue with durable processed links.
LT.3 Why long-tail: needs false-positive controls.

LT.4. Upgrade or replace installed `br 0.1.20` across repos.
LT.4 Why long-tail: protected repos and recovery scripts need sequencing.

LT.5. Migrate VRTX Agent Mail primary keys to repo-local project key.
LT.5 Why long-tail: cross-project contacts/reservations may need preserved history.

LT.6. Decide VRTX Beads/flywheel management status and initialize if needed.
LT.6 Why long-tail: client repo may need its own mission-lock first.

LT.7. Build temp dispatch spool with index, archive, and retention.
LT.7 Why long-tail: must integrate with NTM sends and callback matching.

LT.8. Build doctrine-to-executable-gate pipeline for INCIDENTS promotions.
LT.8 Why long-tail: requires validators per incident class.

LT.9. Protected-session cleanup for picoz dirty tree and corrupted DB.
LT.9 Why long-tail: safety-critical repo must not be swept into generic cleanup.

LT.10. Screenshot/evidence artifact retention across mobile-eats and other repos.
LT.10 Why long-tail: evidence links must remain valid after archival.

Long-tail count: 10.
Callback metric: `long_tail_count=10`.

## Pattern to Doctrine Candidates

Candidate DCT.1. `fleet-propagation-failed`.
DCT.1 Count today: 211.
DCT.1 Candidate rule: fleet propagation must verify target file, source freshness, and target repo cleanliness before claiming propagation.
DCT.1 Route: `/flywheel:learn --promote fleet-propagation-failed`.

Candidate DCT.2. `dispatch_callback_overdue`.
DCT.2 Count today: 96.
DCT.2 Candidate rule: dispatch expected-by must become an absolute deadline and an overdue row must be auto-dispositioned.
DCT.2 Route: dispatch-log doctor rule.

Candidate DCT.3. `owner-custody-missing`.
DCT.3 Count today: 71.
DCT.3 Candidate rule: owner-custody blockers require one canonical recovery dispatch, not repeated idle redispatch.
DCT.3 Route: protected-session recovery plus domain skill.

Candidate DCT.4. `tick-driver-primitive-failed`.
DCT.4 Count today: 70.
DCT.4 Candidate rule: a primitive tick failure must pause loop truth updates until prompt delivery proof is restored.
DCT.4 Route: loop driver doctor.

Candidate DCT.5. `storage-headroom-prune-exhausted`.
DCT.5 Count today: 29.
DCT.5 Candidate rule: low-headroom recovery must produce reclaim receipts before host mutation resumes.
DCT.5 Route: storage-health INCIDENTS.

Candidate DCT.6. `skillos-loop-integrity-still-limping`.
DCT.6 Count today: 12.
DCT.6 Candidate rule: skillos loop health must distinguish mission lock paused from integrity failed.
DCT.6 Route: skillos mission and loop doctor.

Candidate DCT.7. `br-sync-stale-db-export-blocked`.
DCT.7 Count today: 9.
DCT.7 Candidate rule: stale DB/JSONL export refusal triggers recovery queue, not force export.
DCT.7 Route: beads-br incident.

Candidate DCT.8. `parent-bead-dispatched-with-open-children`.
DCT.8 Count today: 5.
DCT.8 Candidate rule: idle dispatcher must not dispatch a parent bead whose acceptance gate is owned by open children.
DCT.8 Route: idle dispatch gate.

Candidate DCT.9. `agent-mail-reservation-token-path-gap`.
DCT.9 Count today: 4.
DCT.9 Candidate rule: reservation commands must resolve token by identity primary key, not mailbox name.
DCT.9 Route: Agent Mail resolver.

Candidate DCT.10. `agentmail-beads-db-reservation-conflict`.
DCT.10 Count today: 4.
DCT.10 Candidate rule: Beads mutation requests must join a reservation queue when `.beads/*` is held.
DCT.10 Route: file reservation workflow.

Candidate DCT.11. `jeff-dedupe-bead-stale-scope`.
DCT.11 Count today: 4.
DCT.11 Candidate rule: stale canonical path in a bead must trigger scope-refresh before host mutation.
DCT.11 Route: Jeff swarm ops.

Candidate DCT.12. `pane-respawn`.
DCT.12 Count today: 4.
DCT.12 Candidate rule: pane respawn requires topology and Agent Mail identity repair in the same receipt.
DCT.12 Route: protected-session-recovery.

Candidate DCT.13. `parent-redispatched-before-open-child-complete`.
DCT.13 Count today: 3.
DCT.13 Candidate rule: redispatch must check child closure and supersession before reusing a parent task.
DCT.13 Route: idle dispatcher.

Candidate DCT.14. `worker-evidence-file-write-before-reservation`.
DCT.14 Count today: 3.
DCT.14 Candidate rule: evidence file writes require reservation or explicit read-only scratch exemption before write.
DCT.14 Route: dispatch template L51 enforcement.

Doctrine candidate count: 14.
Callback metric: `doctrine_candidates_count=14`.

## Gap Register

GAP-001. Active marker without project label loaded.
GAP-001 Severity: high.
GAP-001 Dimensions: 1,8.
GAP-001 Close order: wave-0.

GAP-002. Writeback-only loop proof treated as verified.
GAP-002 Severity: high.
GAP-002 Dimensions: 1,2,8.
GAP-002 Close order: wave-0.

GAP-003. Inactive loops receive fresh last_tick updates.
GAP-003 Severity: high.
GAP-003 Dimensions: 1.
GAP-003 Close order: wave-0.

GAP-004. Dispatch backlog older than 24h.
GAP-004 Severity: high.
GAP-004 Dimensions: 2,6.
GAP-004 Close order: wave-0.

GAP-005. Recent dispatch expected-by not enforced.
GAP-005 Severity: medium.
GAP-005 Dimensions: 2.
GAP-005 Close order: quick-fix.

GAP-006. Idle auto-dispatch parent/child churn.
GAP-006 Severity: high.
GAP-006 Dimensions: 2,3.
GAP-006 Close order: wave-0.

GAP-007. Dispatch delivery state contradiction.
GAP-007 Severity: high.
GAP-007 Dimensions: 2,8.
GAP-007 Close order: wave-0.

GAP-008. Fuckup-log unprocessed backlog.
GAP-008 Severity: high.
GAP-008 Dimensions: 3,8.
GAP-008 Close order: wave-0.

GAP-009. Dominant trauma classes lack current executable closure.
GAP-009 Severity: high.
GAP-009 Dimensions: 3,8.
GAP-009 Close order: wave-0.

GAP-010. Beads OpenRead/malformed failures recurring.
GAP-010 Severity: high.
GAP-010 Dimensions: 3,5,8.
GAP-010 Close order: wave-0.

GAP-011. Secret-output recurrence in dispatch probes.
GAP-011 Severity: high.
GAP-011 Dimensions: 3,7.
GAP-011 Close order: wave-0.

GAP-012. Reservation conflicts lack queue/disposition UX.
GAP-012 Severity: medium.
GAP-012 Dimensions: 3,4,5.
GAP-012 Close order: quick-fix plus long-tail.

GAP-013. L112 regex/prose parser fragility.
GAP-013 Severity: medium.
GAP-013 Dimensions: 3,5,8.
GAP-013 Close order: quick-fix.

GAP-014. Topology ledger not paired with generated live snapshot.
GAP-014 Severity: medium.
GAP-014 Dimensions: 4.
GAP-014 Close order: quick-fix.

GAP-015. Flywheel pane 3 dead while expected by topology.
GAP-015 Severity: high.
GAP-015 Dimensions: 4,7.
GAP-015 Close order: wave-0 if pane 3 needed.

GAP-016. Flywheel Agent Mail pane 2 role drift.
GAP-016 Severity: medium.
GAP-016 Dimensions: 4.
GAP-016 Close order: quick-fix.

GAP-017. ALPS Agent Mail pane 3 role drift.
GAP-017 Severity: high.
GAP-017 Dimensions: 4,7.
GAP-017 Close order: wave-0.

GAP-018. VRTX Agent Mail project key drift.
GAP-018 Severity: high.
GAP-018 Dimensions: 4,7.
GAP-018 Close order: wave-0 before VRTX work.

GAP-019. Legacy Agent Mail token surfaces remain.
GAP-019 Severity: medium.
GAP-019 Dimensions: 4.
GAP-019 Close order: quick-fix warning.

GAP-020. NTM user pane health pollutes agent health.
GAP-020 Severity: medium.
GAP-020 Dimensions: 4.
GAP-020 Close order: quick-fix.

GAP-021. Flywheel Beads external changes pending import.
GAP-021 Severity: medium.
GAP-021 Dimensions: 5.
GAP-021 Close order: quick-fix after lock-free window.

GAP-022. Flywheel `br dep cycles` DB busy.
GAP-022 Severity: high.
GAP-022 Dimensions: 5.
GAP-022 Close order: wave-0.

GAP-023. `bv` baseline missing.
GAP-023 Severity: medium.
GAP-023 Dimensions: 5,7.
GAP-023 Close order: quick-fix after checkpoint.

GAP-024. mobile-eats Beads integrity failure.
GAP-024 Severity: high.
GAP-024 Dimensions: 5.
GAP-024 Close order: wave-0 if mobile-eats loop resumes.

GAP-025. ALPS Beads integrity failure.
GAP-025 Severity: high.
GAP-025 Dimensions: 5,7.
GAP-025 Close order: wave-0 for ALPS.

GAP-026. Picoz Beads integrity failure.
GAP-026 Severity: medium-high.
GAP-026 Dimensions: 5,7.
GAP-026 Close order: protected long-tail.

GAP-027. VRTX missing Beads substrate.
GAP-027 Severity: medium.
GAP-027 Dimensions: 5,7.
GAP-027 Close order: long-tail.

GAP-028. Beads recovery artifacts untracked.
GAP-028 Severity: medium.
GAP-028 Dimensions: 5,7.
GAP-028 Close order: quick-fix.

GAP-029. `/tmp` dispatch file churn.
GAP-029 Severity: medium.
GAP-029 Dimensions: 6.
GAP-029 Close order: quick-fix.

GAP-030. Dispatch spool naming inconsistency.
GAP-030 Severity: medium.
GAP-030 Dimensions: 6.
GAP-030 Close order: long-tail.

GAP-031. CASS similar-work prompt aborts orchestrator dispatch.
GAP-031 Severity: high.
GAP-031 Dimensions: 6,2.
GAP-031 Close order: wave-0 for dispatch command template.

GAP-032. Core dirty-tree critical state.
GAP-032 Severity: high.
GAP-032 Dimensions: 7.
GAP-032 Close order: wave-0.

GAP-033. Doctrine surfaces dirty across repos.
GAP-033 Severity: medium.
GAP-033 Dimensions: 7,8.
GAP-033 Close order: quick-fix read-only; commit later.

GAP-034. INCIDENTS fragmentation.
GAP-034 Severity: medium.
GAP-034 Dimensions: 8.
GAP-034 Close order: long-tail.

GAP-035. Promoted incidents recurring unfixed.
GAP-035 Severity: high.
GAP-035 Dimensions: 3,8.
GAP-035 Close order: wave-0.

GAP-036. INCIDENTS evidence-link validation missing.
GAP-036 Severity: medium.
GAP-036 Dimensions: 8.
GAP-036 Close order: quick-fix.

Total gaps found: 36.
Callback metric: `total_gaps_found=36`.

## Evidence Appendix: Loop Drivers

E.LD.1. Loop markers checked: alpsinsurance, flywheel, mobile-eats, skillos, VRTX.
E.LD.2. Active markers: flywheel, VRTX.
E.LD.3. Inactive markers: ALPS, mobile-eats, skillos.
E.LD.4. Active stale markers by project label: flywheel and VRTX.
E.LD.5. Inactive stale markers by post-stop writeback: ALPS, mobile-eats, skillos.
E.LD.6. `com.flywheel.tick` loaded.
E.LD.7. `ai.zeststream.flywheel-flywheel-loop` not loaded.
E.LD.8. `ai.zeststream.vrtx-flywheel-loop` not loaded.
E.LD.9. `ai.zeststream.alps-flywheel-loop` not loaded.
E.LD.10. `ai.zeststream.mobile-eats-flywheel-loop` not loaded.
E.LD.11. `ai.zeststream.skillos-flywheel-loop` not loaded.
E.LD.12. Loop ledgers lines 421-425 all report writeback mode.
E.LD.13. Loop ledgers lines 421-425 all report `prompt_file=null`.
E.LD.14. Loop ledgers lines 421-425 all report empty send output.
E.LD.15. L57 source: AGENTS loop-state-marker-not-driver.
E.LD.16. Incident source: flywheel-end-to-end loop-state-without-driver.

## Evidence Appendix: Dispatch Log

E.DL.1. Dispatch log line count at scan: 1,649.
E.DL.2. Normalized dispatch records: 301.
E.DL.3. Stale unresolved older than 24h: 86.
E.DL.4. Unresolved under 24h: 119.
E.DL.5. Dispatch-like event vocabulary count: 7 event names.
E.DL.6. Callback-like matching used task_id set from callback/completion events.
E.DL.7. Recent unresolved dispatches at lines 1647-1649 are about 2h old.
E.DL.8. Older loop ntm dispatches remain unresolved from lines 708-724 and 1119.
E.DL.9. Idle auto-dispatch count: 105.
E.DL.10. `ntm_dispatch_sent` count: 107.
E.DL.11. `dispatch_sent` count: 49.
E.DL.12. `dispatched` count: 30.
E.DL.13. `manual_dispatch` count: 3.
E.DL.14. Dispatch freshness is not measurable correctly by line grep alone.
E.DL.15. Expected-by fields need absolute conversion.

## Evidence Appendix: Fuckup Log

E.FL.1. Fuckup log total lines at scan: 1,283.
E.FL.2. 72h total rows: 1,075.
E.FL.3. 72h unprocessed rows: 864.
E.FL.4. Today total rows: 659.
E.FL.5. Today classes with recurrence >=3: 14.
E.FL.6. Recent secret-output cluster: lines 1271-1273.
E.FL.7. Recent file reservation conflict: line 1274.
E.FL.8. Recent Beads recovery and failure rows: lines 1275, 1277, 1280, 1281, 1283.
E.FL.9. Recent L112 regex rows: lines 1276, 1278, 1282.
E.FL.10. Recent CASS abort row: line 1269.

## Evidence Appendix: Topology and Agent Mail

E.TA.1. Session topology log line count: 22.
E.TA.2. Latest flywheel topology row: line 7.
E.TA.3. Latest ALPS topology row: line 18.
E.TA.4. Latest VRTX topology row: line 19.
E.TA.5. Latest skillos topology row: line 20.
E.TA.6. Latest picoz topology row: line 21.
E.TA.7. Latest clutterfreespaces topology row: line 22.
E.TA.8. Live NTM sessions: alpsinsurance, clutterfreespaces, flywheel, mobile-eats, skillos, VRTX.
E.TA.9. Flywheel Agent Mail active roles: two orch, two worker.
E.TA.10. ALPS Agent Mail active roles: two orch, two worker.
E.TA.11. VRTX Agent Mail active project key: shared fleet-mail path.
E.TA.12. Canonical token files had 0600 permissions.
E.TA.13. Legacy token JSON files still exist.
E.TA.14. No raw token values were printed or used.

## Evidence Appendix: br/bv

E.BR.1. `br doctor --json` returned OK for flywheel.
E.BR.2. Flywheel JSONL records: 1,096.
E.BR.3. Flywheel DB records: 1,096.
E.BR.4. Flywheel sqlite integrity: OK.
E.BR.5. Flywheel sync metadata: external changes pending import.
E.BR.6. `br dep cycles --json` returned database busy snapshot conflict.
E.BR.7. `bv --check-drift` returned no baseline found.
E.BR.8. skillos integrity OK, 138 issues.
E.BR.9. mobile-eats integrity failed on page 939.
E.BR.10. ALPS integrity failed with freelist and unused pages 919-1017.
E.BR.11. picoz integrity failed with many unused pages.
E.BR.12. VRTX `.beads` missing.

## Evidence Appendix: /tmp and Dirty Tree

E.TMP.1. `/tmp/dispatch_*.md` count: 1,018.
E.TMP.2. Older than 24h: 438.
E.TMP.3. Older than 7d: 0.
E.TMP.4. Newest sample included this infra scan dispatch.
E.TMP.5. Oldest sample around 49.1h.
E.GIT.1. Flywheel tracked dirty count: 32.
E.GIT.2. skillos tracked dirty count: 7.
E.GIT.3. mobile-eats tracked dirty count: 4.
E.GIT.4. ALPS tracked dirty count: 4.
E.GIT.5. VRTX tracked dirty count: 23.
E.GIT.6. picoz tracked dirty count: 35.
E.GIT.7. Core four dirty tracked count: 47.
E.GIT.8. All scanned repos dirty tracked count: 105.

## Close-Order Detail

CO.1. Freeze wave-1 dispatch except wave-0 repair lanes.
CO.2. Mark active loop markers as stale until prompt delivery proof exists.
CO.3. Stop inactive loop writeback updates from touching `last_tick`.
CO.4. Reconcile loaded launchd labels with loop marker labels.
CO.5. Recompute dispatch backlog with absolute expected-by.
CO.6. Disposition stale loop tick dispatches as superseded where safe.
CO.7. Disposition idle auto-dispatch parent-child repeats.
CO.8. Promote or route top 14 trauma classes.
CO.9. Schedule Beads writer-free recovery.
CO.10. Correct Agent Mail role/key drift.
CO.11. Classify core dirty tree into commit/archive/ignore.
CO.12. Add temp dispatch retention index.
CO.13. Run INCIDENTS recurrence validator.
CO.14. Only then resume wave-1 substrate expansion.

## Non-Goals

NG.1. This scan does not close beads.
NG.2. This scan does not mutate Beads DBs.
NG.3. This scan does not rotate or read secrets.
NG.4. This scan does not load launchd plists.
NG.5. This scan does not change Agent Mail tokens.
NG.6. This scan does not delete `/tmp` dispatch files.
NG.7. This scan does not clean dirty trees.
NG.8. This scan does not decide protected repo changes.

## Callback Metrics

dimensions_scanned=8
total_gaps_found=36
wave_0_candidates_count=8
quick_fix_count=12
long_tail_count=10
doctrine_candidates_count=14
cross_dimension_patterns=8
stale_loop_markers=5
stale_dispatches_over_24h=86
unprocessed_fuckup_rows_72h=864
dirty_tree_critical_uncommitted=47
bead_db_writes=0

## L112 Readiness

The file includes `loop driver`, `dispatch.log`, `fuckup`, `topology`, `br doctor`, and `stale`.
The file includes `Wave-0`, `Cross-dimension`, and `Quick-fix`.
Expected probe result: `OK_infra_gap_scan`.
