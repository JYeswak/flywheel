---
title: "Fleet Autonomy v1 Review - GPT-5.5 /planning-workflow exact-prompt"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet Autonomy v1 Review - GPT-5.5 /planning-workflow exact-prompt

Review date: 2026-05-05  
Reviewer mode: GPT-5.5 as GPT Pro exact-prompt parity  
Plan input: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN-INPUT.md`  
No source edits performed. This file is the plan-space review artifact.

## Executive verdict

**Revise** - the plan has the right diagnosis and the right first substrate primitive, but it currently overstates P1 as a one-line fix, depends on a nonexistent `bv --exclude` flag in P2, underweights the existing no-silent-darkness and peer-orch permit-gate surfaces, and treats the morning artifact as the measurement unit instead of a consumer of continuous status.

Four-lens score after the revisions proposed here:

| Lens | Score | Reason |
|---|---:|---|
| Brand | 9.4 | Strongly aligned with "founder grows outside the founder"; revise to make autonomy falsifiable rather than narrative. |
| Sniff | 9.1 | The failure evidence is real; main smell is one-line-fix rhetoric around a multi-surface selector contract. |
| Jeff | 9.2 | Correctly reuses `bv --robot-next`; needs issue-file routing for missing upstream flags and less local fork energy. |
| Public | 9.0 | Compelling operational story if the status/alert substrate proves outcomes without private heroics. |

Composite score: **9.18 / 10**.

Bottom-line recommendation: ship **P1+P2 as a single revised selector contract first**, with a minimal status row emitted in the same patch. Then ship full P3. Do not ship P1 alone.

## Evidence used

- `bv --robot-next` works locally and returned `flywheel-4m2a`, P0, PageRank 100%, unblocks 1, unclaimed.
- `bv --robot-next --exclude=flywheel-668a` fails: the flag does not exist.
- `.flywheel/scripts/idle-state-probe.sh` currently shells to `br ready --json`, normalizes that list, filters P0/P1, skips recent fired beads from a state file, then sorts by priority and `created_at`.
- `.flywheel/scripts/idle-pane-auto-dispatch.sh` consumes `idle_state_class[].dispatch_candidate` from the probe, writes dispatch prompts, updates the bead to `in_progress`, appends cooldown files, and appends `.flywheel/dispatch-log.jsonl`.
- `AGENTS.md` L68 already defines the higher goal as `NO_SILENT_DARKNESS`, with `silent_dark_minutes`, detection latency, false recovery, unknown auto-recovery, and L60 signal presence.
- `AGENTS.md` L70 already requires same-tick chain-forward when a next action is identified.
- `AGENTS.md` L107 already requires shared-surface reservations for shared write surfaces.
- `.flywheel/scripts/peer-orch-freeze-monitor.sh` already exists and gates peer-orch recovery through `.flywheel/scripts/peer-orch-respawn-permit.sh`.
- Socraticode status was green with 694 indexed chunks.

## Per-primitive review

### P1: Watcher uses `bv --robot-next`

Recommendation: **revise, then keep**.

Does it target the cited leverage point?

Partly. It is framed as Meadows #3, system goal, but the primitive itself is mainly Meadows #6 information flow plus #5 rules: the watcher receives better graph-ranked information and changes the dispatch selection rule. It supports the #3 goal only if the status substrate measures closure velocity and blocks busy-work regressions.

Smallest counter-example that breaks it:

`bv --robot-next` returns a bead that is already in flight, stale `in_progress`, held by another pane, blocked by a file reservation, or repeatedly dispatched without callback. The watcher dispatches it again because the selector trusts a single top pick without consulting recent dispatch state.

Risk register:

1. `bv --robot-next` returns only one pick. If that one is locally suppressed, the plan currently has no valid next-best mechanism.
2. Calling `bv --robot-next` three times, as shown in the plan, can race against cache freshness or bead state changes and emit inconsistent `id`, `score`, and `unblocks`.
3. A blind replacement can lose existing guard behavior in `idle-state-probe.sh`: epic filtering, P0/P1 filtering, fired-bead cooldowns, and doctor-visible `br_ready_count` fields that tests already assert.

Analysis and rationale:

P1 is the right first target, but not a literal one-line change in this repo. The actual selection happens in the canonical probe, and the auto-dispatcher consumes the probe. If P1 lands as an isolated shell substitution, the system gains graph rank but loses existing observability and cooldown logic. The safer architecture is a **selector contract**:

- Probe calls `bv --robot-next` once and records the full object.
- Probe retains `br ready` only as count/context/fallback evidence, not as primary selection.
- Dispatcher logs selector source, score, reasons, data hash, suppression reason, and recent-dispatch count.
- If the top `bv` pick is suppressed, the implementation uses `bv --robot-triage` or `quick_ref.top_picks` to find the next locally valid pick, not `--exclude`.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
-### P1: Watcher uses `bv --robot-next` (one-line core change + tests)
+### P1: Watcher uses a `bv` selector contract (core selection change + tests)
@@
-**Status:** Highest-leverage, lowest-blast-radius. Ships first.
+**Status:** Highest-leverage selector fix, but not a standalone one-line patch.
+Ships first only when bundled with P2's recent-dispatch suppression and with
+doctor-visible selector evidence.
@@
-**Change:** In `~/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh` (or wherever the next-bead selection happens — needs grep), replace:
+**Change:** In `.flywheel/scripts/idle-state-probe.sh`, preserve the existing
+probe contract but make `bv` the primary selector. Call `bv --robot-next` once,
+store the full JSON object, and expose:
+- `selector_source`
+- `selector_data_hash`
+- `selector_score`
+- `selector_reasons`
+- `selector_unblocks`
+- `dispatch_candidate`
+- `dispatch_candidate_suppressed_reason`
@@
-NEXT=$(br ready --json | jq -r '.[0].id // empty')
+BV_NEXT_JSON="$(bv --robot-next 2>/dev/null || true)"
+NEXT="$(jq -r '.id // empty' <<<"$BV_NEXT_JSON" 2>/dev/null || true)"
@@
-NEXT=$(bv --robot-next 2>/dev/null | jq -r '.id // empty')
-SCORE=$(bv --robot-next 2>/dev/null | jq -r '.score // 0')
-UNBLOCKS=$(bv --robot-next 2>/dev/null | jq -r '.unblocks // 0')
-# Log the rationale into the dispatch-log
+SCORE="$(jq -r '.score // 0' <<<"$BV_NEXT_JSON")"
+UNBLOCKS="$(jq -r '.unblocks // 0' <<<"$BV_NEXT_JSON")"
+REASONS="$(jq -c '.reasons // []' <<<"$BV_NEXT_JSON")"
+DATA_HASH="$(jq -r '.data_hash // empty' <<<"$BV_NEXT_JSON")"
+# Log the rationale into the probe output and dispatch-log.
@@
-**Test fixture:** Replay last night's 107-dispatch sequence. Assert that the bv-picked bead would have been different from the watcher's pick on at least 60 of 107 events. Acceptance gate: counterfactual closure rate > 15% on the replay.
+**Test fixture:** Replay last night's 107-dispatch sequence. Assert:
+- same-bead redispatches drop below 2 per 8h window
+- dispatches to `BLOCKED` or `closed` beads are zero
+- `watcher_unique_bead_ratio >= 0.75`
+- `selector_source == "bv_robot_next"` on healthy `bv`
+- replay records `selector_data_hash` for every dispatch candidate
+
+Do not claim counterfactual closures as proven by replay. Report them as an
+estimate; prove selector quality with dispatch legality and uniqueness.
```

