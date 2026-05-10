---
bead_id: flywheel-pfjkw
task_id: flywheel-pfjkw-65fd3d
worker_identity: MistyCliff
ts: 2026-05-10T15:24:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - dogfood-discovers-scaffolder-gaps
  - 30x-better-than-target-compression
  - production-revert-pattern-second-application
  - early-dispatch-help-trade-off
---

The pilot validated the tooling chain in **6 minutes wall-clock**
against a 3-5h estimate. The scaffolder's stubs are good enough that
the canonical-cli-scoping checker hits 13/13 on each surface with NO
TODO fill-in required. Median per-surface compression: 2 minutes.
That's ~30x better than the spec's 30-60min projection.

But the pilot also surfaced 2 small scaffolder gaps that needed
fixing in-flight. Both were patches to the SCAFFOLDER (flywheel-ws02m)
that I wrote earlier today. The first run showed 10/13; v2 patch
got it to 12/13; v3 patch got it to 13/13. Worth noting because:

1. **Dogfooding is the only honest validation**. I had run the
   scaffolder's own e2e (20/20 PASS) and dogfooded against
   callback-fix-bead-opener (13/13 on the test scaffold's 13
   canonical assertions), but neither test exercised the
   `canonical-cli-scoping` checker that the pilot's spec requires.
   That checker tests deeper substance (per-subcommand --help,
   root --help mentioning canonical flags). The scaffolder's stub
   functions didn't recognize `--help`, so `<CLI> repair --help`
   returned rc=64.

2. **The fixes were tiny**. v2: add `-h|--help` arms to two
   `scaffold_cmd_*` functions. v3: add `-h|--help` to
   `_scaffold_is_canonical_arg`. ~6 lines of code total. Both are
   the kind of polish that you only notice when running real-world
   probes.

The v3 patch trade-off is real: targets whose original `--help` had
substantive flag documentation lose that detailed help when the
canonical surface intercepts `--help`. For build-dispatch-packet's
50+ line usage, this is a regression unless the operator merges
target-specific flags into scaffold_usage's USG heredoc as part of
TODO fill-in. The doctrine should call this out — and the next-
generation scaffolder should consider calling the original `usage()`
function (if defined) before printing canonical usage, to preserve
both worlds.

The production-revert discipline is now a recurring pattern (second
application after flywheel-ws02m's callback-fix-bead-opener dogfood).
The discipline: scaffolded targets with un-filled TODOs are NOT
production-ready. The pilot's deliverable is the verdict +
measurements + scaffolder revisions, not the 3 targets in production
state. Scaffolded snapshots live in
`.flywheel/audit/flywheel-jloib.1.pilot/` for reviewer inspection.

The L5 lint violation on dispatch-and-log.sh is the canonical
"pre-existing target-side condition not introduced by tooling".
The script uses `set -uo pipefail` (no -e) intentionally because
its `PACKET_OUT="$(... 2>&1)"; PACKET_RC=$?` pattern relies on the
command substitution running to completion regardless of the
sub-command's exit code. Adding -e could break this. Filed as
PROPOSED followup; reviewer triage decides whether to (a) add -e
with audit of all rc-capture sites, or (b) document accepted L5
variance for command-substitution-rc-capture targets.

The verdict-validated outcome is significant: it unblocks
`jloib.1.1/.2/.3` (21 more dispatch surfaces), `jloib.2` (recovery
lane), `jloib.3` (agent-mail lane). At 2 minutes/surface compression,
the remaining 21 dispatch surfaces ship in ~45 minutes scaffolder
work + per-surface fill-in only where TODOs are substantive. That's
the lane-decomposition track unlocked.
