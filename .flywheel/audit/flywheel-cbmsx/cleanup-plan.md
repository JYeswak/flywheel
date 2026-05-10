# skill-autoresearch focused cleanup plan

Bead: `flywheel-cbmsx` (P3, [canonical-cli-scoping] resolve
skill-autoresearch major-rework residuals)
Plan author: worker CloudyMill on flywheel:0.2 (codex-pane), 2026-05-09
Plan-status: APPLY-READY (concrete sed/edit motions documented;
no execution in this dispatch — bead asks to "plan" the cleanup)

## TL;DR — bead premise is stale

The bead body claims:

> Residual skill-autoresearch grade remains MAJOR REWORK:
> composite_score=5.29, weakest_gate=operational_tooling,
> weakest_score=0.0

A live re-run of `skill-grader.py --skill-path ~/.claude/skills/skill-autoresearch --json`
on 2026-05-09 returns:

```text
composite_score=9.0
skill_type=domain
gate scores:
  structure                 9.0/10.0
  trigger_quality           8.0/10.0
  progressive_disclosure    8.0/10.0
  actionability             8.0/10.0
  anti_patterns            10.0/10.0
  operational_tooling      10.0/10.0  ← bead claimed 0.0
  sources                  10.0/10.0
```

The MAJOR-REWORK status is RESOLVED. The bead was filed
2026-05-08 against a state that since shifted (likely a sibling
bead between flywheel-yt0w close and now lifted operational_tooling
from 0.0 → 10.0 by adding `scripts/skill-grader.py` at 1398 lines,
plus `scripts/probe.sh`, plus the `examples/autoresearch-config.yaml`).

Live evidence captured at
`.flywheel/audit/flywheel-cbmsx/live-grader-output.json`.

## Residual remediations (live, post-resolution)

The grader returns 4 minor remediations. Each is graded for
APPLY/SKIP/DEFER discipline below.

### 1. Structure — trim SKILL.md from 288 → 200-250 lines (APPLY-READY, NOT EXECUTED)

`SKILL.md` is 38-88 lines over the structure-gate band. The
biggest section is "The Autoresearch Loop" at 113 lines — a
prime candidate for progressive disclosure (move detail to
`references/autoresearch-loop.md`, leave a 30-50 line summary
in SKILL.md).

Section sizes today:

| Lines | Section | Trim approach |
|---|---|---|
| 21  | Before Starting | KEEP |
| 39  | THE EXACT PROMPT | KEEP (load-bearing prompt) |
| 113 | The Autoresearch Loop | **Trim 60 lines** → move depth into `references/autoresearch-loop.md`, keep loop-stages summary table |
| 17  | Anti-Patterns | KEEP (gate 5 evidence) |
| 36  | Running the Grader | Trim 10 lines → table-row examples can move to `references/grader-output.md` |
| 13  | Tooling | KEEP |
| 8   | Related Skills | KEEP |
| 6   | Sources | KEEP (gate 7 evidence — sources.md is in references/) |
| 25  | Telemetry-Driven Maturity (Jeff doctrine) | KEEP (Jeff delta — preserve per bead body) |

Target trim: ~70 lines (288 → 218). Lands SKILL.md at the
200-250 sweet spot AND preserves the Jeff append-only audit
lineage delta (telemetry-driven maturity section), per bead
body's "preserves canonical CLI trigger intent and existing
Jeff deltas" constraint.

Concrete edit motion (apply-time):

```bash
# 1. Create the new reference target
mkdir -p ~/.claude/skills/skill-autoresearch/references
# 2. Cut lines describing each loop stage's micro-detail into:
#    references/autoresearch-loop.md (preserve as full doc)
# 3. Keep in SKILL.md a 30-50 line summary table:
#    | Stage | Inputs | Outputs | Reference |
#    |---|---|---|---|
#    | Generate Skill | bare-call dispatch packet | initial SKILL.md draft | references/autoresearch-loop.md#generate |
#    | etc. | ... | ... | ... |
```

This dispatch DOES NOT execute the trim — the cleanup is
intentionally PLANNED, not APPLIED, per the bead's "plan a
focused skillos/flywheel cleanup" framing.

### 2. Trigger quality — "remove 2 second-person phrases" (SKIP — false positive)

Grader returns:

> Remove 2 second-person phrases (you should/need/can)

Investigation finds BOTH matches are META-CONTENT explaining
what to AVOID in tables:

