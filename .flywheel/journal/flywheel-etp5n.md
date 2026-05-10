---
schema_version: journey-entry/v1
bead_id: flywheel-etp5n
task_id: flywheel-etp5n-74b7a7
worker_identity: MagentaPond
ts: 2026-05-10T15:00:00Z
mission_fitness: infrastructure
commit_sha: 05bc5fa
linked_l_rules:
  - L107
  - L70
  - L52
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - canonical-cli-lint
  - eight-rule-static-analyzer
  - mid-tick-calibration
---

# flywheel-etp5n — journey entry

Shipped canonical-cli-lint.sh as a static analyzer covering 8 violation
classes: L1 chained-local-set-u, L2 enumerator-missing-return-zero,
L3 brace-default-ambiguity, L4 short-circuit-in-helper, L5 missing-
strict-mode, L6 missing-magic-comment, L7 apply-without-idempotency-
key, L8 mutate-without-backup. The 4 bash gotchas come from pilot
(daily-report-enabled-repos.sh) bug-hunt; the 4 canonical-CLI gates
come from the canonical-cli-scoping skill's acceptance criteria. Wired
as pre-commit hook + 18-assertion regression test. Baseline output
(--scan-all on 337 .flywheel/scripts files) shows 259 violations for
downstream bead 2.x wave-2 work to track P0 progress.
Mid-tick calibration was load-bearing: initial L2 detector over-fired
on pilot functions ending in [[ ]] intentionally (cmd_run, cmd_health,
cmd_validate_config). Re-read pilot-lessons.md and tightened L2 to
match the actual bug shape — enumerator functions ending in bare
'done' without explicit return — and skip the pipe-suffix case where
rc is determined by the right-most command. Pilot now lints clean as
spec AG5 requires. Bash regex backreference gotcha (the lint script
was itself going to ship a regex with \1 backref) caught by initial
test failure; rewrote with BASH_REMATCH capture + secondary check.
