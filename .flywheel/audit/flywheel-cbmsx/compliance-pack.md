# flywheel-cbmsx Compliance Pack

Task: `flywheel-cbmsx-cd9f0d`
Bead: `flywheel-cbmsx`
Decision: DONE (planning artifact shipped; cleanup planned not applied per bead framing)
Compliance score: 870/1000

## Final receipt

```
plan_artifact=.flywheel/audit/flywheel-cbmsx/cleanup-plan.md
live_grader_evidence=.flywheel/audit/flywheel-cbmsx/live-grader-output.json
bead_premise_state=stale (composite 5.29 claimed; live composite 9.0)
remediations_addressed=4 (1 apply-ready trim, 1 false-positive skip, 1 dup-of-#1, 1 apply-ready checklist add)
sibling_bead_recommended=skill-grader-second-person-false-positive-suppression
canonical_cli_scoping_touch=NONE (constraint preserved)
jeff_delta_touch=NONE (telemetry-driven-maturity section KEEP)
```

## Finding

The bead body cites a stale composite score. Live grader run on
2026-05-09 captured at
`.flywheel/audit/flywheel-cbmsx/live-grader-output.json` returns:

```text
composite_score=9.0
operational_tooling=10.0/10  ← bead claimed weakest=0.0
all 7 gates score >= 8.0
```

A sibling bead between flywheel-yt0w close (2026-05-08) and now
lifted operational_tooling from 0.0 → 10.0 by adding
`scripts/skill-grader.py` (1398 lines), `scripts/probe.sh`,
and `examples/autoresearch-config.yaml`. The MAJOR-REWORK status
no longer applies.

Four residual remediations remain. The plan classifies each:

| # | Remediation | Class | Plan response |
|---|---|---|---|
| 1 | Trim SKILL.md 288→200-250 | apply-ready | Section-by-section trim plan, ~70 lines from "The Autoresearch Loop" → references/ |
| 2 | Remove 2 second-person phrases | grader-false-positive | SKIP — both matches are table-cell META-CONTENT explaining what to avoid |
| 3 | Move detail to references/ | dup-of-#1 | One trim addresses both gates |
| 4 | Add `- [ ]` implementation checklist | apply-ready | Pre-flight checklist section spec'd |

The plan is APPLY-READY (concrete edits documented) but
intentionally NOT executed in this dispatch — the bead body
says "plan a focused skillos/flywheel cleanup", emphasis on
PLAN. Execution is a follow-up dispatch.

## JSM discipline (pre-flight gate)

Verified before any potential mutation:

```bash
$ jsm list 2>&1 | grep -c "skill-autoresearch"
0
$ jsm list 2>&1 | grep -c "canonical-cli-scoping"
0
```

Neither skill is JSM-managed. Direct mutation under
`~/.claude/skills/<skill>/` would be allowed if the bead asked
for execution. This dispatch did NOT mutate either skill —
only audit-dir artifacts written.

## Constraint compliance (per bead body)

The bead body requires the cleanup plan to "preserve canonical
CLI trigger intent and existing Jeff deltas":

- **Canonical CLI trigger intent**: PRESERVED. Plan does not
  touch `~/.claude/skills/canonical-cli-scoping/` at all.
  Remediations are scoped to `~/.claude/skills/skill-autoresearch/`.

- **Existing Jeff deltas**: PRESERVED. The
  "Telemetry-Driven Maturity (Jeff doctrine)" section (25
  lines, ~lines 264-288 of SKILL.md) is explicitly KEEP in
  the trim plan. The trim target is "The Autoresearch Loop"
  section (113 lines, predates Jeff delta), not the Jeff
  delta itself.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Plan addresses MAJOR REWORK status | ✓ Documented as resolved by sibling work between bead-filing and now (live composite 9.0) |
| AG2 | Plan addresses weakest_gate=operational_tooling | ✓ Documented as already at 10.0/10 — no further action needed |
| AG3 | Plan preserves canonical CLI trigger intent | ✓ canonical-cli-scoping skill untouched by plan |
| AG4 | Plan preserves Jeff deltas | ✓ Telemetry-Driven Maturity section explicitly KEEP |
| AG5 | Plan addresses SKILL.md length, examples/sources, Python tooling | ✓ Trim 288→218 spec'd; examples/sources/tooling already at 10/10 |

