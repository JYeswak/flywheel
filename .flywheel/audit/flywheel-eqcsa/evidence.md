---
title: br-authority-probe — substantive 18-TODO fillin
type: evidence
bead: flywheel-eqcsa
task: flywheel-eqcsa-5038ee
parent: flywheel-gf2rj (beads-substrate lane wave 1)
sister: flywheel-qprlj (beads-db-recover) / flywheel-dsrq1 / flywheel-ut3ng
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for br-authority-probe.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | grep -c TODO = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 PASS | 13/13 PASS | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 11 substrate checks
- **binary**: br_executable (the upstream binary the probe wraps)
- **target**: target_dir_resolvable, beads_dir_present (with symlink-aware messaging)
- **deps (5)**: jq, mktemp, realpath, grep, awk
- **config**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

### `health` (smoke-health.json)
Standard pattern — total_runs / last_run_ts / last_status / pass_rate / window.

### `repair` — 2 scopes (audit_log_dir, audit_log_truncate); apply contract gate first.

### `validate` (smoke-validate-{target-dir,audit-row}.json)
Two subjects:
- `target-dir [PATH]` — invokes the probe on the supplied directory and surfaces
  discovery_method / walk_up_distance / cross_tree from the probe output. Default
  path = $SCAFFOLD_TARGET_DIR.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields.

The target-dir validator self-tested against the real flywheel repo and
returned status=pass with discovery_method=local, walk_up_distance=0,
cross_tree=false — meaningful signal that the .beads dir is locally present
(no walk-up, no cross-tree symlink risk).

### `audit` — `cli_emit_audit_tail` route.

### `why` — row index OR substring on discovery_method / target_dir / cross_tree.

## Architecture coexistence

Same pattern as sister surfaces (s0c53 / hpirw / qprlj): legacy substantive
doctor/info/schema impls (~lines 250+) stay intact; scaffold stubs provide
canonical envelope shape that matches the 13/13 contract; legacy reachable
via dash-prefix `--doctor`.

## Mission fitness

Class: `direct`. The probe verifies br authority/discovery — load-bearing
for orchestrator workflow because every br invocation depends on the
discovery method resolving correctly. cross_tree symlink detection
specifically protects against the bead-isolation traumas filed in
2026-04-30 (Change 4.3 of the bead-isolation-fix doc).

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wgitr+beads chain.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; validate target-dir
  self-tested against real flywheel repo (discovery_method=local confirmed).
- **Jeff**: 9/10 — single-file edit; legacy code preserved.
- **Public**: 9/10 — three judges check passes; future fillin worker has
  this as direct sister exemplar for dsrq1 / ut3ng.

## L112 verify probe

```bash
bash .flywheel/scripts/br-authority-probe.sh doctor --json | jq -r '.status'
# expected: pass
```
