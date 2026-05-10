---
schema_version: journey-entry/v1
bead_id: flywheel-3ycjw
task_id: flywheel-3ycjw-5bc961
worker_identity: CloudyMill
ts: 2026-05-10T20:53:36Z
mission_fitness: adjacent
commit_sha: 2445420
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - skillos-diagnosed-cross-orch-fix
  - probe-layer-vs-top-level-aggregation
  - timeout-default-bump-with-error-class-distinction
  - sleeper-fixture-deterministic-test-pattern
---

# flywheel-3ycjw — journey entry

Cross-orch fix shipped exactly as skillos diagnosed. Two layers
addressed together because they're the same bug viewed differently:

1. **The 1s default was simply too tight** under realistic concurrent
   load. Direct probe takes 0.27s; on a quiet machine it never trips,
   but doctor's full run fires 30+ probes in parallel and a tail
   distribution can blow past 1s. 5s gives ~18x headroom over the
   direct-call measurement.

2. **The error envelope was conflating two failure modes**. Pre-fix,
   any probe failure (timeout OR garbage output) emitted
   `identity_registry_doctor_invalid_json` regardless of root cause.
   That hid the timeout-specific issue from automated remediation —
   you couldn't grep escalations for "concurrent-load timeouts" vs
   "probe is broken." Now `probe_rc=124` routes to
   `identity_registry_doctor_timeout` with both `probe_exit_code`
   AND `probe_timeout_seconds` in the envelope, so callers can
   classify automatically.

Most interesting moment: the **sleeper-fixture deterministic-test
pattern**. To test the timeout branch, I needed a probe that reliably
exceeds the timeout. Real flywheel-loop is fast (0.27s); waiting for
a tail-latency event would make tests flaky. Solution: `mktemp` a
shell script that just `sleep 5`s, point
`FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE` at it, set
`FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=1`. Now the timeout
path fires DETERMINISTICALLY in ~1s. Same pattern for the
invalid-JSON path: a fixture that prints garbage + exits 1.

Second moment: **probe-layer vs top-level aggregation**. After the
fix, my function returns status=pass + drift=0 reliably (verified
10/10 parallel). But the FULL doctor's top-level
`identity_registry_drift` field still shows 1. Sister bead e5f2f's
closure had the EXACT same pattern: probe layer is clean; top-level
surface fails for unrelated reasons; "each its own bead." The bead's
AC is at the probe layer, not the top-level — so 3ycjw closes its
AC even though the top-level surface is still red. The discipline
here: scope the bead, ship the fix, file follow-ups for downstream
aggregation issues if they're load-bearing.

Sister-bead pattern proven again: 5m9gp + e4ulf + nbgp6 + ukbej +
yy9qi formed a 5-bead arc this morning; e5f2f + 3ycjw form a
2-bead arc here. Each bead is scoped to one fix layer. Composing
them gives the full system behavior.
