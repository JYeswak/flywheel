# Loop-Non-Accretive Trauma Class

A failure mode where `/flywheel:tick` runs through ceremony (read state, emit
DECISION, write receipt, update last_tick.json, arm Monitor, ScheduleWakeup)
without producing accretion (dispatch sent, callback reaped, bead closed,
artifact landed).

## Symptom

- Loop state shows `active: true`
- Last_tick.json updates on cadence
- Closeout receipts validate `receipt_ok=true`
- `~/.flywheel/loops/<project>.json` reflects healthy driver
- BUT: workers stay WAITING, dispatch-log shows no fresh `dispatch_sent` events,
  bead queue doesn't shrink, callbacks Monitor never fires fresh events.

## Root cause class

The loop driver fires the tick, the tick reads state and emits ceremony, but
skips step 4 of `LOOP.md` ("Dispatch every idle worker pane unless a named
approval gate blocks it"). The orchestrator punts dispatch to "next tick" and
the cycle repeats indefinitely.

Common punt-rationales (all L70 NO-PUNT failures per memory rule):
- "L130 dispatch wrapper requires /flywheel:dispatch invocation" — yes, then
  invoke it
- "Each bead has 5 ACs and would take 30-60min" — fine for a worker, dispatch
  to one
- "Workers might be busy" — probe `ntm --robot-activity`, dispatch to actual
  WAITING panes
- "Need to ask Joshua first" — only TRUE-blocker classes need Joshua per
  `feedback_orch_handshakes_never_gate_on_joshua`

## Documented incident

2026-05-08T15:30Z — Joshua surfaced after observing 9-hour idle: cc loop
pulse activated via `Skill("loop", "30m /flywheel:tick")`, receipt validated,
Monitor armed. But the tick body itself audited beads (closed 2 stale) without
calling `/flywheel:dispatch`. Workers across flywheel:2/3/4 + skillos:2 +
alps:2/3/4 stayed WAITING. Receipt recorded `tick_class=dispatch_reap` but
the bead_receipt detail showed audit-only closes, not callback-reap closes.

## Detection

A tick is non-accretive when ALL of these hold:
- `dispatches_sent_this_tick == 0`
- `callbacks_reaped_this_tick == 0`
- `beads_closed_via_callback_this_tick == 0`
- `ntm --robot-activity` shows >=1 WAITING worker pane
- `br ready --json --limit 1` returns >=1 ready bead
- No `JOSHUA_OVERRIDE` justifying idle

If all hold, the tick is ceremony, not accretion.

## Fix

The /flywheel:tick body MUST execute one of these accretive paths each tick:

1. **Dispatch path**: Call `/flywheel:dispatch <pane> <bead-or-spec>` for at
   least one WAITING worker if ready beads exist. Records dispatch event in
   `<repo>/.flywheel/dispatch-log.jsonl`.

2. **Reap path**: Process at least one callback from dispatch-log since last
   tick (close bead with evidence validation).

3. **Local-lane path**: Make a scoped change to repo state (commit, doc,
   bead close with verifiable evidence). Receipt records what changed.

4. **Audit path** (fallback when 1-3 unavailable): Run a probe that produces
   a finding bead. Receipt records the new bead ID. Audit findings without
   bead filing don't count as accretive.

If NONE of 1-4 happen, the tick MUST emit a self-correction record:
```json
{"event": "tick_non_accretive", "ts": "<UTC>", "reason": "<class>", "ready_beads": <N>, "waiting_workers": <N>}
```
to the dispatch-log AND ScheduleWakeup at 600s (not 1800s) to retry sooner.

## Receipt extension

Add to closeout receipt v2:
- `accretive_signals`: object with counts (`dispatches_sent`, `callbacks_reaped`,
  `beads_closed_via_callback`, `commits_with_substrate_change`, `findings_filed`)
- `accretion_path`: enum (`dispatch | reap | local_lane | audit | non_accretive`)
- `non_accretive_reason`: string (required when accretion_path=non_accretive)

Receipts where `accretion_path=non_accretive` are valid (they record the
failure honestly) but increment a fleet-level non-accretive-tick counter.
Three consecutive non-accretive ticks for the same project trigger a doctor
warn surface; five trigger a doctor fail.

## Validator false-positive: capture_disagreement_reminder_template

A specific L70-NO-PUNT root cause discovered 2026-05-08T15:46Z when investigating
9-hour fleet idle: the `dispatch-pre-send-validator.sh` two-truth-sources gate
refuses dispatch with reason `capture_disagreement_reminder_template` when a
codex pane shows `state=WAITING` per robot-activity but the tail capture shows
a CASS reminder template in the buffer.

**Joshua directive 2026-05-08:** "codex workers always have prepared buffer
content sitting there - we just have to paste into it." The "reminder template"
is the codex pane's NORMAL prepared chevron buffer waiting for input. The
validator treats this as a stale-buffer disagreement when it is actually the
expected pre-dispatch state.

**Impact:** Three flywheel worker panes (2/3/4), one skillos pane, three alps
panes, two mobile-eats panes were all blocked from dispatch by this false
positive. Orchestrators that respected the validator's ABORT instruction
correctly per the contract sat idle while the substrate was actually
dispatchable. Result: 9+ hours of fleet idle when 300 ready beads existed.

**Override pattern (used 2026-05-08T15:46Z):** When the validator refuses with
`capture_disagreement_reminder_template` AND the pane is a codex worker AND
robot-activity confirms `state=WAITING capture_provenance=live`, log an
override to dispatch-log and proceed:

```text
validator_override_reason="codex_prepared_buffer_normal_state_per_joshua_directive_2026_05_08_dispatch_validator_false_positive_capture_disagreement_reminder_template"
```

The dispatch packet still gets built via `build-dispatch-packet.sh`; the L130
gate is satisfied by `FLYWHEEL_DISPATCH_WRAPPER=1` env on the ntm send. Only
the false-positive 1b cross-check is bypassed.

**Permanent fix (followup bead recommended):** The validator should distinguish
the prepared-codex-chevron pattern from a genuinely stale buffer (e.g. an
incomplete previous dispatch that never submitted). Until then, the override
pattern above is canonical for codex-pane dispatches.

## Cross-references

- LOOP.md step 4 ("Dispatch every idle worker pane")
- Memory: `feedback_orch_punt_is_l70_failure_dispatch_dont_ask`
- Memory: `feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker`
- Memory: `feedback_data_decides_not_human_meatpuppet`
- Skill: `/flywheel:dispatch` (the L130 wrapper that satisfies dispatch transport gate)
- Validator: `~/.claude/commands/flywheel/_shared/dispatch-pre-send-validator.sh`

## Joshua lens

A 25-year operations manager watching a shift report would not accept "team
checked in, wrote shift notes, scheduled next check-in" as a productive shift
when the floor was empty and orders were waiting. The loop's job is to move
work, not to file paperwork about moving work.
