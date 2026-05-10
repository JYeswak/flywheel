---
title: test-loop-driver-doctor.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-05ost
task: flywheel-05ost-fd119a
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 7 of 17)
sister_exemplars: 0pkcf, ou656, lrdum, gbfpo, kz7o0, bu0es (avg 985)
---

# Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/test-loop-driver-doctor.sh` |
| Lines (before) | 196 |
| Lines (after) | 685 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Verb collisions | NONE |
| Note | Synthetic L57 loop-driver doctor verdict test (does NOT touch launchctl); sister to bu0es (test-doctor-empty-errors) — same canonical test pattern |

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

## Sister-pattern application (bu0es precedent)

This script is the **synthetic loop-driver doctor verdict test** —
sister to `test-doctor-empty-errors.sh` (bu0es, 985). Same domain shape:
- test-name regex (^test-[a-z0-9-]+$)
- fixture-path 2-layer enforcement
- flywheel_loop_executable as load-bearing meta-probe

Recipe applied proactively (zero regression catches needed).

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/test-loop-driver-doctor.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/test-loop-driver-doctor.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/test-loop-driver-doctor.sh \
  && bash tests/test-loop-driver-doctor-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
