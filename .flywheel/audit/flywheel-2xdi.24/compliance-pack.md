# flywheel-2xdi.24 Compliance Pack

Task: `flywheel-2xdi.24-f194a1`
Bead: `flywheel-2xdi.24`
Decision: DONE
Compliance score: 870/1000

## Finding

`gap-hunt-probe.sh probe_without_receiver()` (lines 457-471) iterates every
`*-probe.sh` under `<repo>/.flywheel/scripts` and `~/.claude/skills`, then
checks if each script's basename or stem appears in the union of:

- `command_text()` — `~/.claude/commands/flywheel/{tick,status,synth}.md`,
  `<repo>/AGENTS.md`, `<repo>/INCIDENTS.md`, `<repo>/README.md`
- `~/.local/state/flywheel-loop/last_tick_*.json`

Pre-fix grep across those receivers: zero references to
`ticks-punted-probe.sh`. The probe is referenced in MISSION.md,
canonical-paths.txt, and various receipts/plans, but none of those
surfaces are sampled. The L70 counter twin
(`l70-ticks-punted-counter.sh`) is cited in `tick.md` Step 8b but the
read-only audit probe was orphaned from the canonical receiver set.

## Repair

Edited `tick.md` Step 8b to add an **"Audit twin (read-only)"**
subparagraph immediately after the L70 counter's apply-mode block. The
new text:

- Names `.flywheel/scripts/ticks-punted-probe.sh --json` explicitly so
  the receiver-scan regex matches.
- Documents the operational pairing: counter is the apply-mode writer;
  probe is the read-only diagnostic that surfaces `malformed_rows[]`,
  which would silently pollute the counter's input if not caught.
- Frames the trigger condition: "investigate a counter mismatch or a
  sudden change in the L70 trend" — gives operators a concrete reason
  to run the probe rather than burying it as background diagnostic.
- Marks the probe as safe-from-any-pane (read-only) so workers know
  they don't need pane-1 owner discipline to invoke it.

No tick logic changed. The probe was already runnable; the gap was
purely the receiver-scan visibility.

## Acceptance Gate Map

The bead's only test gate is implicit: gap-hunt-probe should no longer
surface `probe-without-receiver:ticks-punted-probe.sh`.

- AG1: post-edit gap-hunt-probe re-run returns empty for that gap id. ✓
  (`hits=[]`)

did=1/1

## Evidence

```text
$ grep -cE "ticks-punted-probe|ticks_punted_probe" /Users/josh/.claude/commands/flywheel/tick.md
# pre-fix: 0
# post-fix: 2

$ bash .flywheel/scripts/gap-hunt-probe.sh \
  | python3 -c 'import json,sys; d=json.load(sys.stdin);
                hits=[g for g in d.get("gap_ids",[])
                      if "probe-without-receiver" in g and "ticks-punted" in g];
                print("post-fix hits:", hits)'
post-fix hits: []

$ .flywheel/scripts/ticks-punted-probe.sh --json | jq '.status, .ticks_punted_count, .malformed_row_count'
"ok"
0
12
# probe runs; surfaces 12 malformed dispatch-log rows the counter
# would have silently swallowed — confirms the probe is materially
# useful, not just receiver-bait
```

## Scope

- Edits: 1 file (`/Users/josh/.claude/commands/flywheel/tick.md`,
  +12 lines for the Audit-twin subparagraph)
- Files reserved/released: tick.md
- Out of scope: the 19 other `probe-without-receiver` gaps in the same
  probe run — those are separate scripts with their own beads. Doing
  them in this dispatch would be scope creep.

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: single-probe-receiver-wire-no-followup
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable (tick.md is the receiver surface,
  not AGENTS.md)
- readme_updated: not_applicable
- L61 ecosystem-touch: tick.md is a slash-command spec; the canonical
  surface for orchestrator hook documentation. No README/AGENTS sibling
  needed.

## Four Lens

- Brand: 8 (Audit-twin framing matches existing tick-step language;
  marks the operational pairing rather than just dropping a script
  reference)
- Sniff: 9 (pre/post grep delta + probe re-run + script run confirms
  the probe is materially useful — surfaces 12 malformed rows)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 9 (a future operator investigating counter mismatch can find
  the audit twin in tick.md Step 8b instead of having to grep canonical-paths.txt)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added (probe already had its own
  --help and --json contract pre-existing this dispatch)
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
grep -cE "ticks-punted-probe" /Users/josh/.claude/commands/flywheel/tick.md
```
Expected: `literal:2` (2 mentions in the new Audit-twin subparagraph:
script path + invocation example).