Verdict on whether the `bv` replacement is the highest-leverage fix:

Yes, conditionally. It is the highest-leverage selector fix because the overnight evidence shows repeated dispatches to beads `zaat` and `668a` while `bv` surfaces `flywheel-4m2a`. The smallest safe version is not "replace one command"; it is "use `bv` as primary selector and keep the local suppression/observability contract." There is no smaller robust fix than that because pure `br ready` is the wrong information source.

### P2: Watcher self-asserts on divergent loops

Recommendation: **merge into P1 and revise**.

Does it target the cited leverage point?

Yes, but the plan labels it as #4 self-organization while the concrete primitive is mainly #5 rules and #8 negative feedback loop strength. It changes the watcher rule and adds a balancing loop that dampens same-bead recurrence. It becomes self-organization only if the watcher can evolve its suppression list or route upstream issues when `bv` lacks a needed selector feature.

Smallest counter-example that breaks it:

The plan says "call `bv` again with `--exclude=<id>` if it exists." It does not exist locally. The third repeated dispatch is therefore either sent again or the watcher idles even when `bv --robot-triage` has other valid top picks.

Risk register:

1. Nonexistent `bv --exclude` makes the proposed fallback unusable.
2. Cooldown keyed only by bead ID can suppress legitimate retries after a worker crashes before starting.
3. Cooldown without callback validation can hide a real blocker instead of creating a fix bead or upstream issue.

