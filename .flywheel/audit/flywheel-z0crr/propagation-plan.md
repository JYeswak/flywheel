# flywheel-z0crr — fleet-level scripts/{validate,audit}.sh propagation plan

Bead: `flywheel-z0crr` (P2, [skill-builder] propagate scripts validate/audit pattern across JSM-managed skill fleet)
Worker: CloudyMill on flywheel:0.2 (codex-pane), 2026-05-09
Source: flywheel-gjjrp 2026-05-09 fleet audit + live re-audit today

## Live gap (refreshed 2026-05-09)

```
total JSM-managed skills (locally cached): 111
  has scripts/ directory:            41 (missing in 70)
  has scripts/validate.sh:            3 (missing in 108)
  has scripts/audit.sh:               0 (missing in 111)
```

Drift vs flywheel-gjjrp's prior 85-skill audit: fleet grew by **+26 skills in
24h** (85 → 111). Gap proportions unchanged: validate.sh and audit.sh
remain near-universally absent.

Live evidence: `.flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv`
+ `fleet-scripts-gap-summary.txt`.

## Constraint: this CANNOT be one-off live edits

Per `feedback_no_push_ntm_br.md` + `feedback_jeff_issue_chain.md`:
JSM-managed skills are owned by Jeffrey's source pipeline. Workers
file issues, not patches, on Jeffrey's repos. Per memory
`feedback_jeff_issue_requires_full_workaround_research_first.md`:
NEVER propose a Jeff issue without first researching workarounds.

The bead's own framing is explicit: "Needs fleet-level
skill-builder/JSM propagation pattern, not one-off live edits."

Per `~/.claude/skills/skill-builder/scripts/refresh-all-skills.sh`,
the existing skill-refresh substrate ALREADY excludes JSM-managed
skills — `JSM sync owns those, leave alone`. Direct fleet mutation
is doctrinally barred AND practically prevented.

## Three propagation paths (compared)

### Path A: skill-builder stamps templates on `jsm push` (RECOMMENDED)

