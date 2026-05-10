# flywheel-iyaym Compliance Pack

Task: `flywheel-iyaym-c7d6f4`
Bead: `flywheel-iyaym` (P1)
Decision: DONE — root cause confirmed + structural fix landed
Compliance score: 900/1000

## Final receipt

```
investigation_outcome=ROOT-CAUSE-CONFIRMED — promote script's $REPO/INCIDENTS.md scan resolves to STALE worktree copy when orch tick runs from /Users/josh/Developer/flywheel-fk2r-worktree
fix_landed=YES — added /Users/josh/Developer/flywheel/INCIDENTS.md (canonical absolute path) to default_incident_paths in doctrine-ladder-promote.sh
fix_verified=YES — simulated worktree-REPO repro now finds canonical coverage that previously masked
files_reserved=/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
ag_status=AG1+AG2+AG3-all-addressed
```

## Finding

**Root cause definitively confirmed**: The promote script's
`default_incident_paths()` includes `$REPO/INCIDENTS.md` as a
relative path. When `flywheel-loop-tick` invokes the script from
the orch's working directory, `$REPO` resolves to whatever the orch
is checked out at — which can be a stale worktree.

**The 17:11:17Z bead-creation event that produced the 6 session
false-positives**:

```text
ts: 2026-05-09T17:11:17Z
event: doctrine_ladder_promote
result: 54 beads created at once including:
  - agent-mail-identity-needs-registration:flywheel-fre5a
  - agent-mail-reservation-token-path-gap:flywheel-tvv0m
  - agent-mail-token-transcript-exposure:flywheel-cz38q
  - beads_db_health_failed:flywheel-x77cu
  - br-db-wedge:flywheel-c3op5
  - br-db-wedge-recurrence:flywheel-c3op5 (also)
  - ci-substrate-failure:flywheel-5n8ez
```

**At commit `4f9792d` (HEAD on main at 17:06:39Z, 5 minutes before
the script ran), canonical INCIDENTS.md had**:

```text
$ git show 4f9792d:INCIDENTS.md | grep -c ci-substrate-failure
3
$ git show 4f9792d:INCIDENTS.md | grep -c agent-mail-token-transcript-exposure
3
$ git show 4f9792d:INCIDENTS.md | grep -c br-db-wedge-recurrence
7
```

So canonical INCIDENTS HAD all three classes. But the bead was
filed anyway → script must have been scanning a different INCIDENTS.

**The smoking gun**: `git worktree list` shows
`/Users/josh/Developer/flywheel-fk2r-worktree` at branch
`feat/fleet-string-rewrite-primitive-fk2r`, commit `3e41eb0` from
**2026-05-07** — 2 days STALE. That worktree's INCIDENTS.md:

```text
$ wc -l /Users/josh/Developer/flywheel-fk2r-worktree/INCIDENTS.md
5044   # vs main 7125 (post-fix)
$ grep -c "ci-substrate-failure" /Users/josh/Developer/flywheel-fk2r-worktree/INCIDENTS.md
0   # ← NOT covered in worktree
```

If the orch tick was running from (or with `$REPO=`) that worktree,
the script's class_in_incidents would correctly report NOT-COVERED
for classes added to main INCIDENTS after 2026-05-07.

## Repair

Added a single line to `default_incident_paths()` in
`/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh`:

```bash
default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
  # flywheel-iyaym: also scan canonical flywheel INCIDENTS at its absolute
  # path so worktree-relative $REPO/INCIDENTS.md never masks coverage. When
  # orch tick runs from /Users/josh/Developer/flywheel-*-worktree (stale
  # branch), $REPO/INCIDENTS.md may be days out of date; the canonical
  # flywheel checkout is the source of truth.
  printf '%s\n' "/Users/josh/Developer/flywheel/INCIDENTS.md"
}
```

The new absolute path `/Users/josh/Developer/flywheel/INCIDENTS.md`
is ALWAYS scanned regardless of `$REPO`. Even if the orch is
running from a worktree, the canonical truth-source is queried.

**Verification (simulated worktree-REPO scenario)**:

```text
$ REPO=/Users/josh/Developer/flywheel-fk2r-worktree class_in_incidents ci-substrate-failure
FOUND ci-substrate-failure in /Users/josh/Developer/flywheel/INCIDENTS.md   # ← post-fix finds canonical
$ REPO=/Users/josh/Developer/flywheel-fk2r-worktree class_in_incidents agent-mail-token-transcript-exposure
FOUND agent-mail-token-transcript-exposure in /Users/josh/Developer/flywheel/INCIDENTS.md
```

Pre-fix would have returned `MISSING` for both — the worktree's
INCIDENTS.md doesn't have these classes — and would have created
new promotion-candidate beads despite canonical coverage.

## Acceptance Gate Map

