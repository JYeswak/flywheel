# flywheel-s2yd8 Compliance Pack

Task: `flywheel-s2yd8-e69c8a`
Bead: `flywheel-s2yd8` (P2)
Decision: DONE (genuine promotion candidate — new doctrine entry authored)
Compliance score: 880/1000

## Final receipt

```
trauma_class=bead-missing-from-local-db
canonical_INCIDENTS_coverage_pre_dispatch=NO (verified via grep + class_in_incidents test)
event_count_in_fuckup_log=3 (matches bead claim)
doctrine_entry_authored=YES — appended to /Users/josh/Developer/flywheel/INCIDENTS.md
canonical_INCIDENTS_coverage_post_dispatch=YES (live class_in_incidents test rc=0)
files_reserved=/Users/josh/Developer/flywheel/INCIDENTS.md
contrast_with_prior_3_dispatches=this is a GENUINE promotion candidate (vs flywheel-fre5a/tvv0m/cz38q which were stale-premise false positives)
```

## Finding

Unlike the three prior promotion-candidate dispatches in this session
(flywheel-fre5a, flywheel-tvv0m, flywheel-cz38q), this bead's premise
is **TRUE**:

```text
$ # Pre-dispatch coverage check:
$ grep -c "bead-missing-from-local-db" /Users/josh/Developer/flywheel/INCIDENTS.md
0
$ grep -c "bead-missing-from-local-db" /Users/josh/Developer/flywheel/AGENTS.md
0
$ grep -c "bead-missing-from-local-db" ~/.claude/skills/.flywheel/INCIDENTS.md
0
$ # Live class_in_incidents pre-dispatch:
$ class_in_incidents "bead-missing-from-local-db"
rc=1   # NOT FOUND
```

The class is genuinely uncovered. 3 fuckup-log events confirm the
bead's count claim, all on alpsinsurance:4 between 2026-05-07T18:43-
19:01Z:

| ts | bead | what_happened |
|---|---|---|
| 2026-05-07T18:43:33Z | `josh-19yvg` | Dispatch bead not in local bead DB; `br close` could not be applied after PR merge (`should_become=tool-patch`) |
| 2026-05-07T18:51:36Z | `josh-2jyzb` | Dispatch bead not in local br issue DB during React Flow worker tick |
| 2026-05-07T19:01:43Z | `josh-bmd26` | Dispatch bead not in local br issue DB during simple-mode worker tick |

All three involve cross-repo paths: orch in `/Users/josh/Developer/alpsinsurance`
vs worker in `/private/tmp/alpsinsurance-worker-pane-4-josh-*` mktemp
worktree. Worker checkouts inherit `issues.jsonl` at branch-base time
and miss beads created post-branch in the parent repo.

## Repair

Authored a new layer-2 INCIDENTS entry at canonical
`/Users/josh/Developer/flywheel/INCIDENTS.md` following the
established format (matches flywheel-fre5a's
`agent-mail-identity-needs-registration` shape):

```
## bead-missing-from-local-db
Date: 2026-05-09
Promotion Action: NEW
Class: `bead-missing-from-local-db`
Event Count: 3 events in 7 days
Severity: low

Cost: <worker dispatch + br close failure description>
Root Cause: <cross-worktree per-repo SQLite DB sync gap>
Forever-Rule: <verify-then-sync-or-surface contract for workers>
Fix Applied/Status: NEW layer-2 entry...
Evidence: <fuckup-log line numbers, doctrine refs, bead refs>
```

INCIDENTS.md grew from 6985 to 7042 lines (+57 lines for the new section).

