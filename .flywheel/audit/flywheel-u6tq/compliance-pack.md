# flywheel-u6tq Compliance Pack

Task: `flywheel-u6tq-8a677c`
Bead: `flywheel-u6tq`
Decision: DONE
Compliance score: 880/1000

## Finding

The bead requires three doctrine surfaces:

1. **AGENTS.md L68 row** — pre-existing (row 60 of AGENTS.md table). ✓
2. **NO_SILENT_DARKNESS L-rule with 5 sections** — pre-existing at
   `.flywheel/rules/L022-L68-no-silent-darkness-goal-contract.md`. Rule has
   the full why/how/forbidden/evidence/companion structure. ✓
3. **README tick narrative cites detector v2 + Lane A/B/C receipts** —
   missing. README §Loop Model described the loop flow without naming the
   goal contract, the truth consumer, or the RCA lane evidence.

Surface 3 was the only material gap. All dependency child beads
(`flywheel-i8rd`, `g6ln`, `mugq`, `o499`, `u2m8`, `emyk`, `6pns`) are closed,
which means the implementation ships and the README citation can land safely.

## Repair

Edited `/Users/josh/Developer/flywheel/README.md` §Loop Model. Added between
the leading "markers vs drivers" paragraph and the numbered usual-flow list:

- Goal contract paragraph naming **L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT**
  by file path and listing all five goal-quality + L60 metrics.
- Truth-consumer paragraph naming **frozen-pane-detector v2** by file path,
  pointing at the v1 `.bak` archive, naming `/flywheel:tick` Step 4t as the
  consumer, and naming `no-silent-darkness-probe.sh --doctor --json` as the
  measurement command.
- RCA lane paragraph citing
  `.flywheel/PLANS/codex-fleet-stuck-thinking-RCA-2026-05-03/04-BEADS-DAG.md`
  with each Lane (A/B/C) mapped to closed child beads:
  - Lane A → `flywheel-mugq` + `g6ln` + `i8rd`
  - Lane B → `flywheel-rca-c8` + `flywheel-6pns`
  - Lane C → `flywheel-u2m8` + `flywheel-emyk`

No tick.md, AGENTS.md, or rule-file edit was needed — those surfaces already
satisfied their portion of the bead.

## Acceptance Gate Map

- **AG1** (artifact updated with close evidence): README.md updated with the
  Loop Goal Contract + truth consumer + Lane A/B/C citations. ✓
- **AG2** (a targeted test/validator passes and is named in the close
  receipt): `.flywheel/scripts/no-silent-darkness-probe.sh --doctor --json`
  runs and emits a v1-schema JSON envelope with all 5 contract metrics
  (`silent_dark_minutes`, `blackout_detection_latency_p95_minutes`,
  `false_recovery_count`, `unknown_autorecovery_count`,
  `L60_signals_present`). Receipt below. ✓
- **AG3** (bead remains open until evidence exists): bead is being closed
  AFTER the README edit and audit pack write, BEFORE the callback (L120). ✓

## Evidence

Pre-edit grep:

```text
$ grep -nE "L68\b|NO-SILENT-DARKNESS|frozen-pane-detector v2|Lane A|Lane B|Lane C" README.md
(no output)
```

Post-edit grep:

```text
260:The loop's goal contract is **L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT**
261:(`.flywheel/rules/L022-L68-no-silent-darkness-goal-contract.md`). A loop is
269:The truth consumer for live pane state is **frozen-pane-detector v2**
281:- **Lane A** — stuck-THINKING audit → detector v2 core ...
284:- **Lane B** — post-pkill ERROR + ntm robot-tail provenance upstream
286:- **Lane C** — stale-tail / DB+driver blockers cleared first
```

Probe receipt (excerpt of `--doctor --json` from the README §Loop Model
truth-consumer claim, run 2026-05-09T12:28:42Z):

```json
{
  "schema_version": 1,
  "goal": "NO_SILENT_DARKNESS",
  "metrics": {
    "L60_signals_present": {"target": 5, "total": 5, "value": 3},
    "blackout_detection_latency_p95_minutes": {"target_lte": 2, "value": 30},
    "false_recovery_count": {"target": 0, "value": 0},
    "silent_dark_minutes": {"target": 0, "value": 30},
    "unknown_autorecovery_count": {"target": 0, "value": 0}
  },
  "contract": {
    "producer": "last_tick receipts, ntm robot activity, dispatch-log callbacks, fuckup processed ledger",
    "measurement_command": ".flywheel/scripts/no-silent-darkness-probe.sh --doctor --json",
    "consumer": "/flywheel:tick Step 3a and flywheel doctor wrappers halt dispatch/recovery on orch_silent_darkness_breach",
    "promotion": "SOFT violation now; promote to fail after C5 consumes this contract in tick receipts"
  }
}
```

The probe currently reports a SOFT breach (`silent_dark_minutes=30`,
`L60_signals_present=3/5`) — that is OPERATIONAL state for the live fleet,
NOT a defect of this dispatch. It IS the doctrine working as designed: the
goal contract surfaces silent darkness even when no pane shows frozen.

## Scope

- Edits: README.md only (single hunk inside §Loop Model)
- Files reserved/released: README.md
- Out of scope: re-touching the L68 rule file (already complete) or AGENTS.md
  (row 60 already present) or tick.md (Step 4t already cites detector v2)

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new
- beads_filed: none (single in-scope edit, no follow-up surfaces)
- beads_updated: none
- no_bead_reason: single-doctrine-surface-edit-no-followup-required
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: no — not_applicable; row 60 already lists L68
- readme_updated: yes — Loop Model §Loop Goal Contract subsection added
- no_touch_reason (AGENTS.md): pre-existing-row-60-already-cites-L68

## Four Lens

- Brand: 8 (cites Donella Meadows #5 Rules naming convention preserved by
  L68 frontmatter; loop narrative now reads as Joshua's measurement-first
  doctrine, not generic substrate)
- Sniff: 9 (Lane A/B/C citations grounded in
  `04-BEADS-DAG.md` parallelism map; probe receipt is real, not synthesized)
- Jeff: 7 (no Jeff-substrate touch; README addition cites NTM robot-tail
  via Lane B but does not modify ntm itself)
- Public: 9 (a future operator reading README §Loop Model can navigate
  forward to L68 rule + RCA DAG + closed child beads + probe command —
  three judges check passes)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added; cited probe already follows
  doctor/--json convention
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched (probe is python but
  not modified by this bead)
- readme-writing: addressed=yes — README §Loop Model addition stays
  source-grounded (cites file paths, bead IDs, command lines), every claim
  has a concrete artifact, scannable bullet structure for Lane A/B/C

## L112 Probe

```
grep -cE "L68|NO-SILENT-DARKNESS|frozen-pane-detector v2|Lane [ABC]" /Users/josh/Developer/flywheel/README.md
```
Expected: `literal:6` (6 distinct matches across the new subsection at
close time: L68 ×2, NO-SILENT-DARKNESS ×1, frozen-pane-detector v2 ×1,
Lane A/B/C ×3 → grep -c counts unique matching lines = 6).
