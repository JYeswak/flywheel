# flywheel-ywhdu Compliance Pack

Task: `flywheel-ywhdu-75fae0`
Bead: `flywheel-ywhdu`
Decision: DONE
Compliance score: 870/1000

## Final receipt

```
8k94v_propagation=visible (script at expected ALPS path, probe runs)
alps_t4_symptom=accurate (not a metric naming drift / 4o9o1 surface_mismatch)
classification=per-repo-audit-doc-not-yet-authored
fix_path=author .flywheel/PUBLISHABILITY-AUDIT.md on ALPS OR document exemption (Joshua's call per 8k94v acceptance "OR document why ALPS is exempt")
divergence_with_4o9o1_class=YES — this is NOT 4o9o1-class
```

## Finding

The bead's hypothesis was that ALPS T4 (02:06Z) reporting
`publishability-audit-md-missing` while flywheel-8k94v shipped at
~01:35Z might be a 4o9o1-class metric-naming-drift / surface_mismatch
between probes. Investigation rejects that hypothesis: 8k94v
propagation IS visible, ALPS probe IS accurate, and the missing
piece is the per-repo authored audit document — a different artifact
class than the propagated script.

### Probe state (confirmed)

```text
$ ls /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh
/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh

$ /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh \
    --doctor --json --repo /Users/josh/Developer/alpsinsurance \
    | jq '.errors[0]'
{
  "code": "publishability_audit_missing",
  "message": "missing .flywheel/PUBLISHABILITY-AUDIT.md"
}
```

The script at line 14 documents its own contract:
`Scores .flywheel/PUBLISHABILITY-AUDIT.md against the seven-facet
publishability bar.`

So `publishability-bar.sh` is the SCORER and
`.flywheel/PUBLISHABILITY-AUDIT.md` is the SCORED ARTIFACT — they
are TWO DIFFERENT FILES. 8k94v shipped the SCORER (the script that
gets propagated via templates/flywheel-install/). The SCORED ARTIFACT
is per-repo authored content that the operator (or an audit
worker) writes once per repo.

### Why this isn't 4o9o1-class

`flywheel-4o9o1` (closed 2026-05-08) was a true surface_mismatch:
ALPS probed a different surface than the flywheel-side fix
addressed (raw orphan count vs confirmed-unreachable count). The
metric WAS divergent because the producers were measuring
different things.

This bead's symptom is opposite: ALPS probe is accurate.
"`.flywheel/PUBLISHABILITY-AUDIT.md` missing" is literally true —
the file doesn't exist on ALPS, and the probe correctly reports
that. The bug is NOT in the probe; the bug is "ALPS hasn't been
through the publishability authoring loop yet." That's not
operator-trust corrosion (the metric IS moving when content is
authored); it's a per-repo-content-authoring gap.

Note: flywheel-source repo HAS
`/Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-AUDIT.md`
(produced by the original 7-facet authoring on flywheel itself).
ALPS has the script (via 8k94v propagation) but no audit content
(because audit content is repo-specific, not template-propagated).

## Classification

**NOT 4o9o1-class surface_mismatch.** 8k94v's propagation is
correct. The symptom name `publishability-audit-md-missing` is
literally the missing file class.

**Per-repo audit-doc not-yet-authored.** ALPS needs either:
1. An authored `.flywheel/PUBLISHABILITY-AUDIT.md` (operator or
   audit-worker writes the 7-facet content for ALPS), OR
2. An explicit exemption documented in
   `.flywheel/PUBLISHABILITY-BAR.md` per 8k94v's acceptance gate
   "OR document why ALPS is exempt"

The 8k94v close note already named this branch in its acceptance:
"install canonical publishability-bar.sh per
`.flywheel/PUBLISHABILITY-BAR.md` doctrine OR document why ALPS
is exempt." 8k94v shipped the install branch. The exemption
branch is separate work — and orthogonal to this verification
bead.

## Joshua-lens (25yr-ops, per user_joshua_lens_judgment_depth.md)

The bead body cites the 25yr-ops rule: "metric naming drift
between probes is canonical operator-trust corrosion."