```text
SKILL.md:110: | 2 | Trigger Quality | 15+ trigger phrases in description,
                 third-person voice, no second-person ("you should") | 1.0 |
SKILL.md:194: | Ignoring second-person voice | Trigger Quality gate
                 penalizes "you should" phrasing | Rewrite all instructions ... |
```

Both lines are TABLE CELLS DESCRIBING the rule. They literally
NEED the string `"you should"` to communicate what the gate
penalizes. Rewriting them to remove the example would harm
SKILL.md clarity for the grader-rule explanation.

**Decision: SKIP this remediation.** This is a grader
false-positive class — pattern-matches the literal substring
without context-aware exclusion of meta-content (table cells
that describe the rule itself).

**Sibling-bead opportunity (flywheel_orch_action_required):**
file a bead to teach `skill-grader.py:second_person_patterns`
to ignore lines inside markdown table cells whose surrounding
text labels them as ANTI-PATTERN ENTRIES — i.e., suppress
matches in rows whose first cell starts with phrases like
"Ignoring second-person voice" or "no second-person". Match
condition is structural (in-table + meta-context cue), not just
substring exclusion.

### 3. Progressive disclosure — "move detail to references/ to reduce 288 → 200-250" (APPLY same as #1)

Identical to remediation #1 — the 70-line trim into
`references/autoresearch-loop.md` IS the progressive-disclosure
fix. One edit, two gates fixed.

### 4. Actionability — "Add implementation checklist with `- [ ]` items" (APPLY-READY, NOT EXECUTED)

SKILL.md has tables and a Tooling section, but no
`- [ ] checkbox` style implementation checklist. Add a
"Pre-flight Checklist" section before "The Autoresearch Loop"
with ~5 items:

```markdown
## Pre-flight checklist

- [ ] Skill-path resolved (target skill exists under `~/.claude/skills/<name>/`)
- [ ] Baseline grade captured (`skill-grader.py --skill-path <path> --json`)
- [ ] Backup or jsm-managed status confirmed (jsm list | grep <name>)
- [ ] Working directory clean (no in-flight edits to `<path>/SKILL.md`)
- [ ] Iteration budget set (max 2 attempts per gate, per anti-pattern)
```

This addresses the actionability remediation AND adds operator-
grade discipline (the budget item is direct lift from the
"Over-iterating on one gate" anti-pattern).

## Apply-time runbook

When the cleanup is ready to execute (next dispatch or batch):

```bash
# 0. Confirm the skill is NOT JSM-managed (free-direct-edit class)
jsm list 2>&1 | grep -c "skill-autoresearch"  # → 0 means safe to edit

# 1. Reserve SKILL.md via L107 before edit
.flywheel/scripts/shared-surface-reservation-check.sh \
  --reserve ~/.claude/skills/skill-autoresearch/SKILL.md \
  --pane=2 --session flywheel \
  --task-id=<future-bead-id> --json

# 2. Capture baseline grade (commit-pinned receipt)
python3 ~/.claude/skills/skill-autoresearch/scripts/skill-grader.py \
  --skill-path ~/.claude/skills/skill-autoresearch --json \
  > .flywheel/audit/<future-bead>/baseline.json

# 3. Cut autoresearch-loop micro-detail into references/autoresearch-loop.md
#    (manual section cut, not scripted; preserve markdown anchors)

# 4. Add pre-flight checklist section above "The Autoresearch Loop"

# 5. Re-grade, ensure composite >= baseline, no gate regresses
python3 ~/.claude/skills/skill-autoresearch/scripts/skill-grader.py \
  --skill-path ~/.claude/skills/skill-autoresearch --json \
  > .flywheel/audit/<future-bead>/post-cleanup.json

# 6. Diff both grades
python3 -c "
import json
b = json.load(open('.flywheel/audit/<future-bead>/baseline.json'))
p = json.load(open('.flywheel/audit/<future-bead>/post-cleanup.json'))
for bg, pg in zip(b['gate_scores'], p['gate_scores']):
    delta = pg['score'] - bg['score']
    sign = '+' if delta >= 0 else ''
    print(f\"{bg['gate_name']:<25} {bg['score']:.1f} -> {pg['score']:.1f} ({sign}{delta:.1f})\")
print(f\"composite {b['composite_score']:.2f} -> {p['composite_score']:.2f}\")
"

# 7. Release reservation
.flywheel/scripts/shared-surface-reservation-check.sh \
  --release ~/.claude/skills/skill-autoresearch/SKILL.md \
  --pane=2 --session flywheel \
  --task-id=<future-bead-id> --json

# 8. Skill self-validation re-run
~/.claude/skills/skill-autoresearch/scripts/probe.sh
```

