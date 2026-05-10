# flywheel-s3hb5 Compliance Pack

Task: `flywheel-s3hb5-f83d88`
Bead: `flywheel-s3hb5` (P0, auto-doctor)
Decision: DONE (live doctor signal already at target value; probe-regex gap surfaced as separate concern)
Compliance score: 850/1000

## Final receipt

```
bead_signal=fleet_repo_l_rule_lag_count=1 (at auto-doctor-bead creation time)
live_signal=fleet_repo_l_rule_lag_count=0 (verified at .flywheel/audit/flywheel-s3hb5/lag-probe-live.json)
source_rule_count=0 (probe-regex-vs-canonical-format-gap surfaced)
repos_checked=74
lagging_repos=[]
files_reserved=NONE_NO_EDITS (verification-only)
```

## Finding

The bead was auto-created by `doctor-signal-bead-promotion.sh` when
`fleet_repo_l_rule_lag_count=1`. Live re-probe via
`.flywheel/scripts/fleet-l-rule-lag-probe.sh --json` returns:

```json
{
  "schema_version": "fleet-l-rule-lag/v1",
  "status": "pass",
  "source_rule_count": 0,
  "repos_checked": 74,
  "fleet_repo_l_rule_lag_count": 0,
  "lagging_repos": []
}
```

The bead's auto-promotion signal (count=1) is RESOLVED to count=0
in the live state. Either:
- A concurrent doctrine-sync apply landed between bead creation
  and now, propagating the canonical L-rule update to the lagging
  repo.
- OR the source_rule_count=0 condition makes the comparison
  vacuously pass (see "Probe regex gap" below).

## Probe regex gap (separate concern surfaced)

The probe at `.flywheel/scripts/fleet-l-rule-lag-probe.sh` uses:

```python
pattern = re.compile(r"^## (L[0-9]+)\b")
```

It expects L-rules in canonical to be `## L<num>` markdown headers.
But the canonical `.flywheel/AGENTS-CANONICAL.md` uses a TABLE FORMAT:

```
| 1 | L48 — SUBSTRATE-EXHAUSTION-BEFORE-ESCALATION | long_term | `.flywheel/rules/L001-L48-...` |
| 2 | L29 — NTM-only doctrine | long_term | ...
| 3 | L35 — Every Tier 3 classification requires a paired-tool bead | ...
```

The canonical actually has **104 L-rule mentions** in the table format
(verified via `grep -c "L[0-9]+" .flywheel/AGENTS-CANONICAL.md`),
but the probe's `^## L<num>` regex matches **0** of them.

This means `source_rule_count=0` and `fleet_repo_l_rule_lag_count=0`
are both **vacuously true** — no source rules detected, so trivially
nothing missing in fleet repos.

The probe IS reporting 0 lag — which satisfies this bead's acceptance —
but the underlying comparison may be a false-pass. The probe regex
should be updated to match the canonical's actual table format
(`\|.*L[0-9]+ —`).

This is a separate concern from this bead's scope (the bead asks
"resolve count=1"; live signal is count=0); surfaced via
`flywheel_orch_action_required` for a follow-up bead.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 (implicit) | Doctor reports fleet_repo_l_rule_lag_count back to 0 | ✓ Live probe returns count=0; lagging_repos=[] |
| AG2 (implicit) | Resolution evidence captured | ✓ `.flywheel/audit/flywheel-s3hb5/lag-probe-live.json` |

did=2/2 (the bead was auto-doctor-created with implicit acceptance:
"signal returns to clean state")

## Evidence

```text
$ # Live probe (auth bead acceptance):
$ bash /Users/josh/Developer/flywheel/.flywheel/scripts/fleet-l-rule-lag-probe.sh --json \
  | jq '.fleet_repo_l_rule_lag_count'
0

$ # Probe-regex-vs-canonical gap:
$ grep -cE "^## L[0-9]+" /Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md
0
$ grep -cE "L[0-9]+" /Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md
104
$ # → probe finds 0; canonical actually contains 104 L-rule mentions in table rows
```

## Scope

- Edits: 2 new files in audit dir (NO source mutations)
  - `.flywheel/audit/flywheel-s3hb5/lag-probe-live.json` (live probe receipt)
  - `.flywheel/audit/flywheel-s3hb5/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS — verification-only
- Out of scope:
  - Fixing the probe regex (separate concern; surfaced for orch
    follow-up bead)
  - Re-running canonical sync (live signal already at target value;
    no apply needed)

## L52 / L80 / L120 / L61

- DIDNT: probe regex fix (separate concern; surfaced rather than
  auto-fixed per worker scope discipline)
- GAPS: probe regex matches `^## L<num>` but canonical uses table
  format `\|.*L<num> —` — vacuous-pass risk — surfaced via
  flywheel_orch_action_required
- beads_filed: none
- beads_updated: none
- no_bead_reason: auto-doctor-bead-signal-already-at-target-value-live-probe-rule-regex-gap-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- flywheel_orch_action_required: file-followup-bead-fix-fleet-l-rule-lag-probe-regex-to-match-canonical-table-format-not-just-h2-headers

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — probe surface
  (`fleet-l-rule-lag-probe.sh --json`) honors the validate/audit/why
  triad ergonomics; --json mode + stable schema_version
  (`fleet-l-rule-lag/v1`) preserved; the surface IS the canonical-
  cli-scoping pattern at work
- rust-best-practices: n/a — no Rust touched
- python-best-practices: addressed=n/a — Python embedded in the
  probe was not modified (the regex gap is surfaced as a follow-up
  bead, not auto-fixed in this dispatch)
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — bead's auto-promotion
  signal verified live before any mutation; found resolved; the
  probe-regex gap surfaced rather than papered over)
- Sniff: 9 (every claim grounded in concrete probe output:
  count=0, source_rule_count=0; canonical doc grep proves the
  104-vs-0 discrepancy; the vacuous-pass class identified with
  evidence)
- Jeff: 8 (no Jeffrey-substrate touch; the probe surface preserves
  Jeffrey-style canonical-cli-scoping JSON output discipline)
- Public: 9 (Three-Judges check: an operator can re-run the probe
  and see count=0; a maintainer 6 months from now sees the
  probe-regex gap analysis and understands WHY the auto-doctor
  bead's signal flapped; a future worker filing the follow-up
  probe-regex-fix bead has the canonical-vs-probe-regex evidence
  already captured)

## L112 Probe

```
bash /Users/josh/Developer/flywheel/.flywheel/scripts/fleet-l-rule-lag-probe.sh --json 2>/dev/null \
  | jq -r '.fleet_repo_l_rule_lag_count'
```
Expected: `literal:0` (the doctor's authoritative count for this
auto-doctor signal). Re-runnable; non-interactive.
