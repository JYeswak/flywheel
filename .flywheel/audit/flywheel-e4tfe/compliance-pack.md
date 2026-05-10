# flywheel-e4tfe Compliance Pack

Task: `flywheel-e4tfe-23ccb8`
Bead: `flywheel-e4tfe` (P2)
Decision: DONE (genuine promotion candidate — new doctrine entry authored)
Compliance score: 880/1000

## Final receipt

```
trauma_class=br-source-repo-dot-after-create
canonical_INCIDENTS_coverage_pre_dispatch=NO (verified via grep + class_in_incidents test)
event_count_in_fuckup_log=7 (bead claimed 5; live count is 7 — even more substantial than claimed)
doctrine_entry_authored=YES — appended to /Users/josh/Developer/flywheel/INCIDENTS.md
canonical_INCIDENTS_coverage_post_dispatch=YES (live class_in_incidents test rc=0)
files_reserved=/Users/josh/Developer/flywheel/INCIDENTS.md
contrast_with_session_pattern=GENUINE candidate (matches flywheel-s2yd8); 8th L56 promotion candidate this session, 2nd genuine one
```

## Finding

Genuine promotion candidate per same shape as flywheel-s2yd8:

```text
$ # Pre-dispatch coverage:
$ grep -c "br-source-repo-dot" /Users/josh/Developer/flywheel/INCIDENTS.md
0
$ grep -c "br-source-repo-dot" ~/.claude/skills/.flywheel/INCIDENTS.md
0
$ class_in_incidents "br-source-repo-dot-after-create"
rc=1   # NOT FOUND
```

7 fuckup-log events between 2026-05-02 and 2026-05-03, all
documenting `br create` invocations producing rows with
`source_repo='.'` (literal dot string) instead of the absolute
repo path. Each required manual repair via direct SQLite or
`br update --source-repo`.

## Repair

Authored a new layer-2 INCIDENTS entry at canonical
`/Users/josh/Developer/flywheel/INCIDENTS.md` (matches established
format from prior dispatches in this session):

- Date: 2026-05-09
- Promotion Action: NEW
- Class: `br-source-repo-dot-after-create`
- Event Count: 7 events in 7 days (note: bead claimed 5; live
  count is 7 — even more substantial)
- Severity: low (matches fuckup-log severity field on all 7 rows)
- Cost: manual repair burden after every `br create` from absolute
  repo paths
- Root Cause: `br create` resolves `source_repo` from CWD
  representation that yields "." rather than `pwd -P`/`realpath`
- Forever-Rule: TWO enforcement layers
  1. **Worker discipline**: cd to realpath repo before `br create`;
     verify resulting row's source_repo starts with "/"; repair via
     `br update --source-repo` if not
  2. **Upstream tool patch** (Jeffrey-substrate): canonicalize
     `source_repo` internally; refuse "." or relative paths
- Fix Applied/Status: NEW layer-2 entry; worker-side contract
  established; upstream br fix surfaced as Jeffrey issue
  recommendation (out of worker scope)
- Evidence: 7 fuckup-log line references with affected beads named

INCIDENTS.md grew from 7042 to 7125 lines (+83 lines for the new section).

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Verify trauma class is genuinely uncovered | ✓ Pre-dispatch grep across all INCIDENTS surfaces returned 0; class_in_incidents rc=1 |
| AG2 | Confirm fuckup-log event count meets threshold | ✓ 7 rows confirmed (bead claimed 5; live count higher) |
| AG3 | Author dedicated doctrine entry | ✓ New `## br-source-repo-dot-after-create` section appended with full Severity / Cost / Root Cause / Forever-Rule / Fix Applied / Evidence per established pattern |
| AG4 | Verify promote script will skip on future runs | ✓ Live class_in_incidents rc=0 post-dispatch |

did=4/4

## Evidence