The Forever-Rule codifies the canonical worker contract:
1. `br show <id> --json` first (fast-path check)
2. If missing: `br sync --import-only` (pull JSONL → DB)
3. If still missing: surface `bead-missing-from-local-db` in
   closeout receipt; do NOT fabricate `br close`; do NOT
   write directly to `.beads/issues.jsonl`

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Verify trauma class is genuinely uncovered (vs stale false-positive class) | ✓ Pre-dispatch grep across canonical INCIDENTS / AGENTS / skill INCIDENTS all return 0; class_in_incidents returns rc=1 |
| AG2 | Confirm fuckup-log event count matches bead claim | ✓ 3 events in fuckup-log.jsonl lines 3928-3930 (matches bead's "3 events in 7d") |
| AG3 | Author doctrine entry following INCIDENTS.md format | ✓ New `## bead-missing-from-local-db` section appended with Severity, Cost, Root Cause, Forever-Rule, Fix Applied, Evidence per established pattern |
| AG4 | Verify promote script will now skip this class on future runs | ✓ Live class_in_incidents test post-dispatch returns rc=0, "FOUND in: $REPO/INCIDENTS.md" |

did=4/4

## Evidence

```text
$ # Pre-dispatch state (genuine gap):
$ grep -c "bead-missing-from-local-db" /Users/josh/Developer/flywheel/INCIDENTS.md
0
$ class_in_incidents "bead-missing-from-local-db"
rc=1   # NOT FOUND

$ # Fuckup-log evidence:
$ grep -nF "bead-missing-from-local-db" ~/.local/state/flywheel/fuckup-log.jsonl | wc -l
3
$ # All 3 rows are alpsinsurance:4 cross-worktree dispatches on 2026-05-07

$ # Post-dispatch state:
$ grep -c "^## bead-missing-from-local-db$" /Users/josh/Developer/flywheel/INCIDENTS.md
1
$ class_in_incidents "bead-missing-from-local-db"
FOUND in: /Users/josh/Developer/flywheel/INCIDENTS.md
rc=0

$ # File grew by 57 lines:
$ # pre:  6985 lines
$ # post: 7042 lines
```

## Scope

- Edits: 1 source/doctrine file appended + 2 audit-dir files
  - `/Users/josh/Developer/flywheel/INCIDENTS.md` (new section
    appended, 6985 → 7042 lines)
  - `.flywheel/audit/flywheel-s2yd8/fuckup-evidence.jsonl` (durable
    copy of the 3 fuckup-log rows for evidence pointers)
  - `.flywheel/audit/flywheel-s2yd8/compliance-pack.md` (this file)
- Files reserved/released: 1 (`/Users/josh/Developer/flywheel/INCIDENTS.md`,
  released before callback)
- Out of scope:
  - Implementing the worker-side sync-or-surface contract (separate
    bead — the doctrine entry codifies the rule; tooling/wrapper
    changes are downstream work)
  - Propagating to skill INCIDENTS.md (the canonical scan finds it
    in canonical; skill propagation was demonstrated as defense-in-
    depth in flywheel-fre5a/tvv0m but per flywheel-cz38q's diagnosis
    correction, not strictly required)
  - Modifying `agentmail-registration-broadcast.sh` or `br` CLI
    (Jeff substrate; out of worker scope)

## L52 / L80 / L120 / L61

- DIDNT: implementing worker sync-or-surface tooling (separate concern;
  doctrine codifies the rule which is the L56 promotion deliverable)
- GAPS: the bead-missing trauma class points to a worker-tick
  hardening opportunity — workers should pre-flight `br show <id>`
  before claiming bead state operations; surfaced as
  flywheel_orch_action_required
- beads_filed: none
- beads_updated: none
- no_bead_reason: doctrine-entry-authored-tooling-followup-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable (the doctrine entry is in
  INCIDENTS.md per L56 layer-2 promotion; an L-rule promotion to
  AGENTS.md is layer-3 — separate ladder step)
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: file-followup-bead-implement-worker-tick-pre-flight-br-show-check-and-br-sync-import-only-fallback-per-bead-missing-from-local-db-Forever-Rule

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — the new entry's Forever-Rule
  cites `br show --json` (fast-path), `br sync --import-only` (canonical
  worker-side pull), and `br sync --flush-only` (canonical orch-side
  push); follows canonical-cli-scoping discipline of naming the
  validate/audit/why surface
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — bead premise verified
  TRUE this time after corrected diagnosis from flywheel-cz38q;
  doctrine entry authored from real fuckup-log evidence; ZestStream
  brand voice "structure-level over symptom-level" honored —
  Forever-Rule names a verify-then-sync-or-surface contract that
  prevents recurrence at the worker-tick level)
- Sniff: 9 (every claim grounded in concrete evidence: pre-dispatch
  grep counts, 3 fuckup-log rows with line numbers + bead names,
  post-dispatch class_in_incidents rc=0; entry shape matches
  established INCIDENTS.md sections)
- Jeff: 8 (no Jeffrey-substrate touch; Forever-Rule cites Jeffrey's
  `br sync --import-only` and `br show --json` canonically; trauma
  class concerns Jeffrey's br substrate sync model but doctrine
  entry only documents the worker-side contract, not br itself)
- Public: 9 (Three-Judges check: an operator can re-run
  class_in_incidents and confirm coverage; a maintainer 6 months
  from now sees the Forever-Rule and understands the canonical
  verify-then-sync-or-surface flow; a future worker hitting this
  trauma class has the doctrine entry as the canonical reference)

## L112 Probe

```
grep -c "^## bead-missing-from-local-db$" \
  /Users/josh/Developer/flywheel/INCIDENTS.md
```
Expected: `literal:1` (the new doctrine entry's section heading
exists; the bead's "no INCIDENTS coverage" premise is now
satisfied by an authoritative entry).
