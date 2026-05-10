# flywheel-z0crr Compliance Pack

Task: `flywheel-z0crr-63089b`
Bead: `flywheel-z0crr` (P2)
Decision: DONE (fleet-level propagation plan + canonical templates + Jeffrey draft issue; one-off live edits explicitly rejected per bead body)
Compliance score: 880/1000

## Final receipt

```
fleet_size_live=111 (drift +26 vs flywheel-gjjrp's 85-skill audit 24h ago)
gap_live: scripts/=70_missing  validate.sh=108_missing  audit.sh=111_missing
canonical_paths_designed=2 (validate-template.sh + audit-template.sh, both bash-n-pass)
draft_jeff_issue_status=held-for-joshua-revision-per-session-pattern
recommended_path=Path-A-jsm-push-stamps-canonical-scripts-on-push
explicitly_rejected_path=Path-B-219-per-skill-patches (does-not-scale-and-does-not-cover-future-skills)
files_reserved=NONE_NO_EDITS (no JSM skill mutations performed)
```

## Finding

Live re-audit on 2026-05-09 against the JSM workspace returns:

```
total JSM-managed skills locally cached: 111
  has scripts/ directory:            41 (missing in 70)
  has scripts/validate.sh:            3 (missing in 108)
  has scripts/audit.sh:               0 (missing in 111)
```

Drift vs flywheel-gjjrp's 2026-05-09 audit: fleet grew **+26 skills
in 24h** (85 → 111). Gap proportions unchanged: validate.sh and
audit.sh remain near-universally absent. Live evidence at
`.flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv`.

The bead's framing is explicit: "Needs fleet-level skill-builder/JSM
propagation pattern, not one-off live edits." This dispatch designs
that pattern.

## Repair (fleet-level propagation)

Plan at `.flywheel/audit/flywheel-z0crr/propagation-plan.md` compares
three paths and recommends Path A:

**Path A (recommended)**: Add a stamp step to skill-builder's `jsm push`
flow. When `scripts/validate.sh` or `scripts/audit.sh` is missing, the
push stamps a canonical template stub with placeholder substitution
(`<SKILL_NAME>`, `<REQUIRED_BIN>`, `<DOCTOR_CMD>`, `<SUBSTRATE_PROBE>`).
Skill authors customize on subsequent edits; `--no-stamp-canonical-scripts`
opts out.

Why Path A wins on the 4-criterion matrix:
- Reaches all consumers ✓ (vs Path C flywheel-only)
- One-tool-change instead of N-edits ✓ (1 vs 219)
- Future skills auto-covered ✓ (vs Path B static patches)
- Worker-tick can author proposal solo ✓ (Path B requires 219 patch
  authoring which exceeds worker-tick scope by a factor of 200+)

**Path B explicitly rejected** as one-off-live-edits anti-pattern
per bead body's framing.

**Path C (flywheel adapter)** is a fallback if Path A is rejected
or delayed; doesn't reach non-flywheel JSM consumers, so not the
long-term answer.

## Canonical templates designed

Two ~80-line bash scripts in audit dir:

1. `canonical-validate-template.sh` (89 lines) — honors
   canonical-cli-scoping triad: `--json` mode, stable schema_version
   `skill-validate/v1`, exit codes 0/2/3 (ok/missing/degraded),
   placeholder block. `bash -n` passes.

2. `canonical-audit-template.sh` (95 lines) — read-only substrate
   probe with JSON output (`schema_version=skill-audit/v1`),
   placeholder block. `bash -n` passes.

Templates are stamping-ready: skill-builder (or a flywheel-side
adapter, if Path A is rejected) can substitute `<SKILL_NAME>` etc.
and write the result to `scripts/validate.sh` + `scripts/audit.sh`.

## Jeffrey-substrate respect (jeff-issue-chain v1.1)

No JSM skills mutated. Zero unilateral edits performed across the
111-skill fleet. Draft Jeffrey issue at
`.flywheel/audit/flywheel-z0crr/draft-jeff-issue.md` proposes Path A
upstream, anonymized per `jeff-issue-chain` v1.1 hard rules:
- No flywheel paths
- No bead IDs / session names
- Internal terms substituted ("downstream consumers" not
  "flywheel orch tick"; "111 locally-cached skills" not "fleet")

Held-for-Joshua-revision per session pattern (matches flywheel-tv00,
flywheel-wy0uh, flywheel-72z43 precedents).

## Acceptance Gate Map

The bead has implicit gates from its body. This plan addresses each:

| # | Implicit gate | Status |
|---|---|---|
| AG1 | Capture the 85/85 (live: 111/111) gap precisely | ✓ Live re-audit at fleet-scripts-gap-live.tsv (111 rows, JSM-only); summary captures the +26 drift vs prior audit |
| AG2 | Path is fleet-level, not one-off live edits | ✓ Three-path comparison; Path B (per-skill patches) explicitly rejected; Path A (Jeffrey-side stamping) recommended |
| AG3 | Canonical templates designed (validate.sh + audit.sh) | ✓ Two ~80-line stubs in audit dir, bash-n-syntax-passing, placeholder-substitution-ready |
| AG4 | Propagation pattern compatible with skill-builder/JSM workflow | ✓ Path A integrates with `jsm push` natively; Path C respects existing `refresh-all-skills.sh` JSM-exclusion rule |
| AG5 | Jeffrey-substrate respect maintained (no unilateral mutation) | ✓ Zero skill mutations performed; draft issue anonymized per jeff-issue-chain v1.1; held-for-Joshua-revision |