Analysis and rationale:

P2 should not be an additive follow-up. It is part of the P1 selector contract. The selector must know "recently attempted, no closure/callback evidence" before it emits a candidate. The implementation should use existing surfaces:

- `.flywheel/dispatch-log.jsonl` for dispatch and callback state.
- `STATE_DIR/bead-fired` only as a fast local cache, not the authority.
- `bv --robot-triage` or `quick_ref.top_picks` as next-best fallback when `--robot-next` is suppressed.
- A Jeff upstream issue draft if `bv` needs native `--exclude`, `--attempted-since`, or `--cooldown-window`.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
-### P2: Watcher self-asserts on divergent loops (Jeff's CRDT invariant)
+### P2: Recent-dispatch suppression inside the P1 selector contract
@@
-**Status:** Ships immediately after P1. Same script, additive.
+**Status:** Ships in the same bead as P1. P1 without this is an unsafe partial.
@@
-If count >= 2 and no `closure_event` in the same window, log the skip with reason `same-bead-cooldown` and call `bv` again with the previous pick excluded (via `bv --robot-next --exclude=<id>` if it exists, else fallback to "no dispatch this tick, log idle").
+If count >= 2 and no callback, closure, or validated progress event exists in
+the same window, suppress the pick with reason `same-bead-cooldown`.
+
+Because local `bv --robot-next --exclude=<id>` is not supported, use this
+fallback order:
+1. `bv --robot-triage` and select the first `quick_ref.top_picks[]` or
+   actionable recommendation not in the local suppression set.
+2. If no alternate exists, emit `status=no_candidate`,
+   `suppressed_candidate=<id>`, and `chain_blocked_reason=same_bead_cooldown`.
+3. File a Jeff-stack upstream issue draft requesting native selector exclusion;
+   do not patch Jeff's binary locally.
@@
-**Worker:** Same pane as P1 (combine into single dispatch).
+**Worker:** Same pane as P1. This is not optional follow-up work.
```

### P3: `flywheel-loop status` primitive with computed verdict

Recommendation: **keep, revise scope, ship second**.

Does it target the cited leverage point?

Yes. This is the strongest Meadows #3 primitive in the plan because it changes the visible goal from "dispatches fired" to "closure conversion and no silent darkness." It also targets #6 information flow by giving the orchestrator and Joshua the same computed verdict.

Smallest counter-example that breaks it:

The status command reports `BROKEN` in the morning, but the overnight watcher keeps dispatching for eight hours because no live monitor consumes the status thresholds during the run.

Risk register:

1. The command becomes a report generator rather than a control-plane gate.
2. It creates a new CLI surface without canonical CLI scoping: no schema, no doctor/health/repair integration, no `--watch`, no exit code contract.
3. It omits existing L68 `NO_SILENT_DARKNESS` metrics and creates a parallel health model.

Analysis and rationale:

P3 is foundational, but full P3 does not have to block the first selector fix. What must ship with P1 is a small status row: selector source, dispatch legality, same-bead suppression count, and candidate reason. The full P3 should then become the canonical fleet verdict surface and consume existing L68/L70/L71 signals rather than invent a separate dashboard.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
 ### P3: `flywheel-loop status` primitive with computed verdict
@@
-**Status:** Foundation for the morning ritual. Independent of P1/P2 (different file).
+**Status:** Foundation for continuous control and the morning ritual. Full P3
+ships after P1/P2, but P1/P2 must emit a minimal selector-status row immediately.
@@
 **Output schema:**
 ```json
 {
@@
   "joshua_interventions_count": 3,
+  "silent_dark_minutes": 0,
+  "blackout_detection_latency_p95_seconds": 0,
+  "false_recovery_count": 0,
+  "unknown_auto_recovery_count": 0,
+  "l60_signals_present_count": 5,
+  "l70_chain_required_unexecuted_count": 0,
+  "selector_source": "bv_robot_next",
+  "same_bead_suppression_count": 0,
+  "dispatches_to_blocked_or_closed_beads": 0,
   "verdict": "DEGRADED",
@@
 }
 ```
@@
-**Storage:** appends to `~/.local/state/flywheel/status-history.jsonl` every 5min via launchd plist. Morning ritual = `tail -1` + jq pretty-print.
+**Storage:** appends to `~/.local/state/flywheel/status-history.jsonl` every
+5min from the live driver. `--human` and the morning ritual render the latest
+row; they are not the measurement unit.
+
+Canonical CLI scoping gates:
+- `flywheel-loop status --json --since=8h`
+- `flywheel-loop status --human --since=overnight`
+- `flywheel-loop status --watch -i 300 --json`
+- `flywheel-loop schema status`
+- doctor exposes status row freshness and verdict
+- exit 0=HEALTHY, 1=DEGRADED, 3=BROKEN, 2=usage
```

