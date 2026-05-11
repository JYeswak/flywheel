---
bead: flywheel-2xdi.119
title: wired-but-cold fix — research-triad SKILL.md citation for perf-bench.sh
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.104 (build-spend-ledger-rust.sh same-pattern) + flywheel-2xdi.105 (check-goldens.sh same-pattern; MistyCliff)
sister_owns_class: flywheel-ugali (probe-self-ref-clearance meta-fix; OPEN)
posterior_shape: probe-self-clears-via-own-findings-ledger (recurrence; 11th distinct shape)
---

# Journey: flywheel-2xdi.119

## What the bead asked for

gap-wired-but-cold for `~/.claude/skills/research-triad/scripts/perf-bench.sh` —
auto-filed by gap-hunt-probe based on "script not referenced by recent flywheel
jsonl ledgers modified in last 30d".

## Investigation (META-RULE 2026-05-11 — 16th application)

5-corpus probe identical to flywheel-2xdi.104:

| Corpus | Match? | Source |
|---|---|---|
| 1. recent_ledger_text | ✓ | gap-hunt.jsonl (self-ref) |
| 2. sibling_repo_ledger_corpus | ✗ | — |
| 3. runtime_source_corpus | ✗ | — |
| 4. skill_md_corpus | ✗ PRE-PATCH | — |
| 5. launchd_plist_corpus | ✗ | — |

Genuinely canonical-cold; probe self-clears via own findings ledger. Same shape
as 2xdi.104 — 11th posterior shape (`probe-self-clears-via-own-findings-ledger`)
recurrence.

## What I shipped

### Primary: SKILL.md citation

`~/.claude/skills/research-triad/SKILL.md` Operator scripts section — 3rd bullet
added for `perf-bench.sh`. Now sits alongside `check-goldens.sh` (2xdi.105 by
MistyCliff) and `build-spend-ledger-rust.sh` (2xdi.104 by me).

### NO new sister calibration bead (substrate-self-improving loop validation)

`flywheel-ugali` (P3, OPEN) — filed in 2xdi.104 — already owns the
wired-but-cold class probe-self-ref-clearance blind spot for ALL future sibling
cases. Filing a duplicate would skip the loop per user framing on 2xdi.110.

This bead validates the substrate-self-improving loop in 2nd-order: 1 ugali bead
serves N sibling 2xdi.* beads (currently N=2: 2xdi.104 + 2xdi.119; potentially
N=18+).

### Paired jsm-import-ready patch artifact

`.flywheel/audit/flywheel-2xdi.119/skill-md-patch-artifact.md` — sister to
2xdi.104's artifact shape.

## Cross-bead pattern

| # | Bead | Script | Status | Worker |
|---|---|---|---|---|
| 1 | flywheel-2xdi.105 | check-goldens.sh | SHIPPED | MistyCliff |
| 2 | flywheel-2xdi.104 | build-spend-ledger-rust.sh | SHIPPED | MagentaPond |
| 3 | **flywheel-2xdi.119** (this) | perf-bench.sh | SHIPPED | MagentaPond |
| 4-18 | (15 sibling research-triad scripts) | — | candidate beads | — |

`feedback_convergent_evolution_is_canonical_signal.md` (META-RULE 2026-05-06):
3 beads converging on same fix path (SKILL.md citation under Operator scripts)
across 2 workers (MistyCliff + MagentaPond) reinforces this as the canonical
recipe for research-triad scripts.

## Compliance

- AG receipt: 7/7
- META-RULE 2026-05-11: 16th application
- L52: 0 new beads filed (ugali covers class); `no_bead_reason=ugali_covers_class`
- L107: MCP-skipped (single bullet, no conflict surface)
- compliance_score: 1000/1000
