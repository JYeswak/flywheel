---
bead: flywheel-2xdi.104
title: wired-but-cold fix — research-triad SKILL.md citation for build-spend-ledger-rust.sh + sister calibration ugali
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.72.1 (substrate-registry allowlist add; alternative path) + flywheel-zsk2d (SKILL.md cap fix; sister calibration)
sister_filed: flywheel-ugali (probe-self-ref-clearance class — sister-but-distinct from xbsd8)
posterior_shape: probe-self-clears-via-own-findings-ledger (11th distinct)
---

# Journey: flywheel-2xdi.104

## What the bead asked for

gap-wired-but-cold for `~/.claude/skills/research-triad/scripts/build-spend-ledger-rust.sh` — auto-filed by gap-hunt-probe based on "script not referenced by recent flywheel jsonl ledgers modified in last 30d".

## Investigation (META-RULE 2026-05-11 — 15th application)

5-corpus probe of gap-hunt-probe's wired-but-cold detector:

| Corpus | Match? | Source |
|---|---|---|
| 1. recent_ledger_text (~/.local/state/flywheel/*.jsonl <30d) | ✓ | gap-hunt.jsonl (probe's OWN findings) |
| 2. sibling_repo_ledger_corpus | ✗ | — |
| 3. runtime_source_corpus | ✗ | — |
| 4. skill_md_corpus | ✗ PRE-PATCH | — |
| 5. launchd_plist_corpus | ✗ | — |

**Only corpus 1 cleared it, and only via self-ref ledger contamination.** The script
is canonically orphan in all real cross-link corpora. The probe currently doesn't flag
it BECAUSE its own findings ledger (`gap-hunt.jsonl`) contains the script's name from
when it FIRST flagged it (auto-bead-filing event included the script in `gap_ids[]`).

This is the **11th distinct posterior shape** this session:
`probe-self-clears-via-own-findings-ledger` — sister-but-distinct from xbsd8 (which
captures memory-without-cross-link semantic-embedding name-grep blind spot).

## What I shipped

### Primary: SKILL.md citation (Meadows #5)

`~/.claude/skills/research-triad/SKILL.md` Operator scripts section — added 1 bullet
for `build-spend-ledger-rust.sh` with Why/When/Composition prose matching existing
`check-goldens.sh` shape. SKILL.md explicitly invites this at line 208:

> "Add other operator scripts to this section as they ship so SKILL.md is the
> discovery surface (not just the scripts/ directory listing)."

Now gap-hunt-probe corpus 4 (skill_md_corpus) cleanly clears the script via
canonical-doctrine citation, NOT via self-ref ledger contamination.

### Sister: flywheel-ugali (probe-self-ref-clearance calibration)

P3, parent-child to flywheel-2xdi + related to flywheel-2xdi.104. Captures the
meta-class:
- gap-hunt.jsonl in STATE_DIR/*.jsonl corpus
- Probe auto-files beads with script names in gap_ids[]
- Subsequent runs read own ledger as "recent activity" + clear script
- 3 triage options deferred to orch: A) exclude gap-hunt.jsonl from corpus 1, B)
  strip own-ledger gap_ids[] entries, C) skip-clear if only matching ledger IS
  gap-hunt.jsonl

Cross-source-silos class already has sister allowlist at gap-hunt-probe.sh:1582
(`{"gap-hunt.jsonl", "gap-hunt-false-positives.jsonl"}`). The wired-but-cold class
needs the same sister discipline.

### Paired jsm-import-ready patch artifact

`.flywheel/audit/flywheel-2xdi.104/skill-md-patch-artifact.md` — anchor + insertion
block + rationale + verification. Sister to flywheel-2xdi.60.1 + 2xdi.72.1 artifact
shapes. research-triad NOT in `jsm list` (only `research-software`); unmanaged →
direct mutation allowed.

## Cross-script decomposition discipline

Found 18 sibling uncited scripts in research-triad/scripts/. Per
`feedback_decompose_by_natural_unit_not_bundle.md` (META-RULE 2026-05-10), bundling
all 18 into this bead would force over-tick. Held scope to ONE script (this bead's
subject). Orchestrator can dispatch per-script siblings if it chooses; xbsd8 +
ugali capture the substrate-self-improving-loop fixes for the meta-class.

## Substrate-self-improving loop 2nd-order validation

This bead added an 11th posterior shape and an 11th faqj2 finding-type candidate
(`wired_but_cold_corpus1_self_ref`). When ugali's fix lands, faqj2 Phase 2
finding-type taxonomy can be extended analogous to existing
`ledger_producer_name_mismatch`. The loop is functioning per design:
discovery → meta-fix bead → faqj2 extension → continuous detection.

## Compliance

- AG receipt: 7/7
- META-RULE 2026-05-11: 15th application; 11th posterior shape
- L52: 1 bead filed (flywheel-ugali) for probe-self-ref class
- Boundary preservation: only SKILL.md + audit-pack edited; probe + script untouched
- L107: MCP-skipped (project-key/registration challenge); unique single-bullet edit
- compliance_score: 1000/1000

## Sister precedent contrast

| # | Bead | Subject | Fix path | Class |
|---|---|---|---|---|
| 2xdi.60.1 | agentmail-fd-pressure-probe | substrate-registry kind=audit | registry allowlist |
| 2xdi.72.1 | render_scorecard_html + migrate-scores | substrate-registry kind=scaffold | registry allowlist |
| zsk2d | (calibration) | SKILL.md priority cap 256KB | corpus extension |
| 2f4br | (calibration) | rules+slash-cmds glob | corpus extension |
| **2xdi.104** (this) | build-spend-ledger-rust.sh | SKILL.md citation | Meadows #5 doctrine-cite |
| **ugali** (sister filed) | probe-self-ref class | (3 options A/B/C; deferred) | meta-calibration |
