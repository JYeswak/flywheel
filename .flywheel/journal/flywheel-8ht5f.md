---
bead_id: flywheel-8ht5f
task_id: flywheel-8ht5f-250c8f
worker_identity: MistyCliff
ts: 2026-05-10T05:12:02Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills: []
narrative_tags:
  - donella-leverage-point-4-self-organization
  - extend-not-rewrite
  - carve-out-priority-over-activity-signals
  - joshua-gate-before-first-launchctl-load
---

The bead's AG1 said "Author the script" — but the script already
existed (May 4, 344 lines, 16/16 tests passing). This is the
canonical "extend, don't rewrite" decision: the existing classifier
covers commit/callback/assignee signals exhaustively; what was
missing was the label-based carve-out tier the bead body explicitly
named.

The carve-out check happens FIRST in the new classify() function,
before any activity-signal check. Reasoning: labels carry intent,
activity-signal checks carry evidence. A bead labeled `joshua-gated`
has *intentional* lack of activity — closing it would be wrong even
if the activity-signal classifier would have caught it as ACTIVE
on assignee or recent commit. The label says "this is supposed to
be sitting." Honor it first.

The empirical observation from the inaugural dry-run: the bead's
"64 May-4 stale beads" prediction is off-by-cohort. Today is
2026-05-10; the May-4 cohort is 6 days old (threshold is 7). The
classifier finds 2 candidates from May 1 — beads 9+ days old with
zero signals. The May-4 cohort crosses tomorrow. So the inaugural
report is honest: 2 candidates today, more after tomorrow's
threshold crossing.

The other empirical observation: of 66 in_progress beads, 62 are
classified `ACTIVE` (commit/callback/assignee). That's the existing
classifier doing its job — most "stale-looking" beads are actively
being worked. The reaper isn't going to scythe through 64 beads on
the next Sunday run; it's going to surgically close the 2-3 that
truly went silent. That's the right behavior — Donella leverage
point #4 isn't about volume reduction, it's about removing
*invisible* drag.

The Joshua-gate before first `launchctl load` is the load-bearing
discipline. The plist is committed (so the substrate is in place);
loading it is the irrevocable step that makes the reaper run
unsupervised. Per the bead body's directive: "Joshua review of
inaugural-run candidates list BEFORE first --apply (Joshua-gate
the first execution; subsequent runs auto)." The inaugural JSON at
`.flywheel/audit/flywheel-8ht5f/inaugural-candidates.json` is the
review artifact. Once Joshua sees it and approves, `launchctl load`
is the trivial follow-up — but the gate must hold.

The 4 carve-out labels share a property: each names a *class of
intentional async wait*. `upstream-tracker` (waiting on Jeffrey),
`cross-orch-active` (waiting on a peer orch), `joshua-gated`
(waiting on Joshua), `defer-gated` (waiting on a deadline). The
worker tagging the bead is asserting "this should sit." That
distinguishes them cleanly from "in_progress and forgotten."

The classify-test precedence trap (jq `and`/`|` precedence) bit me
a third time today (after 4s3oy and ys7em). Same fix each time:
bind via `as $h` and test on `$h`. Worth folding into a workshop
note next time it surfaces — three sightings is a pattern.
