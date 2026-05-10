---
schema_version: journey-entry/v1
bead_id: flywheel-gam2k
task_id: flywheel-gam2k-9f3d52
worker_identity: MagentaPond
ts: 2026-05-10T16:50:00Z
mission_fitness: infrastructure
commit_sha: 5a17a26
linked_l_rules:
  - L107
  - L70
  - L52
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - substantive-stub-fillin
  - storage-lane-fillin
  - source-grep-fallback-pattern
---

# flywheel-gam2k — journey entry

Sister sub-bead to vc3zs (shipped 950/1000 ~30 min ago); same
substantive-fill-in pattern applied to private-tmp-prune.sh. All 18
canonical-cli-scaffold TODO markers replaced with surface-specific
implementations: doctor probes 6 substrate dimensions (target dir,
ntm, lsof, ledger, min-age, allowlist function), health tails the
ledger jsonl with freshness escalation, repair has 2 real scopes
(stale-tmp candidate finder + ledger-rotate at 10MB threshold),
validate has 3 subjects (row schema, path allowlist gate, config
env), audit tails ledger, why does 3-tier lookup (ledger → filesystem
→ allowlist).

One nuance discovered: the early-dispatch intercept that runs
`scaffold_main` BEFORE the rest of the script's parse-time function
definitions means `declare -F is_allowlisted` fails at doctor-time
even though the function exists in the file. Fix: source-file grep
rather than runtime declare. Filed as
`substantive-stub-fillin-with-source-grep-fallback-class` —
extension of vc3zs's live-signal-surfacing class.

13/13 canonical-cli tests PASS. Lint clean. 0 TODOs. ~25 min wall
clock — template-established workflow now compresses to ~25 min/surface
vs initial ~30 min.

Two sub-beads from the wgitr family closed today (vc3zs + this);
6 remain for parallel worker dispatch. The disposition shape
(BLOCKED-with-decomposition → per-surface ~30-min sub-beads → fresh-
context worker per surface) is validated and now battle-tested.
