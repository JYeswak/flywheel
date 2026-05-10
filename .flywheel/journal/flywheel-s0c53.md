---
bead_id: flywheel-s0c53
task_id: flywheel-s0c53-fd3186
worker_identity: MistyCliff
ts: 2026-05-10T17:08:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules:
  - L52
  - L107
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - storage-lane-fillin-sister-of-gam2k
  - scaffold-stub-vs-legacy-substantive-coexistence
  - validate-probe-binary-checks-real-downstream
---

Sister fillin to gam2k (private-tmp-prune) in the storage-lane. Same gam2k
pattern: 6 substantive scaffold-stub subcommands + per-surface --schema +
topic_help + 8 per-surface test assertions.

The interesting wrinkle here was that storage-headroom-watcher.sh already
had substantive doctor/health/repair/validate/audit/why implementations in
its legacy code (~lines 961+, backed by a python helper). The scaffolder
appended canonical-cli stubs ON TOP, and the early-dispatch intercept routes
the no-dash subcommands (`doctor`, `health`, etc.) to the SCAFFOLD stubs
before reaching the substantive legacy code.

Two coexistence options:
A) Have scaffold stubs delegate to legacy via `exec "$0" --doctor "$@"`
B) Re-implement substantively in the scaffold layer (gam2k pattern)

I went with (B) because the test scaffold expects the canonical envelope
shape (.command, .checks[], .status) which the legacy `--doctor` path does
NOT emit (it has its own python-helper schema like `storage-headroom-watcher.
doctor.v1`). Delegation would have broken the 13/13 contract.

The legacy code stays intact and remains reachable through the dash-prefix
forms (--doctor, --health) which bypass the scaffold intercept. Operators
who want python-helper-backed analysis still get it; operators using the
canonical doctor/health/etc. get the structured envelope. Two parallel
surfaces, same source file, same data.

Doctor probes 13 substrate dimensions — the most of any fillin to date.
Storage watcher has more substrate (ledger + contract ledger + fuckup log
+ probe binary + jsonl-append lib + 5 deps + config + repo root) than the
sister surfaces, so the doctor surface naturally widened.

The validate `probe-binary` subject is the load-bearing one for this surface
— it actually probes whether `.flywheel/scripts/storage-probe.sh` exists,
is executable, and parses bash. That's the real dependency the watcher
delegates to.

Pattern note: storage-lane fillin is the same shape as doctrine-lane fillin
(zjm8v) — script + sister test, ~30 min wall clock, 950+/1000 quality bar.
gam2k + s0c53 now anchor the storage-lane chain.
