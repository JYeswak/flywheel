# flywheel-iyaym Root Cause Evidence

## Bead-creation tick that fired the false-positives

ts: 2026-05-09T17:11:17Z
result.action: completed
created: 54 promotion-candidate beads at once

Beads filed include the 6 false-positives investigated this session:
  - flywheel-fre5a (agent-mail-identity-needs-registration)
  - flywheel-tvv0m (agent-mail-reservation-token-path-gap)
  - flywheel-cz38q (agent-mail-token-transcript-exposure)
  - flywheel-x77cu (beads_db_health_failed)
  - flywheel-hujtc (br-db-wedge-recurrence)
  - flywheel-5n8ez (ci-substrate-failure)

## Worktree mismatch

git worktree list:
/Users/josh/Developer/flywheel               61c4b74 [master]
/Users/josh/Developer/flywheel-fk2r-worktree bc41a2e [feat/fleet-string-rewrite-primitive-fk2r]

Worktree INCIDENTS.md state at promote-time (commit 3e41eb0, 2026-05-07):
  - 5044 lines (vs main: 7125 lines as of post-fix)
  - 0 mentions of ci-substrate-failure
  - 0 mentions of agent-mail-token-transcript-exposure

## Reproduction proof

At commit 4f9792d (HEAD on main at 17:11Z), main INCIDENTS.md had:
  - 3 mentions of ci-substrate-failure
  - 3 mentions of agent-mail-token-transcript-exposure
  - 7 mentions of br-db-wedge-recurrence

But the orch tick was running from worktree (or  resolved to worktree),
so the script's class_in_incidents queried only the stale worktree INCIDENTS
and reported NOT-COVERED, creating beads that were already canonically covered.