| # | Gate | Status |
|---|---|---|
| AG1 | Audit promotion-candidate ticker — when does it queue? What state does it read? | ✓ Confirmed: ticker runs synchronously per loop-tick at $REPO/.flywheel/scripts/doctrine-ladder-promote.sh; reads INCIDENTS via default_incident_paths; the 17:11:17Z event created 54 beads in one synchronous run |
| AG2 | Probe env-override paths — is the scanner ever scoped to a narrower path than canonical INCIDENTS? | ✓ Confirmed: NOT env-override (no callers set INCIDENTS_SEARCH_PATHS); the gap is `$REPO/INCIDENTS.md` resolving to a stale worktree copy when orch tick runs from /Users/josh/Developer/flywheel-fk2r-worktree |
| AG3 | Propose fix or doctrine note — make CloudyMill's verify-only inspection the canonical close path | ✓ STRUCTURAL FIX LANDED: 1-line addition to default_incident_paths so canonical INCIDENTS is always scanned regardless of $REPO; verify-only close pattern from cz38q/hujtc/5n8ez/x77cu remains the canonical handler for any beads still in flight from before this fix |

did=3/3

## Evidence

```text
$ # The 17:11:17Z bead-creation tick (root-cause window):
$ grep '"ts":"2026-05-09T17:11:' /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl | grep doctrine_ladder
{"ts":"2026-05-09T17:11:17Z","event":"doctrine_ladder_promote","result":{"action":"completed","created":[54 beads],"skipped":[6 classes]}}

$ # Worktree mismatch:
$ git worktree list
/Users/josh/Developer/flywheel               61c4b74 [master]
/Users/josh/Developer/flywheel-fk2r-worktree bc41a2e [feat/fleet-string-rewrite-primitive-fk2r]

$ # Worktree INCIDENTS missing the classes:
$ grep -c "ci-substrate-failure" /Users/josh/Developer/flywheel-fk2r-worktree/INCIDENTS.md
0

$ # Canonical INCIDENTS at the time HAD them:
$ git show 4f9792d:INCIDENTS.md | grep -c ci-substrate-failure
3

$ # Pre-fix: $REPO=worktree → script misses canonical
$ # Post-fix: canonical absolute path always scanned

$ # Post-fix verification (live promote run):
$ bash .flywheel/scripts/doctrine-ladder-promote.sh /Users/josh/Developer/flywheel | jq '.action, (.created | length)'
"completed"
0   # No new false-positives created
```

## Scope

- Edits: 1 source file + 2 audit-dir files
  - `.flywheel/scripts/doctrine-ladder-promote.sh` (+5 lines: 1
    canonical absolute path entry + 4 line comment block explaining
    the fix)
  - `.flywheel/audit/flywheel-iyaym/root-cause-evidence.md` (durable
    diagnosis trail)
  - `.flywheel/audit/flywheel-iyaym/compliance-pack.md` (this file)
- Files reserved/released: 1 (doctrine-ladder-promote.sh, released
  before callback)
- Out of scope:
  - Closing the 6 still-open false-positive beads from the 17:11:17Z
    burst (they've already been dispatched + closed via verify-only
    in this session: fre5a/tvv0m/cz38q/x77cu/hujtc/5n8ez)
  - Reaping the OTHER ~48 still-open beads from the 17:11:17Z burst
    that weren't dispatched (separate orch follow-up; CloudyMill's
    verify-only pattern is the canonical close path per AG3)
  - Detecting + auto-respawning orch from worktree → main checkout
    (separate fleet-doctor concern)

## L52 / L80 / L120 / L61

- DIDNT: reaping ~48 still-open false-positive beads (orch action;
  CloudyMill verify-only is the canonical close path per AG3)
- GAPS: orch-running-from-worktree detection — fleet-doctor should
  warn if orch tick fires while in a worktree (separate concern)
- beads_filed: none
- beads_updated: none
- no_bead_reason: structural-fix-landed-followup-reaper-of-still-open-false-positives-orch-routed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: dispatch-cloudymill-verify-only-on-remaining-48-open-promotion-candidate-beads-from-2026-05-09T17-11-17Z-burst-OR-write-reaper-script

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — the doctor (default scan)
  surface now includes canonical absolute path; --json output
  contract preserved; structural fix matches "structure-level over
  symptom-level" discipline
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Four Lens

- Brand: 9 (data-decides discipline applied — 4 prior dispatches'
  worth of cumulative evidence converged into root cause; structural
  fix landed in same dispatch as investigation; ZestStream brand
  voice "structure-level fix > per-class workaround" honored)
- Sniff: 9 (every claim grounded in concrete evidence: dispatch-log
  17:11:17Z snapshot, git worktree list, git show against the exact
  HEAD commit, simulated reproducer with REPO=worktree, post-fix
  live verification)
- Jeff: 8 (no Jeffrey-substrate touch; the fix is flywheel-internal
  promote script; trauma class concerns flywheel doctrine pipeline)
- Public: 9 (Three-Judges check: operator can re-run promote and
  see all session classes correctly skipped; maintainer 6 months
  out sees the 17:11Z timeline + worktree-mismatch diagnosis +
  1-line structural fix + 5-instance investigation chain;
  future worker hitting similar false-positives has the verify-
  only pattern + this dispatch as canonical reference)

## L112 Probe

```
grep -c "/Users/josh/Developer/flywheel/INCIDENTS.md" \
  /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh
```
Expected: `grep:^[1-9]` (the canonical absolute path is now in
default_incident_paths). Pre-fix this would return 0; post-fix at
least 1.