### P4: Cross-orch reservation TTL enforcement

Recommendation: **revise heavily**.

Does it target the cited leverage point?

Partly. It is framed as a delay/parameter fix, Meadows #9/#12, but the meaningful intervention is a rule and permission boundary: who may release another agent's reservation, under what evidence, and with what audit trail. That is Meadows #5 rules.

Smallest counter-example that breaks it:

An active worker legitimately holds `.beads/beads.db` for more than 300 seconds during a long `br` operation or recovery. The watcher force-releases it by age alone, another pane writes, and the bead DB is corrupted or the audit trail lies.

Risk register:

1. Age-only force-release can create the race it is trying to prevent.
2. Agent Mail reservations and L107 shared-surface reservations are separate layers; checking only one misses pane-level staging collisions.
3. Releasing `.beads/beads.db` without also considering `.beads/beads.db-wal`, `.beads/beads.db-shm`, and `.beads/issues.jsonl` leaves partial shared-state risk.

Analysis and rationale:

P4 is necessary, but not as a watcher-side blanket force-release. The plan should use three gates:

- If reservation `expires_ts < now`, release through Agent Mail.
- If holder is inactive by Agent Mail/server heuristics, use `force_release_file_reservation` and notify the previous holder.
- If holder is alive but stale from the watcher's perspective, block dispatch and send a coordination packet; do not mutate shared bead state.

It should also check L107's shared-surface reservation ledger for `.beads/*` writes.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
-### P4: Cross-orch reservation TTL enforcement
+### P4: Cross-orch reservation lease enforcement
@@
-If a reservation older than 300s exists, log `cross-orch-stale-reservation` event AND fire a `force-release` against agent-mail (auto, no Joshua). Skip dispatch this tick.
+If a reservation blocks `.beads/beads.db`, `.beads/beads.db-wal`,
+`.beads/beads.db-shm`, or `.beads/issues.jsonl`, classify it:
+
+1. `expired`: `expires_ts < now`; release through Agent Mail and log the
+   release receipt.
+2. `abandoned`: holder inactive per Agent Mail inactivity heuristics; use
+   `force_release_file_reservation`, notify previous holder, and log evidence.
+3. `live_stale`: holder still active; do not force-release. Skip dispatch this
+   tick and send a coordination packet to the holder plus `flywheel:1`.
+
+Also run `.flywheel/scripts/shared-surface-reservation-check.sh --check` for
+shared surfaces so L107 pane-level collisions are visible.
@@
-**Worker:** 1 pane. ~30min including agent-mail probing.
+**Acceptance gate:** fixture proves expired and abandoned reservations release,
+live reservations do not release, all decisions append audit rows, and dispatch
+is skipped while a live stale holder exists.
```

### P5: Pane freeze auto-respawn permit-gate

Recommendation: **revise to consume existing surfaces**.

Does it target the cited leverage point?

Yes as a negative feedback loop and delay reduction. It is not mainly self-organization; it is a recovery control loop. The plan should explicitly bind to L68 no-silent-darkness, L95 stall receipts, L115 peer-orch permit gate, and L117 peer-orch monitor.

Smallest counter-example that breaks it:

A pane is doing a long compile or a long model call with no visible stdout for five minutes. Hash samples converge, the detector respawns it, and valid work is killed.

Risk register:

1. False-positive respawn destroys valid long-running work.
2. New generic recovery duplicates existing `frozen-pane-detector.sh` and `peer-orch-freeze-monitor.sh`, creating two authorities.
3. The protected-list model is too coarse: peer orchestrators are recoverable by `flywheel:1`, while self-recovery of `flywheel:1` is forbidden.

Analysis and rationale:

The plan is directionally right but dated against the repo. There is already a frozen-pane detector with L60 fields, and there is already a peer-orch monitor with an explicit permit gate. P5 should become a wiring/threshold bead, not a greenfield detector.

Also, the plan's "5min" threshold conflicts with the repo's documented 180s recovery SLO and detector defaults around 90s/30s. If the target is overnight autonomy, five minutes is too slow for repeated panes.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
-### P5: Pane freeze auto-respawn permit-gate
+### P5: Wire existing freeze/stall recovery into the fleet control loop
@@
-**Status:** Generalizes the multi-frame hash-diff freeze detection that already exists in `frozen-pane-detector v2` to fire respawn under permit.
+**Status:** Reuse existing `frozen-pane-detector.sh`,
+`peer-orch-freeze-monitor.sh`, L95 stall receipts, and the L115 permit gate.
+Do not create a second recovery authority.
@@
-**Change:** Extend frozen-pane-detector to invoke `flywheel-respawn` skill when:
-- multi-frame hash-converged for 5min
-- pane NOT in topology's protected list
-- no Joshua-permit override active
+**Change:** Make the control loop consume existing detector/monitor outputs:
+- worker panes: L95 stall ladder, then `frozen-pane-detector.sh --auto-recover`
+  only when live truth is healthy and recovery budget permits
+- peer orchestrators: `peer-orch-freeze-monitor.sh cycle --apply`, with
+  `PEER_ORCH_AUTO_RESPAWN=1` only when L115 returns `decision=permit`
+- self `flywheel:1`: never self-respawn; route to peer recovery
+- active client/high-risk sessions: refuse unless encoded in permit gate
@@
-- multi-frame hash-converged for 5min
+- detection and recovery MTTR target <=180s; 5min is a hard failure, not the
+  action threshold
```

