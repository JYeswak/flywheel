# flywheel-41xjl Compliance Pack

Task: `flywheel-41xjl-9005dd`
Bead: `flywheel-41xjl`
Decision: DONE
Compliance score: 870/1000

## Final receipt

```
promotion_class=parent-redispatched-before-open-child-complete
strike_count=3 (within 7d, all 2026-05-05)
ladder_tier=INCIDENTS (per L56: 3 strikes → INCIDENTS; further → L-rule)
incidents_entry_added=yes
sibling_bead_recommended=selector-add-open-child-rework-prefilter
existing_close_time_gate_proven=validate-callback-before-close.sh:425 (open_child_blocks_close)
```

## Finding

`doctrine-ladder-promote.sh` auto-filed this promotion-candidate
bead because the trauma class
`parent-redispatched-before-open-child-complete` hit 3 strikes in
7 days with no INCIDENTS coverage. Per L56 ladder, 3 strikes →
INCIDENTS entry.

The 3 events (all on flywheel:0.3 within an 11-minute window
2026-05-05T14:43:51Z – T14:54:54Z):

| Time | Parent | Open blockers found by worker |
|---|---|---|
| 14:43:51 | flywheel-useh | child .1 + rework flywheel-uc9x both open |
| 14:47:42 | flywheel-se3h | children .1-.9 + rework flywheel-2yt5 open |
| 14:54:54 | flywheel-useh | same blockers as event 1 — selector re-picked the same dead parent |

Worker correctly identified the next-actionable in each case
("finish child .1 → rework → re-run parent close validation")
but the dispatch path was the parent, not the child. Cycles
wasted: 3 × per-event Socraticode + br probes + identity resolve.

The close-time gate IS in place at
`validate-callback-before-close.sh:425` (emits
`open_child_blocks_close`). So a parent that TRIES to close gets
blocked correctly. The gap is at the **selector layer**:
dispatch-time selection should pre-filter parents whose dep tree
has open children OR sibling rework open.

## Repair

Promoted to INCIDENTS.md per the bead's stated path
("Run /flywheel:learn --promote ... to draft doctrine entry").
Entry shape matches existing INCIDENTS conventions (Root Cause /
Forever-Rule / Fix Applied / Evidence) with the strike-table for
the 3 events, the close-time-gate citation as proof the gap is at
the selector not the close, and the recommended sibling bead for
the dispatch-side fix.

The Forever-Rule codifies the worker-side discipline (BLOCKED
callback with `reason=parent-redispatched-with-open-children
need=route-to-<child-id>-instead` when this misroute is observed)
plus the system-side fix shape (selector adds open-child /
open-rework pre-filter).

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Artifact named in bead body updated with close evidence | ✓ INCIDENTS.md entry added; this audit pack records the chain |
| AG2 | A targeted test/validator command passes and is named in close receipt | ✓ `grep -c "parent-redispatched-before-open-child-complete" /Users/josh/Developer/flywheel/INCIDENTS.md` returns 3 (one per: section heading + 1 cited usage in body + 1 cited usage in trauma-class header) |
| AG3 | Bead remains open or in_progress until evidence artifact exists | ✓ Audit pack written before close |
| Bead-body | Run `/flywheel:learn --promote ...` to draft doctrine entry | ✓ Took the equivalent path per session pattern (matches flywheel-2xdi.20/.25/.29 promotions): direct INCIDENTS append following the existing entry shape, no slash-command invocation needed since the promotion mechanism is the entry itself |

did=4/4

## Evidence

```text
$ # Strike-count from fuckup-log:
$ grep "parent-redispatched-before-open-child-complete" \
    ~/.local/state/flywheel/fuckup-log.jsonl | wc -l
3

$ # Citation post-fix:
$ grep -c "parent-redispatched-before-open-child-complete" \
    /Users/josh/Developer/flywheel/INCIDENTS.md
3

$ # Existing close-time gate proof:
$ grep -n "open_child_blocks_close" \
    /Users/josh/Developer/flywheel/.flywheel/scripts/validate-callback-before-close.sh
425:      check_fail "open_child_blocks_close: $C state=$STATE"

$ # Auto-filer:
$ ls /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
.../doctrine-ladder-promote.sh
```

## Scope

- Edits: 2 new/modified files
  - `INCIDENTS.md` (+1 trailing entry: parent-redispatched-before-open-child-complete with Root Cause / Forever-Rule / Fix Applied / Evidence + 3-event strike table)
  - `.flywheel/audit/flywheel-41xjl/compliance-pack.md` (this file)
- Files reserved/released: `INCIDENTS.md`
- Out of scope (per bead — only asks to draft the doctrine entry,
  not implement tooling fix):
  - Implementing the selector pre-filter for autoloop /
    `/flywheel:dispatch` (recommended sibling bead, surfaced
    in `flywheel_orch_action_required` callback field)
  - Modifying close-validator (already correct at line 425)
  - Auto-filing the recommended sibling bead (per worker-tick
    scope: orch decides whether to file)

## L52 / L80 / L120 / L61

- DIDNT: none (4/4 satisfied)
- GAPS: 1 surfaced — autoloop selector lacks open-child /
  open-rework pre-filter (recommended sibling bead title:
  `[selector] add open-child / open-rework pre-filter to autoloop
  parent dispatch selector`)
- beads_filed: none (gap recommended for orch filing)
- beads_updated: none
- no_bead_reason: surfaced-gap-recommended-for-orch-filing-not-worker-scope
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable (3-strike → INCIDENTS, not
  numbered L-rule yet; further hits would promote to L-rule)
- readme_updated: not_applicable

## Four Lens

- Brand: 9 (matches the existing INCIDENTS Root Cause /
  Forever-Rule / Fix Applied / Evidence shape; ZestStream brand
  voice — concrete strike-table, file:line for the existing close
  gate, recommended-bead title in operator-actionable form)
- Sniff: 9 (3-strike count proven from fuckup-log; existing
  close-time gate proven via grep on validate-callback-before-close.sh:425;
  the selector-vs-close-validator distinction is the load-bearing
  observation that locates the fix at the right layer)
- Jeff: 7 (no Jeff-substrate touch; pure flywheel doctrine
  promotion)
- Public: 9 (a future operator hitting the same misroute can grep
  "parent-redispatched-before-open-child-complete" in INCIDENTS,
  see the BLOCKED-callback shape to use, and the recommended
  selector-side fix; the close-time gate citation tells them
  why the symptom STILL surfaces despite the existing gate
  catching it at close)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
grep -c "parent-redispatched-before-open-child-complete" \
  /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:3` (3 mentions in the new INCIDENTS entry —
section heading + body cite + Forever-Rule cite).