did=5/5

## Evidence

```text
$ # Bead-claim vs live state:
$ python3 -c "
import json
d = json.load(open('.flywheel/audit/flywheel-cbmsx/live-grader-output.json'))
print('composite:', d['composite_score'])
for g in d['gate_scores']:
    print(f\"  {g['gate_name']:<25} {g['score']}/10\")
"
composite: 9.0
  structure                 9.0/10
  trigger_quality           8.0/10
  progressive_disclosure    8.0/10
  actionability             8.0/10
  anti_patterns             10.0/10
  operational_tooling       10.0/10
  sources                   10.0/10

$ # Second-person false-positive proof:
$ grep -nE "you should" ~/.claude/skills/skill-autoresearch/SKILL.md
110:| 2 | Trigger Quality | 15+ trigger phrases in description, third-person voice, no second-person ("you should") | 1.0 |
194:| Ignoring second-person voice | Trigger Quality gate penalizes "you should" phrasing | Rewrite all instructions in third-person imperative |

$ # JSM-not-managed proof:
$ jsm list 2>&1 | grep -c "skill-autoresearch"
0

$ # Plan artifact written:
$ wc -l .flywheel/audit/flywheel-cbmsx/cleanup-plan.md
193 .flywheel/audit/flywheel-cbmsx/cleanup-plan.md
```

## Scope

- Edits: 3 new files in audit dir (no skill mutation)
  - `.flywheel/audit/flywheel-cbmsx/cleanup-plan.md` (193 lines)
  - `.flywheel/audit/flywheel-cbmsx/live-grader-output.json`
    (live grader snapshot)
  - `.flywheel/audit/flywheel-cbmsx/compliance-pack.md` (this)
- Files reserved/released: NONE_NO_EDITS (no mutation of any
  skill source)
- Out of scope: applying the trim (next dispatch); modifying
  `skill-grader.py` to suppress the false-positive (sibling
  bead recommendation, not auto-filed); refactoring
  `canonical-cli-scoping` (constraint preservation, untouched)

## L52 / L80 / L120 / L61

- DIDNT: applying the cleanup (plan-only per bead body framing;
  not a failed gate)
- GAPS: skill-grader false-positive class (recommended as sibling
  bead via flywheel_orch_action_required, not auto-filed per
  worker scope discipline)
- beads_filed: none
- beads_updated: none
- no_bead_reason: planning-bead-with-sibling-bead-orch-routed-not-auto-filed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- flywheel_orch_action_required: file-sibling-bead-skill-grader-second-person-false-positive-suppression

## Skill Auto-Routes

- canonical-cli-scoping: addressed=n/a (no CLI surface
  authored; the bead asks about a skill OF a skill, not a CLI)
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — `skill-grader.py` not modified;
  plan documents apply-time work but no Python edits in this
  dispatch
- readme-writing: n/a — no README touched (the plan IS a
  planning doc, not a README; SKILL.md re-shaping is the
  apply-time work)

## Four Lens

- Brand: 9 (data-decides discipline applied — bead premise
  found stale via live re-grade, not blindly executed; plan
  reflects current truth not bead-text claim; ZestStream
  brand voice of "AI proposes, Joshua disposes" honored)
- Sniff: 9 (every claim grounded in
  `.flywheel/audit/flywheel-cbmsx/live-grader-output.json`;
  false-positive #2 has line-number proof both matches are
  meta-content; constraint compliance has explicit-section
  evidence)
- Jeff: 8 (Telemetry-Driven Maturity section preserved;
  apply-time runbook uses Jeff-style baseline+post-cleanup
  JSON pattern; no Jeff-repo touch)
- Public: 9 (the residual-grade-via-live-rerun pattern
  generalizes to any stale-bead-cleanup class; Three-Judges
  check passes — operator can replay TL;DR, maintainer can
  run runbook, future worker can hit the sibling bead)

## L112 Probe

```
python3 ~/.claude/skills/skill-autoresearch/scripts/skill-grader.py \
  --skill-path ~/.claude/skills/skill-autoresearch --json \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['composite_score'])"
```
Expected: `literal:9.0` (live composite proves the bead's
MAJOR-REWORK premise is stale; plan addresses residuals
not the bead-claimed crisis).