### P6: Repair-bead-aging escalation pipeline

Recommendation: **keep, revise to avoid local Jeff-stack drift**.

Does it target the cited leverage point?

Partly. It targets #9 delays and #6 information flow. If it changes `bv` ranking rules for repair beads, that becomes #5 rules and possibly #4 self-organization if routed upstream cleanly.

Smallest counter-example that breaks it:

A repair bead is labeled inconsistently or lacks the exact `repair-bead` label. It ages past threshold but never enters the repair pipeline.

Risk register:

1. Local watcher priority overlays can fight `bv` PageRank and create another hidden selector.
2. Label-only detection misses repair work described in title/body but not labeled.
3. Pushover at 6h is too late for an 8h autonomy goal; the system should act before the founder wakes up.

Analysis and rationale:

Repair-bead aging is a real missing primitive, but it should not become a private watcher priority system. First consume `bv --robot-alerts`, `bv --robot-label-health`, and `br list --json` label/title/body filters. If `bv` does not natively rank repair beads as substrate blockers, file an upstream issue draft with evidence; do not patch the binary locally.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
 ### P6: Repair-bead-aging escalation pipeline
@@
-**Change:** Watcher tier on detected repair-bead-aging:
-- 0-2h: normal priority
-- 2-6h: P0-promoted, escalated to current ready queue
-- 6h+: Pushover + auto-escalate to flywheel:1 inbox via agent-mail
+**Change:** Status and selector consume repair-bead aging as substrate health:
+- 0-30m: normal priority, visible in status
+- 30m-2h: warn if no first dispatch attempt exists
+- 2h+: BROKEN status reason; selector must prefer repair unblockers when
+  `bv` also ranks them actionable
+- 4h+: Pushover threshold-breach notification plus Agent Mail escalation
+- 6h+: incident row and upstream issue if `bv` failed to rank a labeled repair
+  blocker
+
+Detection uses labels plus title/body fallback terms:
+`repair-bead`, `repair`, `substrate`, `recover`, `corruption`, `br-sync`.
@@
-**Jeff view:** Beads with label `repair-bead` should rank specially in `bv` priority — they unblock substrate. File upstream issue if `bv` doesn't already do this.
+**Jeff view:** File an upstream issue-file with a reproducible `bv` ranking case
+if repair blockers are not surfaced. Do not local-fork Jeff-stack.
```

### M: Morning ritual artifact

Recommendation: **keep as a consumer, reject as the measurement unit**.

Does it target the cited leverage point?

As written, it is #6 information flow to Joshua after the fact. It does not itself change the system goal unless the control loop consumes the same status during the run.

Smallest counter-example that breaks it:

The morning artifact accurately says `BROKEN` after eight hours of bad dispatches. That is useful, but autonomy already failed.

Risk register:

1. A once-daily artifact turns an operational control problem into a postmortem.
2. Human-readable markdown can drift from the JSON row if generated by separate logic.
3. Routine notification/reporting can train the fleet to optimize for narrative quality instead of closure quality.

Analysis and rationale:

The artifact is good as the "coffee readout." The actual measurement unit should be a 5-minute `status-history.jsonl` row with schema validation, exit codes, and threshold breach routing. Pushover should fire on threshold breach, not routine completion. This matches the "Notify sparingly" doctrine and makes the system act while Joshua is asleep.

Proposed plan diff:

```diff
diff --git a/00-PLAN-INPUT.md b/00-PLAN-INPUT.md
@@
-### M (Measurement): Morning ritual artifact
+### M (Measurement): Continuous status row plus morning rendering
@@
-The morning ritual = `flywheel-loop status --since=overnight --human` which renders the most-recent `status-history.jsonl` row as a markdown brief, leading with:
+The measurement unit is the append-only JSON status row emitted every 5min.
+The morning ritual is only a renderer:
+`flywheel-loop status --since=overnight --human`.
@@
-This is the artifact you read with coffee, not me composing a chat summary.
+This is the artifact Joshua reads with coffee, not an operator-composed chat
+summary. During the night, the same verdict drives controls:
+- `DEGRADED`: log, continue only if no hard safety threshold is breached
+- `BROKEN`: stop new dispatches, chain repair/status work per L70
+- repeated `BROKEN`: Pushover threshold-breach notification
+Routine reports do not notify.
```

Verdict on the morning ritual:

Conditional. The morning artifact is the right human artifact, but continuous monitoring is more valuable for autonomy. Treat the markdown report as a view over the control-plane row, not as the primitive.

## Missing primitives

1. **Dispatch lifecycle transaction primitive**

Failure mode observed: `dispatch_callback_overdue` had 82 events. P1/P2 reduce bad picks but do not make dispatch atomic.

Needed primitive: a transaction state machine around `ntm send`, prompt visibility, `br update --status=in_progress`, dispatch-log append, callback deadline, validation receipt, and retry/reap decision.

```diff
+### P7: Dispatch lifecycle transaction and callback SLA
+
+Every dispatch is a transaction with states:
+`candidate -> prompt_written -> sent -> visible -> work_started -> callback_received -> callback_validated -> integrated`.
+
+Acceptance gates:
+- every `sent` dispatch has a deadline
+- every overdue dispatch becomes retry, reap, fix bead, or no-bead receipt
+- no bead can be marked productive without callback validation
+- status exposes `dispatch_callback_overdue_rate`
```

2. **Sibling-inspection-first substrate-config gate**

Failure mode observed: alps spent hours on NIXPACKS/config while working siblings existed. The plan names sibling inspection but does not add a primitive.

```diff
+### P8: Sibling-inspection-first config gate
+
+Before any substrate-config debug dispatch, run a sibling diff against known-good
+repos or sessions and include the diff in the dispatch packet. If no sibling
+exists, callback must say `sibling_inspection=NONE_FOUND`.
+
+Acceptance gate: config-debug dispatches without sibling evidence fail callback
+validation.
```

3. **L70 no-punt enforcement gate**

Failure mode observed: orchestrator repeatedly described next work instead of executing it. The plan cites L70 but does not require a chain receipt.

```diff
+### P9: L70 same-tick chain receipt in fleet status
+
+When any primitive identifies a next actionable phase, the same tick must either
+execute it or emit `chain_blocked_reason=<concrete>`. Status exposes
+`l70_chain_required_unexecuted_count`.
+
+Acceptance gate: any `chain_required=true` row without `chained=true` or
+`chain_blocked_reason` makes the fleet verdict `BROKEN`.
```

4. **Duplicate fuckup collapse before metrics**

Failure mode observed: `fleet-propagation-failed` appeared 188 times as dup-encoded events. That can swamp prioritization.

```diff
+### P10: Fuckup dedupe and rate normalization
+
+Compute both raw and deduped fuckup counts using `(class, repo, bead_id,
+root_cause_hash, 30m bucket)`. Selection and reports use deduped rates; raw
+counts remain available for volume diagnostics.
```

5. **Storage low-water guard**

Failure mode observed: success criteria includes storage low-water distance, but no primitive acts on it.

```diff
+### P11: Storage low-water action gate
+
+Status includes `storage_low_water_gb`. Below 50GB, block nonessential
+dispatches and chain cleanup work in the same tick. Below 25GB, verdict is
+BROKEN and Pushover fires.
```

6. **Upstream issue-file routing for Jeff-stack gaps**

Failure mode observed: plan needs `bv --exclude`, and may need repair-label priority. Local command does not expose `--exclude`.

```diff
+### P12: Jeff-stack upstream issue-file bridge
+
+When a needed `bv`/`br` feature is missing, generate a local upstream issue
+draft with reproduction, desired CLI contract, and workaround. Do not patch or
+push Jeff-stack from this repo.
```

## Sequencing

The order should be revised.

Original sequence: P1 -> P2 -> P3 -> P4 -> P5 -> P6 -> M.

Recommended sequence:

1. **P1+P2 combined selector contract**: highest immediate leverage against Loop A. This is the first implementation bead, but it must include recent-dispatch suppression and selector evidence. P1 alone is too weak.
2. **P3-lite inside P1/P2**: emit minimal selector/status fields in dispatch-log and probe output immediately. This gives proof without waiting for the full status CLI.
3. **Full P3 status CLI**: canonical continuous verdict with L68/L70/L71 fields, status-history, schema, watch mode, exit codes.
4. **P7 dispatch lifecycle transaction**: directly attacks callback overdue and closure conversion.
5. **P4 reservation lease enforcement**: prevents shared bead substrate stalls, but only with abandoned/expired/live-stale classification.
6. **P5 recovery wiring**: integrate existing freeze/stall/peer-orch monitors into status and control.
7. **P6 repair aging**: feed status/selector after the core selector and status loop are trustworthy.
8. **M morning renderer**: last, because it should render status rows that already drive the system.

Should P3 ship first?

No for full P3. P3 is the better measurement substrate, but the plan already has a live, tested `bv --robot-next` result and a known bad selector. Waiting for full status first risks another planning loop. Ship a thin measurement slice with P1/P2, then full P3 immediately after.

Is P1 correct because it is the highest-leverage line change?

P1 is correct as the highest-leverage selector change, but the "line change" framing is unsafe. The smallest safe first ship is a small selector-contract patch, not a raw command substitution.

## Acceptance gates

Several current gates are not yet measurable or falsifiable enough.

Revised gates:

| Area | Current gate | Problem | Tighter gate |
|---|---|---|---|
| P1 replay | counterfactual closure rate >15% | Counterfactual closures are not directly provable. | `same_bead_redispatch_count <= 2`, `dispatches_to_blocked_or_closed == 0`, `watcher_unique_bead_ratio >= 0.75`, selector data hash present. |
| P1 implementation | one-line replacement | Does not bind actual repo surfaces. | Tests must update `tests/test_idle_pane_watcher_convergence.sh` and `tests/idle-state-probe.sh`; probe exposes `selector_source`. |
| P2 fallback | `bv --exclude` if exists | It does not exist. | Fixture proves fallback through `bv --robot-triage` or emits `no_candidate` with suppression reason. |
| P3 verdict | returns BROKEN | Needs schema and exit contract. | `flywheel-loop status --json --since=8h` validates schema and exits 3 for BROKEN. |
| P4 release | reservation older than 300s | Age-only release is unsafe. | Expired/abandoned/live-stale fixtures prove only expired/abandoned release. |
| P5 recovery | hash-converged 5min | Can false-positive and conflicts with existing SLO. | Recovery requires live truth healthy, L95 receipt, permit/refuse row, and post-recovery live evidence. |
| P6 repair | 6h Pushover | Too late. | 2h repair age makes verdict BROKEN; 4h threshold breach notifies. |
| M report | morning markdown exists | Too late for autonomy. | Status rows every 5min; morning markdown must be generated only from latest JSON row. |
| L70 | cited in constraints | No hard gate. | Any required chain without `chained` or `chain_blocked_reason` makes status BROKEN. |
| Sibling inspection | named constraint | No primitive. | Config-debug dispatches require sibling diff or `NONE_FOUND`. |

Acceptance gate self-check:

- Minimum 5 git-diff-style proposed changes: satisfied above with P1-P6, M, P7-P12.
- Minimum 3 risk entries per primitive: satisfied for P1-P6 and M.
- Explicit P1 verdict: conditional endorsement; highest selector fix, not one-line.
- Explicit M verdict: morning artifact useful, continuous monitoring more valuable.
- Composite score after proposed revisions: 9.18.

## Multi-model-triangulation

Execution note: after Joshua's correction, no external model outputs are used in this review. This is GPT-5.5 running the `/planning-workflow` exact prompt as GPT Pro parity. The triangulation below is lens-based, not separate Grok/Opus/Sonnet execution.

Consensus across lenses:

- P1 points at the right substrate: `br ready` answers "can work"; `bv --robot-next` answers "should work."
- P1 must not ship without P2's recent-dispatch suppression.
- P3's computed verdict is the real system-goal primitive, but a full status CLI should not delay the selector fix.
- M is a good readout, not a control loop.
- P4 and P5 should reuse existing reservations, L107, L68, L95, L115, and L117 instead of adding parallel private logic.

Divergence:

| Topic | GPT-5.5 verdict | Jeff lens | Donella lens | Joshua/public lens |
|---|---|---|---|---|
| Ship P1 first? | Yes, revised with P2 | Yes, use canonical primitive now | Yes only if measured against closures | Yes if it reduces founder intervention tonight |
| Is P3 first? | Full P3 second; P3-lite with P1 | Do not block the line fix on dashboard work | Measurement must accompany goal change | Need morning truth, but not at cost of another no-op night |
| Force-release reservations? | Only expired/abandoned | Enforce substrate contract, not vibes | Change rules, not thresholds alone | Avoid corrupting work while founder sleeps |
| Auto-respawn | Reuse existing permit-gated monitors | One owner per invariant | Negative feedback loop with source truth | No false recovery surprises |
| Morning artifact | Keep as renderer | Not a primitive | Information flow after the run | Useful only if system already acted |

Unique lens findings:

- Jeff lens: `bv --exclude` absence is decisive. The plan must either use `bv --robot-triage` as fallback or file an upstream issue draft.
- Donella lens: P3 is the true goal-level intervention. P1 is a rule/information-flow fix that supports the goal.
- Joshua/public lens: a plan that produces a beautiful morning report after a broken night still fails the mission.
- GPT-5.5 synthesis: combine P1 and P2, add a minimal status row immediately, then build the full status primitive.

## Final recommendation

Ship first:

**P1+P2 combined selector contract**, with these non-negotiable gates:

- `bv --robot-next` is called once and full JSON evidence is preserved.
- Existing `br ready` counts remain as context, not primary selection.
- Recent-dispatch suppression consults dispatch-log, callback state, and local cooldown.
- No reliance on `bv --exclude`.
- Fallback uses `bv --robot-triage` or emits a no-candidate suppression receipt.
- Dispatch-log row records selector source, score, data hash, reasons, and suppression state.
- Replay proves same-bead redispatch <=2, dispatch to blocked/closed beads =0, and unique bead ratio >=0.75.

Ship second:

**P3 full continuous status**, not just morning markdown:

- `flywheel-loop status --json --since=8h`
- `flywheel-loop status --watch -i 300 --json`
- `flywheel-loop status --human --since=overnight`
- status-history append every 5min
- L68 no-silent-darkness fields
- L70 chain failure fields
- callback overdue and selector legality fields

Defer:

- P4 until it is lease-classification based, not age-only force release.
- P5 until scoped as wiring existing monitors, not creating a new detector.
- P6 until P3 can expose repair age as a hard verdict reason.
- M until continuous status rows exist.

Drop entirely:

- Any direct local fork/patch of Jeff-stack for `bv` behavior.
- Any dependency on `bv --robot-next --exclude`.
- Any routine Pushover for normal morning/report completion.
- Any artifact-only measurement that does not drive the overnight control loop.

Callback values:

- verdict: revise
- proposed_changes: 13
- risk_entries: 21
- bv_replacement_endorsed: conditional
- measurement_artifact_endorsed: conditional
- ship_first_primitive: P1+P2
- defer_list: P4,P5,P6,M-after-P3
- drop_list: bv-exclude-dependency,age-only-force-release,routine-notify,artifact-only-measurement