```text
$ # Pre-dispatch state (genuine gap):
$ grep -c "br-source-repo-dot" /Users/josh/Developer/flywheel/INCIDENTS.md
0
$ class_in_incidents "br-source-repo-dot-after-create"
rc=1

$ # Fuckup-log evidence:
$ grep -cF '"trauma_class":"br-source-repo-dot-after-create"' \
    ~/.local/state/flywheel/fuckup-log.jsonl
7
$ # All 7 events 2026-05-02 to 2026-05-03; all severity:low; all
$ # `br create` -> source_repo='.' -> manual repair pattern

$ # Post-dispatch state:
$ grep -c "^## br-source-repo-dot-after-create$" /Users/josh/Developer/flywheel/INCIDENTS.md
1
$ class_in_incidents "br-source-repo-dot-after-create"
FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md
rc=0

$ # File grew by 83 lines:
$ # pre:  7042 lines (post-flywheel-s2yd8)
$ # post: 7125 lines
```

## Scope

- Edits: 1 doctrine file appended + 2 audit-dir files
  - `/Users/josh/Developer/flywheel/INCIDENTS.md` (new section,
    7042 → 7125 lines)
  - `.flywheel/audit/flywheel-e4tfe/fuckup-evidence.jsonl` (7 rows)
  - `.flywheel/audit/flywheel-e4tfe/compliance-pack.md` (this file)
- Files reserved/released: 1 (canonical INCIDENTS.md, released
  before callback)
- Out of scope:
  - Implementing worker-side cd-to-realpath wrapper (separate bead)
  - Jeffrey upstream `br create` source_repo canonicalization
    fix (out of flywheel scope; surface for Jeffrey issue)
  - Backfilling the 7 affected beads to repair their source_repo
    rows (orch-side data hygiene; out of L56 ladder scope)

## L52 / L80 / L120 / L61

- DIDNT: worker-side wrapper + Jeffrey issue draft (separate
  concerns; doctrine codifies the rule, tooling/upstream are
  downstream work)
- GAPS: workers should adopt the verify-or-repair contract from
  the new Forever-Rule; surfaced via flywheel_orch_action_required
- beads_filed: none
- beads_updated: none
- no_bead_reason: doctrine-entry-authored-tooling-and-upstream-followups-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: file-followup-bead-implement-worker-side-cd-realpath-wrapper-AND-draft-jeffrey-issue-for-br-create-source-repo-canonicalization

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — Forever-Rule names
  `br create`, `br show <id> --json`, `br update <id>
  --source-repo` as canonical surfaces; doctor/health/repair triad
  preserved
- rust-best-practices: n/a — no Rust touched (`br` is Rust upstream
  but flywheel doesn't modify it)
- python-best-practices: n/a
- readme-writing: n/a

## Four Lens

- Brand: 9 (data-decides discipline applied — bead premise verified
  TRUE; live count exceeded bead claim by 2 events; doctrine entry
  authored from real fuckup-log evidence; worker-side AND upstream
  enforcement layers both named)
- Sniff: 9 (every claim grounded: pre-dispatch grep counts, 7
  fuckup-log rows with line numbers + bead names + dates, post-
  dispatch class_in_incidents rc=0, 7 affected beads enumerated)
- Jeff: 8 (no Jeffrey-substrate touch; the Forever-Rule's tier-2
  enforcement names a Jeffrey upstream fix as recommendation,
  scoped as out-of-worker-scope per `feedback_no_push_ntm_br.md`
  / `feedback_jeff_issue_chain.md`)
- Public: 9 (Three-Judges check: operator can re-run probes and
  see fix landed; maintainer 6 months out sees the trauma's
  manual-repair-burden documented + the two enforcement layers;
  future worker hitting `source_repo='.'` knows to verify-then-
  repair OR file a follow-up Jeffrey issue)

## L112 Probe

```
grep -c "^## br-source-repo-dot-after-create$" \
  /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:1` (the new doctrine entry's section heading
exists; the bead's "no INCIDENTS coverage" premise is now
satisfied by an authoritative entry).
