## L139 — TMP-LIFECYCLE-IS-A-CLOSE-GATE-AND-DOCTOR-INVARIANT

---
id: L139
title: Tmp lifecycle is a close gate and doctor invariant
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: tmp-lifecycle-blindness
---

Every worker MUST create one scratch directory with
`mktemp -d -t <bead-short-id>.XXXXXX`, use it as the only scratch root, copy
durable evidence into repo receipts or sanctioned state before close, remove
the scratch directory, and report `tmp_dir_released=true` in the callback.
Loose `/private/tmp/<bead-id>-*`, `/private/tmp/<bead-short-id>-*`, `/tmp`, or
`/var/tmp` task-shaped evidence paths are close blockers.

**How to apply:**
- Dispatch templates include the mktemp command before any work sequence.
- `.flywheel/scripts/validate-callback-before-close.sh` blocks missing or false
  `tmp_dir_released` as `tmp_dir_not_released`.
- The validator also blocks bare task-shaped tmp evidence outside the worker's
  mktemp directory.
- `flywheel-loop doctor` exposes `.storage.tmp_entry_count`; `>5000` is warn,
  `>10000` is critical/halt-on-breach.
- Layer 2 cleanup remains `.flywheel/scripts/tmp-aggressive-prune.sh` from
  commit `2c21355`; this rule does not reimplement it.

**Forbidden outputs:**
- DONE callback without `tmp_dir_released=true`.
- Durable evidence only under `/private/tmp` or `/tmp`.
- `br close` before scratch cleanup.
- Treating low disk as the first tmp lifecycle signal when count stock already
  exceeds threshold.

**Why:** The 2026-05-08 storage emergency hit 1.6% free and 18,041 tmp entries.
Layer 2 prune reclaimed 18 GiB, but cleanup alone leaves the next worker free
to recreate the same stock. Joshua's 25-year ops lens says every accreting
surface gets retention-by-default or the floor breach is accepted. The invariant
makes the stock visible before disk free space becomes the alarm.

**Evidence:** bead `flywheel-2bd2r`; doctrine
`.flywheel/doctrine/tmp-lifecycle.md`; validator
`.flywheel/scripts/validate-callback-before-close.sh`; doctor storage field in
`~/.claude/skills/.flywheel/lib/storage.sh`; test
`tests/tmp-lifecycle-doctor.sh`; failure taxonomy class
`tmp_dir_not_released`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L50, L52, L53, L56, L60, L70, L71, L72, L96, L110,
L116, and L120.
