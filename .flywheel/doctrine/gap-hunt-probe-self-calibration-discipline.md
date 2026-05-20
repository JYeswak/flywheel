---
name: gap-hunt-probe-self-calibration-discipline
type: doctrine
created: 2026-05-11
updated: 2026-05-11
authors:
  - flywheel-faqj2 (MagentaPond / flywheel:0.3) — initial doctrine fold-in motivated by N=7 calibration findings in 1 session
parent_beads:
  - flywheel-2xdi (constant-gap-hunter; emits findings the calibrations consume)
  - flywheel-faqj2 (meta-bead this doctrine canonicalizes)
sister_beads:
  - flywheel-e7lxv (wired-but-cold launchd corpus)
  - flywheel-kckw8 (probe-without-receiver 3-corpus)
  - flywheel-6n1v1 (probe-without-receiver skill-lib)
  - flywheel-2xdi.60.1 (probe-without-receiver allowlist consultation)
  - flywheel-zsk2d (wired-but-cold SKILL.md cap regression)
  - flywheel-nq5ns (cross-source-silos producer-stem fallback)
  - flywheel-2f4br (command_text() rules + all-slash-cmds)
sister_doctrines:
  - bead-hypothesis-starting-point
  - audit-machinery-hygiene-discipline
status: ratified
---

# Gap-Hunt-Probe Self-Calibration Discipline

## TL;DR

The probe that surfaces gaps in other substrates must ALSO surface gaps in itself. Otherwise every per-bead false positive consumes a worker tick × investigation evidence pack × calibration follow-on × shipping commit cycle — when ONE periodic probe-of-the-probe could surface the entire class at once.

Sister surface: `.flywheel/scripts/gap-hunt-probe-self-calibration.sh` (canonical-CLI; read-only; proposals only; never auto-applies).

## Why this doctrine exists — N=7 in one session

On 2026-05-11, gap-hunt-probe.sh accumulated **7 calibration findings in a single ~24-hour worker session**, each surfaced by an individual per-bead worker triage:

| # | Bead | Class | Calibration shipped |
|---|---|---|---|
| 1 | `flywheel-e7lxv` | wired-but-cold | launchd plist corpus added |
| 2 | `flywheel-kckw8` | probe-without-receiver | 3-corpus extension (in-repo + launchd + tests) |
| 3 | `flywheel-6n1v1` | probe-without-receiver | skill-lib `~/.claude/skills/.flywheel/lib/**` added |
| 4 | `flywheel-2xdi.60.1` | probe-without-receiver | on-demand allowlist consultation |
| 5 | `flywheel-zsk2d` | wired-but-cold | SKILL.md cap regression 4 KB → 256 KB priority cap |
| 6 | `flywheel-nq5ns` | cross-source-silos | producer-script-name fallback for `*-runs.jsonl` |
| 7 | `flywheel-2f4br` | command_text() corpus | `.flywheel/rules/*.md` + all-slash-commands glob |

Each finding was correctly diagnosed per META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion). Each calibration shipped applied Meadows #5 leverage (fix the property, not the proxy — extend corpus / change name-match form / etc., not allowlist individual scripts).

**Burn rate observation:** 7 findings × ~1 hour avg worker tick = ~7 hours of worker time on probe-self-improvement that one daily-run self-calibration probe would have surfaced as a single batch.

## The discipline

### Rule 1: every probe must have a self-calibration sibling

Any read-only probe that emits structural findings against substrate must have a co-located self-calibration probe that surfaces structural drift in the parent probe itself. The two probes form a pair:

- `<X>-probe.sh` — surfaces gaps in substrate
- `<X>-probe-self-calibration.sh` — surfaces drift in `<X>-probe.sh`'s own assumptions (corpus caps, glob patterns, name-match forms, byte budgets)

For gap-hunt-probe, this is the canonical pair:
- `.flywheel/scripts/gap-hunt-probe.sh` (existing; N=9 gap classes)
- `.flywheel/scripts/gap-hunt-probe-self-calibration.sh` (NEW; 5 finding types)

### Rule 2: 5 canonical finding types (extensible)

Self-calibration probes minimally cover these 5 drift signal types:

| Finding type | What it surfaces | Sister calibration precedent |
|---|---|---|
| `corpus_cap_approaching` | A corpus's byte size approaches its cap; future entries would be truncated | `flywheel-zsk2d` (SKILL.md 4KB → 256KB) |
| `orphan_script_no_glob_coverage` | Scripts in canonical dirs not matched by any corpus glob | `flywheel-6n1v1` (skill-lib glob extension) |
| `new_ledger_since_last_run` | New `*.jsonl` ledgers in STATE_DIR appearing since last snapshot — fresh substrates surface for triage | `flywheel-nq5ns` (cross-source-silos producer-stem) |
| `ledger_producer_name_mismatch` | `*-runs.jsonl` ledgers where neither basename nor stem nor producer-stem is in receivers_text | `flywheel-nq5ns` (already calibrated; this monitors for new patterns) |
| `large_skill_md_over_threshold` | SKILL.md files exceeding 50% of current cap (drift toward another cap bump) | `flywheel-zsk2d` |

Extensible: as new probe classes emerge (or new gap-hunt-probe corpora are added), self-calibration adds a corresponding finding type.

### Rule 3: severity discipline

Three levels, monotonically increasing:

- `info` — surface for awareness; no immediate action
- `warn` — approaching threshold; calibration likely needed soon
- `alert` — over threshold; calibration immediately needed (file follow-on bead)

