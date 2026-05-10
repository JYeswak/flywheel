---
bead: flywheel-lrdum
title: bead-evidence-indexer.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 3 of 17)
sister_exemplars: 0pkcf (985), ou656 (985)
---

# Journey: flywheel-lrdum

## What Joshua asked for

Wave-1-beads-3 (3rd ok1sk sub-bead). Beads-lane this time. Bash wrapper
around Python heredoc — bash scaffolder applies normally (only `.sh`
files with `#!/usr/bin/env python3` shebang need py-scaffolder).

## What I shipped

- 18 TODO markers filled with substantive impl
- doctor: 6 named probes (python3, jq, repo_root_resolvable, beads_dir_present,
  state_dir_writable, audit_log_dir_writable) with rollup
- health: $SCAFFOLD_AUDIT_LOG binding with stale-threshold
- repair: 2 scopes (state_dir, audit_log_dir) with apply contract
- validate: 3 subjects (bead-id with canonical pattern, evidence-path
  with canonical dir constraint, audit-row JSONL shape)
- audit: cli_emit_audit_tail with row_shape doc
- why: 3 states (found/not_found/unavailable)
- Test 13 → 19 (calibrated 2 + added 6 fillin including dotted-sub-bead
  pattern test for `flywheel-X.N.M` shape that this indexer specifically
  needs to handle)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- Caught the `flywheel-wzjo9.1.2`-style dotted sub-bead pattern in the
  validate-bead-id regex (`^flywheel-[a-z0-9]+(\.[0-9]+)*$`) — explicit
  test (test 18) confirms it accepts the dotted form. Without this, the
  indexer would reject all wave-bead sub-beads.
- evidence-path validate enforces `.flywheel/audit/flywheel-*/` OR
  `.flywheel/journal/` — the two canonical evidence dirs per the bead-
  evidence-indexer's domain. Rejects evidence dropped elsewhere.

## Files touched

- `.flywheel/scripts/bead-evidence-indexer.sh` (367 → 853 lines)
- `tests/bead-evidence-indexer-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-lrdum/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-lrdum.md`

## Mission fitness

Class: **direct**. Wave-1-beads-3 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on a beads-lane indexing primitive.