## Constraint compliance

Per bead body: "preserves canonical CLI trigger intent and existing Jeff deltas":

- **Canonical CLI trigger intent**: this plan does NOT touch
  `canonical-cli-scoping` skill at all. The remediations are
  all in `skill-autoresearch` — a sibling skill that grades
  others. No CLI trigger patterns under
  `~/.claude/skills/canonical-cli-scoping/SKILL.md` will be
  modified by the apply-time work.

- **Existing Jeff deltas**: the "Telemetry-Driven Maturity (Jeff
  doctrine)" section (25 lines, ~lines 264-288 of SKILL.md) is
  EXPLICITLY KEEP in the trim plan. The append-only audit
  lineage hooks land in references/, not by removal. The
  trim target is "The Autoresearch Loop" section, which
  predates the Jeff delta adoption and is the bloat source.

## Acceptance Gate Map

The bead body lists 5 implicit acceptance criteria. This plan
addresses all 5:

| # | Implicit gate (from bead body) | Plan addresses? | Where |
|---|---|---|---|
| 1 | Plan addresses MAJOR REWORK / composite_score=5.29 | ✓ | TL;DR — documents the resolution; live composite is now 9.0 |
| 2 | Plan addresses weakest_gate=operational_tooling (was 0.0) | ✓ | TL;DR — already lifted to 10.0/10 by sibling work; no further action needed |
| 3 | Plan preserves canonical CLI trigger intent | ✓ | "Constraint compliance" — `canonical-cli-scoping` skill is untouched by this plan |
| 4 | Plan preserves existing Jeff deltas | ✓ | "Constraint compliance" + Section sizes table — Jeff doctrine section is KEEP |
| 5 | Plan addresses SKILL.md length, examples/sources, Python operational tooling | ✓ | Remediation #1 (length 288→218), examples/sources already at 10/10, operational tooling already at 10/10 |

did=5/5

## Sibling-bead surface (orch action required)

One concrete sibling bead surfaces from this work:

- **Title**: `[skill-grader] suppress second_person_pattern matches in anti-pattern table cells (false positive class)`
- **Why**: SKILL.md line 110 (gate-rubric table) and line 194
  (anti-patterns table) both contain the literal string
  `"you should"` as META-CONTENT explaining what the gate
  penalizes. The grader penalizes the skill for explaining the
  rule. Surfaces in any rubric-self-describing skill.
- **Acceptance**: skill-grader.py's
  `_score_trigger_quality` excludes matches inside markdown
  table rows whose surrounding cells reference "Trigger Quality
  gate" or "second-person" by name.
- **Filed in this dispatch?**: NO — surfaced via
  `flywheel_orch_action_required=file-skill-grader-anti-pattern-suppression-bead`
  per worker scope discipline.

## Four-Lens Self-Grade

- **Brand: 9** — plan reflects a finding (bead premise is
  stale), not just executes a stale instruction; runbook is
  apply-ready with concrete sed/diff commands; ZestStream
  brand voice (data-decides over meat-puppet) honored.
- **Sniff: 9** — claims grounded in live grader JSON output
  (saved at `.flywheel/audit/flywheel-cbmsx/live-grader-output.json`);
  every remediation has a concrete file:line evidence; the
  false-positive #2 has line-number proof both matches are
  meta-content.
- **Jeff: 8** — Jeff delta (Telemetry-Driven Maturity) is
  explicitly KEEP in the trim plan; the apply-time runbook
  uses Jeff-style append-only audit pattern (baseline +
  post-cleanup JSON saved alongside diff); no Jeff-repo touch.
- **Public: 9** — Three-Judges check: a future operator
  re-running the grader can replay TL;DR; a maintainer 6
  months from now can read the plan, run the apply-time
  runbook, and ship the cleanup; a downstream grader
  improvement (the sibling bead recommendation) lets the
  next worker hit it directly. The plan's framework
  (residual-grade-via-live-rerun before applying stale-bead
  remediations) generalizes to any "this skill needs cleanup"
  bead class — a public-grade pattern.
