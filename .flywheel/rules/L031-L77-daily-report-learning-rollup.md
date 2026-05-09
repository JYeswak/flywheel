## L77 — DAILY-REPORT-LEARNING-ROLLUP

---
id: L77
title: Daily report learning rollup
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: no-daily-narrative
---

Every flywheel-initialized repo SHOULD have one daily narrative report under
`.flywheel/reports/daily-YYYY-MM-DD.md`. The report is the daily synthesis
surface for shipped beads, feedback memories, new trauma classes, doctrine
promotions, Jeff-intel rows, stuck work, next ready work, and cross-orch state.

**How to apply:**
- Generate with `/flywheel:daily-report` or
  `.flywheel/scripts/daily-report.sh --repo <repo> --json`.
- `flywheel-loop doctor --json` MUST expose `.daily_report` and
  `daily_report_age_hours`.
- Doctor status fails when the latest report is older than 36 hours.
- `doctor-signal-bead-promotion.sh` promotes stale or missing reports with the
  `daily_report` symptom instead of leaving narrative drift as a human-noticed
  gap.
- Use `--notify` only when the generated report contains hard blockers.

**Forbidden outputs:**
- Claiming the flywheel learned from a day without a daily report or an explicit
  no-report blocker.
- Sending routine completion notifications when the report has no hard blocker.
- Treating Jeff-intel, fuckup-log, dispatch-log, memory, or doctor state as
  separate daily narratives that do not roll up.

**Evidence:** bead `flywheel-o7dq`; command
`~/.claude/commands/flywheel/daily-report.md`; generator
`.flywheel/scripts/daily-report.sh`; tests `tests/daily-report.sh`.

**Companion rules:** L56 (promotion ladder), L61 (wire into README and canonical
paths), L63 (Jeff-intel network), L70 (chain repair), L71 (validate every
surface), and L72 (storage/headroom as daily-report sibling signal).

