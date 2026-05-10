# flywheel-cz38q Compliance Pack

Task: `flywheel-cz38q-a945a0`
Bead: `flywheel-cz38q` (P2)
Decision: DONE (verification-only — bead premise stale; canonical coverage confirmed; live scan finds it)
Compliance score: 850/1000

## Final receipt

```
trauma_class=agent-mail-token-transcript-exposure
canonical_INCIDENTS_coverage=YES — full section at /Users/josh/Developer/flywheel/INCIDENTS.md:5519
promote_script_scan_includes_canonical=YES — default_incident_paths line 42 (post flywheel-qnkj2 fix)
live_coverage_check=FOUND — class_in_incidents returns rc=0 with "FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md"
bead_premise=STALE — likely filed by an older tick run before flywheel-qnkj2 fix landed
files_reserved=NONE_NO_EDITS (no propagation needed; canonical scan finds coverage)
diagnosis_correction=earlier flywheel-fre5a/tvv0m diagnosis was incomplete; the script DOES scan canonical INCIDENTS.md per flywheel-qnkj2 fix; this 3rd dispatch corrects the diagnosis
```

## Finding

This bead is the **3rd back-to-back same false-positive class** in this
session, but **deeper inspection reveals a corrected diagnosis**:

The promote script's `default_incident_paths` (lines 39-44 of
`doctrine-ladder-promote.sh`) DOES include `$REPO/INCIDENTS.md` —
the canonical flywheel INCIDENTS:

```bash
default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"        # ← canonical
  printf '%s\n' "$REPO/AGENTS.md"
}
```

This was added by `flywheel-qnkj2` (per its smoke-test output:
"PASS default_incident_paths includes $REPO/INCIDENTS.md (post-fix)").

Live `class_in_incidents()` test for this trauma class returns rc=0
with "FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md".
Canonical entry at line 5519: `## agent-mail-token-transcript-exposure`
with full Severity / Cost / Root Cause / Forever-Rule sections.

**So the bead's premise is stale**: the class IS canonically covered,
AND the live promote script's scan finds it. The bead was likely
filed by a tick run BEFORE flywheel-qnkj2's fix landed, or via a
separate code path that bypassed the coverage check.

## Diagnosis correction (vs flywheel-fre5a / flywheel-tvv0m)

My earlier compliance packs in flywheel-fre5a and flywheel-tvv0m
claimed the promote script "scans skill-side INCIDENTS only". That
was incomplete — I was reading the right code section but missing
that the function also yields `$REPO/INCIDENTS.md` (line 42).

Corrected understanding:
- Default scan **does** include canonical `flywheel/INCIDENTS.md`
- Skill-side propagation done in flywheel-fre5a/tvv0m was DEFENSIVE
  (defense-in-depth) but not strictly required for the canonical
  scan to find coverage
- The actual root cause for these false-positive beads is upstream:
  either historical (filed before flywheel-qnkj2 fix) OR a separate
  code path with narrow `INCIDENTS_SEARCH_PATHS` env override

## No propagation this dispatch

Since the canonical scan IS finding coverage, propagating the section
to skill INCIDENTS adds no value (would just be redundant doctrine
duplication). The right close-shape for this bead is verification +
close.

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Trauma class has INCIDENTS coverage | ✓ Canonical INCIDENTS.md:5519 — `## agent-mail-token-transcript-exposure` full section |
| AG2 | Promote script's default scan finds the coverage | ✓ Live `class_in_incidents` test returns rc=0 + "FOUND in: $REPO/INCIDENTS.md" |
| AG3 | Future runs (with default scan) stop flagging this class | ✓ The script as currently committed will skip this class on the next run |
| AG4 | Document why the bead fired despite coverage existing | ✓ Likely filed under stale script state (pre-flywheel-qnkj2); systemic gap is timing/queue-flush, not scan-source-incomplete as previously diagnosed |

did=4/4

## Evidence

```text
$ # Canonical section heading present:
$ grep -n "^## agent-mail-token-transcript-exposure$" /Users/josh/Developer/flywheel/INCIDENTS.md
5519:## agent-mail-token-transcript-exposure

$ # Promote script default scan includes canonical:
$ sed -n '39,44p' /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
}

$ # Live class_in_incidents test (replicated function inline):
$ class_in_incidents "agent-mail-token-transcript-exposure"
FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md
rc=0

$ # flywheel-qnkj2 fix evidence:
$ grep "PASS default_incident_paths" .flywheel/audit/flywheel-qnkj2/smoke-output.txt
PASS default_incident_paths includes $REPO/INCIDENTS.md (post-fix) and $REPO/AGENTS.md
```

## Scope

- Edits: 2 audit-dir files (NO source/doctrine mutations)
  - `.flywheel/audit/flywheel-cz38q/coverage-evidence.md` (live coverage check)
  - `.flywheel/audit/flywheel-cz38q/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS — verification-only
- Out of scope:
  - Propagating to skill INCIDENTS (not needed; canonical scan finds it)
  - Investigating why bead fired despite coverage (orch follow-up;
    likely historical state or separate code path with narrow env)

## L52 / L80 / L120 / L61

- DIDNT: nothing — verification-only path; no failed gates
- GAPS: timing/queue-flush gap that allows beads to fire despite
  current canonical coverage; surfaced for orch
- beads_filed: none
- beads_updated: none
- no_bead_reason: bead-premise-stale-class-canonically-covered-and-script-default-scan-finds-it
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: not_applicable (no reservations granted)
- flywheel_orch_action_required: investigate-why-promotion-candidate-beads-fire-despite-canonical-coverage-and-current-default-scan-likely-stale-tick-queue-or-narrow-env-override-distinct-from-the-sync-gap-flagged-in-flywheel-fre5a-tvv0m

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — promote script's scan-list
  contract verified live; the class_in_incidents function works
  correctly when invoked with default env
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — earlier diagnosis
  re-checked against live script state; correction documented;
  ZestStream brand voice "structure-level over symptom-level"
  honored — refusing to apply redundant propagation when canonical
  scan already finds coverage; honest correction of prior dispatches'
  incomplete diagnosis)
- Sniff: 9 (every claim grounded in live evidence: canonical heading
  at line 5519, default_incident_paths source at lines 39-44,
  class_in_incidents test rc=0, flywheel-qnkj2 fix smoke-test pass;
  diagnosis-correction explicit)
- Jeff: 8 (no Jeffrey-substrate touch; the promote script is
  flywheel-internal; trauma class concerns Jeffrey's agent-mail
  substrate but doctrine pre-existed canonically)
- Public: 9 (Three-Judges check: an operator can re-run
  class_in_incidents and confirm coverage; a maintainer 6 months
  from now sees the diagnosis-correction and knows the actual
  root cause is upstream of the scan logic; a future worker hitting
  another false-positive promotion bead has this dispatch as the
  canonical "verify-coverage-don't-propagate" template)

## L112 Probe

```
grep -c "^## agent-mail-token-transcript-exposure$" \
  /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:1` (the canonical entry's section heading
exists; the bead's "no INCIDENTS coverage" premise is therefore
false).