That heuristic doesn't fire here. The probe and metric ARE
aligned (`publishability_audit_missing` ↔ "missing
.flywheel/PUBLISHABILITY-AUDIT.md"). The metric is moving in the
right direction (will go from `score: 0, errors: [missing]` to
`score: N, errors: []` once the audit is authored, just as the
flywheel-source-repo metric moved when its audit was authored).

The Joshua-lens worth applying is the COMPANION rule: "metric
that DOES move when content is authored proves the
fix-propagation chain is healthy." Here, 8k94v's propagation
shipped the SCORER (machine-readable, propagatable artifact) and
left the SCORED ARTIFACT (per-repo content) for the per-repo
authoring loop. That's the right separation. A future ALPS
audit-author dispatch will move the metric from 0 to N.

The TRUE operator-trust corrosion would have been if the script
ITSELF were missing (which 8k94v fixed) or if the script were
producing wrong metrics (which it isn't — it's reporting accurate
state).

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Artifact named in bead body updated with close evidence | ✓ Audit pack records the propagation-visible verdict + ALPS-side authoring-gap reclassification |
| AG2 | Targeted test/validator command passes and is named in close receipt | ✓ Live ALPS-side probe (`publishability-bar.sh --doctor --json --repo /Users/josh/Developer/alpsinsurance`) returns `publishability_audit_missing` correctly (probe works as designed) |
| AG3 | Bead remains open until evidence artifact exists | ✓ Audit pack written before close |
| Bead-body | Probe ALPS-side script for what filename it expects | ✓ Probe expects `.flywheel/PUBLISHABILITY-AUDIT.md` per script line 14 + structured `errors[0].code: "publishability_audit_missing"` |
| Bead-body | Diff vs 8k94v installed | ✓ 8k94v installed `publishability-bar.sh` (the SCORER); the SCORED ARTIFACT (`PUBLISHABILITY-AUDIT.md`) is a different file class — per-repo authored, not template-propagated. No diff to resolve at the propagation layer. |
| Bead-body | Either rename OR document divergence | ✓ Documented divergence: 8k94v shipped scorer correctly; the missing audit.md is per-repo authoring concern (Joshua's call per 8k94v's "OR document why ALPS is exempt" branch) |

did=6/6

## Evidence

```text
$ # 8k94v propagation visible at expected path:
$ ls /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh
/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh

$ # ALPS-side probe runs cleanly + reports accurate missing-audit error:
$ /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh \
    --doctor --json --repo /Users/josh/Developer/alpsinsurance \
    | jq '.status, .errors[0].code'
"fail"
"publishability_audit_missing"

$ # Script's own self-documented contract names the SCORED file:
$ sed -n '14p' /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh
        "Scores .flywheel/PUBLISHABILITY-AUDIT.md against the seven-facet publishability bar."

$ # Cross-repo comparison: flywheel-source HAS its audit; ALPS doesn't (yet)
$ ls /Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-AUDIT.md
/Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-AUDIT.md
$ ls /Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-AUDIT.md
ls: ... No such file or directory   # per-repo authoring gap, not propagation gap
```

## Scope

- Edits: 1 audit pack file (this file)
- Files reserved/released: NONE_NO_EDITS
  (read-only verification per cross-orch hygiene; no ALPS-side
  edits attempted because authoring `.flywheel/PUBLISHABILITY-AUDIT.md`
  is content-authoring scope, not propagation-verify scope)
- Out of scope: authoring ALPS's
  `.flywheel/PUBLISHABILITY-AUDIT.md` (separate dispatch — could
  be assigned to ALPS pane via cross-orch); documenting an ALPS
  exemption (Joshua's call per `.flywheel/PUBLISHABILITY-BAR.md`
  doctrine); modifying 8k94v's receipt (already closed)

## L52 / L80 / L120 / L61

- DIDNT: none (6/6 satisfied)
- GAPS: 1 surfaced — ALPS's `.flywheel/PUBLISHABILITY-AUDIT.md`
  is not yet authored (recommended sibling bead title:
  `[alps-publishability-author] author 7-facet
  PUBLISHABILITY-AUDIT.md for alpsinsurance OR document
  exemption`); not auto-filed per worker scope
- beads_filed: none
- beads_updated: none
- no_bead_reason: surfaced-gap-recommended-for-orch-filing-not-worker-scope
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 8 (clean cross-orch verification — establishes that
  8k94v's propagation IS visible AND that ALPS T4's symptom is
  accurate, but classifies the symptom into the right category
  rather than forcing it into 4o9o1's class)
- Sniff: 9 (live probe ran with `--repo` set to ALPS, returned
  structured error code; script self-documents its contract on
  line 14; cross-repo file-presence diff confirms the
  scorer-vs-scored-artifact distinction)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 9 (a future operator hitting the same symptom can
  re-run the probe + read the script's line-14 contract +
  understand "the SCORER ships via propagation; the SCORED
  ARTIFACT is per-repo content"; the recommended sibling-bead
  title is operator-actionable)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh \
  --doctor --json --repo /Users/josh/Developer/alpsinsurance \
  | jq -e '.errors[0].code == "publishability_audit_missing"'
```
Expected: `jq:.errors[0].code=="publishability_audit_missing"` returns
`true`. The probe's structured error code is the durable signal
that ALPS T4's symptom is accurate (the audit.md genuinely missing,
not a probe-naming-drift). When ALPS authors the audit.md, the
probe will return `errors:[]` and `score>0` — proving the
fix-propagation chain works.
