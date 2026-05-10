---
title: plan-to-bead-auto-trigger.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-gbfpo
task: flywheel-gbfpo-d0bb49
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 4 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985 (avg 985)
---

# Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/plan-to-bead-auto-trigger.sh` |
| Lines (before) | 145 |
| Lines (after) | 632 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Verb collisions | NONE |

## Acceptance gates

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ 0 violations |
| AG4: tests >= 13 | ✓ 19/19 |
| AG5a: doctor 6+ named probes | ✓ br, jq, find, repo_root, plans_dir, audit_log_dir |
| AG5b: health binds audit log | ✓ |
| AG5c: repair scope-specific | ✓ 2 scopes (plans_dir, audit_log_dir) |
| AG5d: validate per-subject | ✓ 3 subjects (plan-path, bead-id, audit-row) |
| AG5e: audit cli_emit_audit_tail | ✓ |
| AG5f: why provenance | ✓ |

## Domain-specific fillin highlights

- **`validate plan-path`**: 3-layer enforcement (under .flywheel/PLANS/,
  .md extension, exists on disk) with distinct `reason` codes for each
  failure mode; tests 16+17 explicitly verify both rejection paths
- **`validate bead-id`**: same canonical regex as sister lrdum
  (`^flywheel-[a-z0-9]+(\.[0-9]+)*$`) — accepts dotted sub-bead form
- **Doctor probes the load-bearing trio**: br executable (the bead writer),
  jq (envelope shaping), plans_dir present (the input source for the
  plan-to-bead pipeline)

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/plan-to-bead-auto-trigger.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/plan-to-bead-auto-trigger.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/plan-to-bead-auto-trigger.sh \
  && bash tests/plan-to-bead-auto-trigger-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