The 50% / 70% / 85% utilization breakpoints are canonical defaults; configurable via `--threshold` CLI param.

### Rule 4: proposals only — never auto-apply

Self-calibration emits structured JSON proposals. Orchestrator (or Joshua) reviews and dispatches calibration beads. Anti-pattern: auto-applying corpus extensions or cap bumps would skip the Meadows #5 leverage discipline (each calibration deserves an evidence pack + sister-class chain documentation).

This mirrors `/flywheel:tick` Step 4o anti-pattern guardrail: probes SURFACE findings; orch DECIDES on action.

### Rule 5: integrate into tick OR launchd cadence

Self-calibration probes run periodically. Two canonical wire-in patterns:

1. **Per-tick invocation** — add to `/flywheel:tick` (Step 4o or sibling step); each tick consumes the JSON, files at most one calibration bead per cycle. Sister: `flywheel-myfak.1` Dim-9 wire-in for `adversarial-orch-self-audit-probe.sh`.

2. **Launchd cadence** — daily / hourly schedule (`ai.zeststream.gap-hunt-self-calibration.plist`). Sister: `flywheel-8p6fz` launchd wire-in for `worker-deep-liveness-probe.sh`.

For gap-hunt-probe-self-calibration, recommended wire-in is **per-tick** (sister to Step 4o measurement subsections). Filing as follow-on bead per `flywheel-faqj2.X` (cross-repo).

## Why this isn't a one-off

Multiple prior beads observed the threshold but deferred filing the meta-bead as overscope:

- `flywheel-kckw8` evidence pack (3rd calibration): *"After 2 instances the calibration pattern is operationally robust. If a 3rd surfaces, consider filing periodic gap-hunt-probe self-calibration review meta-bead."*
- `flywheel-2xdi.75` evidence pack (3rd recurrence): *"If a 4th distinct corpus extension is needed... consider whether the underlying class definition should switch from 'absent-from-corpora' to 'no-execution-evidence'."*
- `flywheel-2xdi.89` evidence pack (6th finding): *"Meta-bead candidate noted for periodic gap-hunt-probe self-calibration review; deferred this tick as overscope but flagged for future Joshua decision."*
- `flywheel-2xdi.103` evidence pack (7th finding): *"Pattern threshold strongly confirms periodic self-calibration meta-bead recommendation for next session."*

The pattern was visible from the 3rd instance; the meta-bead filing was deferred 4 times before being dispatched as `flywheel-faqj2`. This deferral was correct per individual-tick scope discipline — but at session-aggregate the deferred meta-bead would have prevented findings 4-7's per-tick burn.

**Discipline lesson:** when a deferred-meta observation appears in 3+ evidence packs, file the meta-bead at the 3rd instance, not the 7th. Sister doctrine: `bead-hypothesis-starting-point` (META-RULE 2026-05-11 produced 8 posterior shapes in 12 applications this session — apply to meta-pattern recognition too).

## Operational guidance

### When to invoke self-calibration

- **Per-tick** — orchestrator's `/flywheel:tick` Step 4o calls it; surfaces drift before next gap-hunt-probe run
- **Pre-calibration** — before filing any gap-hunt-probe calibration bead, run self-calibration to see if multiple drift signals can be addressed in one go
- **Post-deployment** — after shipping a gap-hunt-probe calibration, run self-calibration to verify no other signals are above threshold

### Reading the output

```bash
$ .flywheel/scripts/gap-hunt-probe-self-calibration.sh --json | jq -c '.summary'
{"total_findings":3,"by_type":{"corpus_cap_approaching":1,...},"by_severity":{"info":1,"warn":1,"alert":1}}
```

- `total_findings: 0` — substrate is calibrated; no action
- Any `alert` severity — file calibration follow-on this tick
- Any `warn` severity — file calibration follow-on within 1-2 cycles
- `info` severity — note in next gap-hunt-probe evidence; trigger calibration if pattern recurs

### Authoring new finding types

New finding types added to the script:
1. Add finding-type name to `finding_types` array (info + schema envelopes)
2. Implement the check inside the python block; append to `findings[]` with shape `{finding_type, severity, details, proposal}`
3. Update regression test to assert the new finding type appears or not under fixture conditions
4. Document the finding type in this doctrine (table in Rule 2)

## Cross-references

- `flywheel-faqj2` — this doctrine's parent meta-bead
- `flywheel-2xdi` — gap-hunt-probe substrate parent
- 7 sister calibration beads (table above)
- `bead-hypothesis-starting-point` doctrine — META-RULE 2026-05-11 sister
- `/flywheel:tick` Step 4o — read-only probes anti-pattern guardrail (sister discipline)
- `feedback_audit_before_build_when_substrate_underutilized` memory — Meadows #6 information-flow intervention

## Boundary

This doctrine is in-repo flywheel scope. The self-calibration probe lives in `.flywheel/scripts/`. Wire-in to `/flywheel:tick` is cross-repo (skill substrate `~/.claude/commands/flywheel/tick.md`) and requires paired jsm-import-ready patch artifact per `project_skillos_separated.md` discipline; filed as follow-on bead from this meta-bead.

## Outcomes shipped via this doctrine

After ratification, the 7 prior calibrations become historical evidence of the pattern this doctrine canonicalizes. Future probes inherit the discipline: every probe substrate gets a self-calibration sibling from day 1, not after 7 per-bead burns.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
