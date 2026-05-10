---
title: test-doctor-empty-errors.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-bu0es
task: flywheel-bu0es-2300e2
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 6 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985, gbfpo=985, kz7o0=985 (avg 985)
---

# Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/test-doctor-empty-errors.sh` |
| Lines (before) | 168 |
| Lines (after) | 657 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Verb collisions | NONE |
| Note | This is a TEST script that asserts flywheel-loop doctor's loud-failure invariant — directly relevant to flywheel-9vb9i (the doctor sentinel fix) |

## Acceptance gates

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ 0 violations |
| AG4: tests >= 13 | ✓ 19/19 |
| AG5a: doctor 6 named probes | ✓ bash, jq, mktemp, flywheel_loop_executable, python3, audit_log_dir |
| AG5b: health binds audit log | ✓ |
| AG5c: repair scope-specific | ✓ 2 scopes |
| AG5d: validate per-subject | ✓ 3 subjects (test-name, fixture-path, audit-row) |
| AG5e: audit cli_emit_audit_tail | ✓ |
| AG5f: why provenance | ✓ |

## Domain-specific fillin highlights

- **`validate test-name`**: enforces `^test-[a-z0-9-]+$` (canonical fleet-wide test-script naming convention)
- **`validate fixture-path`**: 2-layer enforcement (regular file + readable) — fixture-driven tests are common in the flywheel test suite
- **Doctor probes the load-bearing primitives for the synthetic test**: the `flywheel_loop_executable` check is meta — this script tests flywheel-loop, so probing that flywheel-loop is reachable is the critical readiness check

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/test-doctor-empty-errors.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/test-doctor-empty-errors.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/test-doctor-empty-errors.sh \
  && bash tests/test-doctor-empty-errors-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