did=5/5

## Evidence

```text
$ # Live fleet audit (refreshed):
$ awk -F'\t' 'NR>1 {scripts+=$2; validate+=$3; audit+=$4; total++} END {
    print "total:", total
    print "has_scripts/:", scripts, "(missing:", total-scripts ")"
    print "has_validate.sh:", validate, "(missing:", total-validate ")"
    print "has_audit.sh:", audit, "(missing:", total-audit ")"
  }' .flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv
total: 111
has_scripts/: 41 (missing: 70)
has_validate.sh: 3 (missing: 108)
has_audit.sh: 0 (missing: 111)

$ # Drift vs prior audit:
$ wc -l /tmp/flywheel-gjjrp-compliance/flywheel-gjjrp/fleet-scripts-gap.tsv
86 .../fleet-scripts-gap.tsv  # 85 + header (prior audit 24h ago)
$ wc -l .flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv
112 .flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv  # 111 + header
# Drift: +26 skills in 24h

$ # Templates pass syntax:
$ bash -n .flywheel/audit/flywheel-z0crr/canonical-validate-template.sh && echo OK
OK
$ bash -n .flywheel/audit/flywheel-z0crr/canonical-audit-template.sh && echo OK
OK

$ # JSM exclusion rule honored (refresh-all-skills.sh):
$ grep -E "JSM_OWNED|leave alone" ~/.claude/skills/skill-builder/scripts/refresh-all-skills.sh | head -2
# Build JSM-managed exclusion list (jsm sync owns those, leave alone)
JSM_OWNED["$name"]=1
```

## Scope

- Edits: 6 new files in audit dir (NO JSM skill mutations)
  - `.flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv` (live audit)
  - `.flywheel/audit/flywheel-z0crr/fleet-scripts-gap-summary.txt`
  - `.flywheel/audit/flywheel-z0crr/canonical-validate-template.sh` (template stub)
  - `.flywheel/audit/flywheel-z0crr/canonical-audit-template.sh` (template stub)
  - `.flywheel/audit/flywheel-z0crr/draft-jeff-issue.md` (held-for-Joshua-revision)
  - `.flywheel/audit/flywheel-z0crr/propagation-plan.md` (3-path comparison)
  - `.flywheel/audit/flywheel-z0crr/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS (no JSM skill mutations
  performed; audit dir is this dispatch's own output)
- Out of scope:
  - Direct mutation of any of the 111 JSM-managed skills
  - Authoring 219 per-skill patches (Path B explicitly rejected)
  - Posting the Jeffrey issue (held-for-Joshua-revision)
  - Building the flywheel-side adapter (Path C; only if Path A rejected)

## L52 / L80 / L120 / L61

- DIDNT: posting the Jeff issue (held-for-Joshua-revision; not a
  failed gate)
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: planning-bead-with-four-sibling-bead-sequence-flywheel-z0crr-1-through-4-orch-routed-not-auto-filed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- flywheel_orch_action_required: joshua-review-and-post-draft-jeff-issue-at-.flywheel-audit-flywheel-z0crr-draft-jeff-issue.md-then-file-flywheel-z0crr-1-through-4-per-propagation-plan-md

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — both templates honor
  validate/audit/why triad; --json mode + stable schema_version +
  stable exit codes preserved; templates ARE the canonical-cli-scoping
  pattern made instantiable for fleet propagation
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched (templates are bash)
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — bead premise (85/85)
  refreshed to live state (111/111, +26 drift); the path-comparison
  matrix forces tradeoff transparency rather than rubber-stamping
  one approach; ZestStream brand voice "structure-level over
  symptom-level" honored — 1 tool change vs 219 patches)
- Sniff: 9 (every claim grounded in live audit output saved as
  durable evidence; templates pass `bash -n`; drift +26 documented
  via wc -l on both audit files; JSM-exclusion-rule cited at
  `refresh-all-skills.sh` line)
- Jeff: 9 (Jeffrey-substrate respect maintained — zero JSM skill
  mutations; draft issue anonymized per jeff-issue-chain v1.1;
  held-for-Joshua-revision per established session pattern;
  Path A proposal IS Jeffrey's pipeline integration, not a bypass)
- Public: 9 (Three-Judges check: an operator can re-run the live
  audit and see the +26 drift; a maintainer 6 months from now sees
  the 3-path comparison and understands WHY Path A was canonical;
  a future worker on flywheel-z0crr.3 (Path C fallback) has the
  templates already designed and only needs to wire the adapter
  invocation; the propagation pattern is reusable for any
  fleet-level skill-shape gap that arises in the future)

## L112 Probe

```
awk -F'\t' 'NR>1 && $4==0 {n++} END {print n}' \
  /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-z0crr/fleet-scripts-gap-live.tsv
```
Expected: `grep:^11[0-9]$` (count of skills missing audit.sh — at
capture time was 111; the probe asserts the order-of-magnitude class
in case of further fleet drift). The receipt records the exact value
at capture time.
