---
schema_version: journey-entry/v1
bead_id: flywheel-vc29u
task_id: flywheel-vc29u-95004f
worker_identity: MagentaPond
ts: 2026-05-10T17:10:00Z
mission_fitness: infrastructure
commit_sha: 5a76e20
linked_l_rules:
  - L107
  - L70
  - L52
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - doctrine-lane-fillin
  - pipefail-set-plus-e-pattern
---

# flywheel-vc29u — journey entry

Third sister fill-in today (after vc3zs + gam2k). Same 18-TODO
substantive replacement pattern applied to doctrine-ladder-promote.sh
which analyzes fuckup-log.jsonl over a lookback window and creates
promotion-candidate beads for fuckup classes that recur AND lack
INCIDENTS coverage. The why command became the most substantive of
the three so far — 3-tier provenance: fuckup-log occurrence count
within PERIOD_DAYS + br open-bead check + INCIDENTS coverage with
matched_files; emits a promotion_recommended boolean (≥3 occurrences
AND not in INCIDENTS AND no existing bead).

Two debugging cycles during fill-in:
1. why command exited rc=5 with no output — pipefail tripped on jq's
   not-found rc inside the diagnostic block. Fix: wrap with set +e/-e.
2. doctor incidents check failed (status=fail) because original search
   was scoped to .flywheel/ but the canonical INCIDENTS.md lives at
   repo root. Expanded find to repo + maxdepth 4.

Two new skill-discovery classes shipped today across these three:
- vc3zs: substantive-stub-fillin-with-live-signal-surfacing
- gam2k: substantive-stub-fillin-with-source-grep-fallback
- vc29u (this): substantive-stub-fillin-with-pipefail-set-plus-e-block

The pattern is becoming canonical: each fill-in surface has its own
edge cases, and accumulating "fillin-with-X-pattern" sub-classes
accretes the operational knowledge for downstream workers.

13/13 canonical-CLI tests PASS. Lint clean. 0 TODOs. ~25 min wall
clock — matches gam2k pace; the second-time-doing-it leverage holds.