A single change to `skill-builder` (in Jeffrey's repo): on `jsm push`,
if `scripts/validate.sh` or `scripts/audit.sh` is missing, generate
a stub from canonical templates with placeholder substitution
(`<SKILL_NAME>`, `<REQUIRED_BIN>`, `<DOCTOR_CMD>`, `<SUBSTRATE_PROBE>`).
Skill authors customize on subsequent edits; `--no-stamp-canonical-scripts`
opts out.

**Cost**: 1 PR upstream (skill-builder).
**Coverage**: ALL future + ALL existing skills on next `jsm push`.
**Risk**: low — stubs are inert until customized; opt-out exists.
**Apply blast radius**: Jeffrey-controlled rollout.

### Path B: per-skill jsm-push-ready patches

Generate 219 unified-diff patches (108 for validate.sh + 111 for
audit.sh), one per (skill, missing-script) pair. Apply via
`jsm push` per skill.

**Cost**: 219 patches authored, reviewed, applied.
**Coverage**: only the 111 currently-cached skills. Future skills
must be remembered.
**Risk**: high — review burden, drift between patches if templates
evolve mid-rollout.
**Apply blast radius**: Jeffrey + worker + 219 transactions.

### Path C: flywheel-side adapter (workaround, not fix)

Build a flywheel-side `flywheel-skill-audit-adapter.sh` that wraps
each JSM skill and synthesizes validate/audit output if the skill
doesn't ship its own. Fleet consumers (orch tick, rollup dashboards)
read through the adapter.

**Cost**: 1 adapter + ~111 substrate-probe rules embedded in adapter.
**Coverage**: only flywheel-side consumers; doesn't help
non-flywheel JSM consumers.
**Risk**: medium — adapter becomes a single point of substrate-
knowledge truth that drifts from skills as they evolve.
**Apply blast radius**: flywheel-only.

### Decision matrix

| Criterion | Path A (jsm push stamp) | Path B (219 patches) | Path C (flywheel adapter) |
|---|---|---|---|
| Reaches all consumers | ✓ | ✓ | ✗ |
| One-tool-change instead of N-edits | ✓ (1) | ✗ (219) | ✓ (1) |
| Future skills auto-covered | ✓ | ✗ | ✗ |
| Jeffrey-coordinated | required | required | not required |
| Worker-tick can author solo | propose only | NO (219 patches) | YES |

**Path A is canonical.** Path C is a flywheel-side fallback if Path
A is rejected or delayed; should not be the long-term answer.

## Canonical templates (designed in this dispatch)

Two ~80-line bash scripts under audit dir for Jeffrey-side stamping
or flywheel-side adapter use:

- `.flywheel/audit/flywheel-z0crr/canonical-validate-template.sh` —
  validate.sh template. Honors canonical-cli-scoping triad: --json
  mode, stable schema_version (`skill-validate/v1`), exit codes
  0/2/3. Placeholder substitution: `<SKILL_NAME>`, `<REQUIRED_BIN>`,
  `<DOCTOR_CMD>`.

- `.flywheel/audit/flywheel-z0crr/canonical-audit-template.sh` —
  audit.sh template. Read-only substrate probe with JSON output
  (`schema_version=skill-audit/v1`). Placeholder: `<SKILL_NAME>`,
  `<SUBSTRATE_PROBE>`.

Both pass `bash -n` syntax checks (verified).

## Recommended sibling-bead sequence

When the orch is ready to act on this plan:

```
flywheel-z0crr.1  →  Post draft Jeff issue at draft-jeff-issue.md (held-for-Joshua-revision)
flywheel-z0crr.2  →  If Path A accepted upstream: track skill-builder PR + reinstall
flywheel-z0crr.3  →  If Path A rejected/delayed: implement Path C flywheel-side adapter
                     (NOT one-off patches — Path B is explicitly out of scope)
flywheel-z0crr.4  →  Stamp 5 highest-leverage skills with custom validate.sh
                     bodies (e.g., cass, beads-br, skill-builder, ntm, dcg) as
                     POST-PATH-A demonstration, AFTER skill-builder ships
                     stamping
```

Path B (219 patches) is explicitly excluded from the recommended
sequence — it doesn't scale and doesn't cover future skills.

## Worker-tick scope decision

This dispatch's worker-tick scope ENDS at producing:
1. Live gap audit (refreshed; +26 drift documented)
2. Three-path comparison
3. Canonical validate.sh + audit.sh templates (apply-ready stubs)
4. Draft Jeffrey issue (held-for-Joshua-revision per session pattern)
5. Recommended sibling-bead sequence

**Out of scope** (per bead body's "fleet-level pattern, not one-off"
constraint):
- Direct mutation of any of the 111 JSM-managed skills.
- Authoring 219 per-skill patches.
- Posting the Jeffrey issue (held for Joshua revision).
- Building the flywheel-side adapter (Path C; only if Path A rejected).

**flywheel_orch_action_required**: Joshua-review of draft Jeff issue;
upon approval, post to Dicklesworthstone/skill-builder (or wherever
JSM source lives). Then file flywheel-z0crr.1 through .4 per the
sibling-bead sequence as the upstream rollout progresses.

## Acceptance Gate Map

The bead has implicit acceptance gates from its body. This plan addresses each:

| # | Implicit gate | Status |
|---|---|---|
| AG1 | Audit captures the 85/85 (live: 111/111) gap precisely | ✓ Live re-audit at fleet-scripts-gap-live.tsv (111 skills); summary at fleet-scripts-gap-summary.txt; +26 drift vs prior audit documented |
| AG2 | Path is fleet-level, not one-off live edits | ✓ Three-path comparison documents why Path B (one-off patches) is rejected; Path A (Jeffrey-side stamping) recommended as canonical |
| AG3 | Canonical templates designed (validate.sh + audit.sh) | ✓ Two ~80-line stubs in audit dir, bash-n-syntax-passing, placeholder-substitution-ready |
| AG4 | Propagation pattern compatible with skill-builder/JSM workflow | ✓ Path A integrates with `jsm push`; Path C respects `refresh-all-skills.sh` JSM-exclusion rule; Path B explicitly rejected |
| AG5 | Jeffrey-substrate respect maintained (no unilateral mutation) | ✓ Zero skill mutations performed; draft issue anonymized per jeff-issue-chain v1.1; held-for-Joshua-revision per session pattern |

did=5/5
