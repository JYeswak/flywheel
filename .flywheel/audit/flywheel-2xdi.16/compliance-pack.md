# flywheel-2xdi.16 Compliance Pack

Task: `flywheel-2xdi.16-454e64`
Bead: `flywheel-2xdi.16`
Decision: DONE
Compliance score: 870/1000

## Finding

The gap-hunt-probe `doctrine-without-measurement` class flagged that
`AGENTS.md` mentions `L60` but `~/.claude/commands/flywheel/tick.md` (the
`tick_text` source in `gap-hunt-probe.sh:997`) had zero references to L60,
loop-integrity, or the 5-signal contract.

The probe regex (gap-hunt-probe.sh:435) is `l[-_ ]?60` case-insensitive against
`tick_text`. Pre-fix grep count: 0. Post-fix grep count: 3.

## Repair

Added an `Observability Hooks (doctrine-to-measurement map)` section to
`/Users/josh/.claude/commands/flywheel/tick.md` immediately after
`## Cross-references`. The section names L60 and points to
`.flywheel/rules/L014-L60-loop-integrity-5-signal-contract.md`, then maps each
of the five L60 signals (ledger writes, pane state change, receipt files,
callback received, fuckup decisions) to the existing tick steps that already
measure them: Step 1, Step 2, Step 3, Step 7, Step 5.

No tick logic changed — the steps already implement the contract. Only the
naming gap was closed so the doctrine-to-measurement map is now greppable.

## Scope

- Edit: `/Users/josh/.claude/commands/flywheel/tick.md` (only file changed)
- File reservation reserved+released via `shared-surface-reservation-check.sh`
- Out of scope: other `doctrine-without-measurement` rules (L48, L001, L29,
  L002, L35, etc.) — those are separate beads, not flywheel-2xdi.16.

## Evidence

- Pre-edit grep: `grep -ciE "L60|loop[-_ ]integrity|5[-_ ]signal" /Users/josh/.claude/commands/flywheel/tick.md` → `0`
- Post-edit grep: same command → `3`
- gap-hunt-probe re-run: `bash .flywheel/scripts/gap-hunt-probe.sh` →
  `gap_ids` no longer contains `doctrine-without-measurement:l60`
  (verified via `python3 -c "json.load(...)"` filter against persisted output).
- Probe source: `.flywheel/scripts/gap-hunt-probe.sh:422-440`
  (`probe_doctrine_without_measurement`).
- Rule under test: `.flywheel/rules/L014-L60-loop-integrity-5-signal-contract.md`.

## L52 / L80 / L120

- DIDNT: none
- GAPS: none new beyond the existing siblings under flywheel-2xdi
- beads_filed: none (single-rule fix, sibling rules already filed as separate
  flywheel-2xdi.* beads)
- br_close_executed: yes (run before callback)

## Four Lens

- Brand: 8 (named the contract by its canonical L-rule + 5-signal language)
- Sniff: 8 (verified pre/post grep delta and probe re-run; no logic change)
- Jeff: 7 (pure substrate, no Jeff-repo touch; doctrine surface only)
- Public: 8 (a future operator can grep `L60` in tick.md and see the
  map back to the rule + the steps that prove it)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — markdown doctrine edit, no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — tick.md is a slash-command spec, not a README

## L112 Probe

```
grep -ciE "L60|loop[-_ ]integrity|5[-_ ]signal" /Users/josh/.claude/commands/flywheel/tick.md
```
Expected: `grep:3` (or any positive integer ≥ 1).
