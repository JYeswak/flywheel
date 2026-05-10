---
schema_version: journey-entry/v1
bead_id: flywheel-gl7om
task_id: flywheel-gl7om-9f1a49
worker_identity: CloudyMill
ts: 2026-05-10T17:49:13Z
mission_fitness: adjacent
commit_sha: fab94c6
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - mission-lock-scaffold-validator-fillin
  - q92io-mission-lane-wave-1-final
  - sigpipe-pipefail-discovery
---

# flywheel-gl7om — journey entry

Final fillin in the q92io mission-lane wave-1 (cqhzt + 5wuhe + this).
Closes the lane end-to-end, all three mission scaffolders now
substantive.

Most interesting moment: SIGPIPE/pipefail discovery. The
`scaffold_emit_topic_help` body for "repair" had 5 separate printf
calls (one per scope line) for prose readability. Test 12 (`help
repair | grep -q 'topic:'`) failed under `set -uo pipefail` because
grep -q exits on first match, closing the pipe; the 2nd-5th printf
calls then trip SIGPIPE; pipefail makes the whole pipeline rc non-
zero; the test's `if ... then` falls through to else. The fix is
trivial (collapse to one printf per topic) but the lesson is
load-bearing: **every multi-printf helper that might be piped through
`grep -q` is a latent SIGPIPE failure under pipefail**. The 4 sister
fillins in flight (cqhzt, 5wuhe, prior 39vhm) all share this risk —
the test scaffolds use `grep -q 'topic:'` so any multi-printf
topic_help is a ticking bomb. Filing this as fleet-wide pattern
worth surfacing.

Second interesting moment: nested-probe recursion guard. The
`validate mission-lock-scaffold` subject re-runs cmd_run's mission
validator out-of-band to get a fresh verdict. Without a guard, every
nested probe would itself append a row to the audit log, then if
called from health/audit/validate, infinite recursion or noise rows.
Solved with `env _SCAFFOLD_VALIDATE_NESTED=1 cmd_run …` plus a guard
in the cli_audit_append wiring. The guard is opt-in (no flag, just
env); cmd_run from the operator still appends as expected.

Third: cli_audit_append wiring proved the read/write loop. Before
this fillin, doctor/health/audit/why had nothing to read — the
audit log existed only in scaffold conventions. Wiring the append
into cmd_run gave the surfaces real data to bind to. Now `health`
shows total_rows=1, `audit --tail 3` returns 1 row, `validate
audit-row` validates 1 real row, `why <ts>` finds the row by ts.
The substrate is closed-loop.

Mission-lane wave-1: complete. Wave-2 surfaces next (q92io decomp
should have ~5-6 more if pattern holds).
