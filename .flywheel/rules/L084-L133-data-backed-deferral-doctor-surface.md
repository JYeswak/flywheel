## L133 — DATA-BACKED-DEFERRAL-DOCTOR-SURFACE

---
id: L133
title: Data-backed deferral doctor surface
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: data-decides-not-meatpuppet
---

Doctor surfaces `data_backed_deferral` with saves, overrides, and recent
violation counts from the fleet JSONL receipts. Status is `ok` when recent
violations are zero, `warn` when violations are 1-4, and `fail` at 5 or more.
The doctor field may include a single-line `last_suggested_action` summary, but
must not echo raw pane scrollback or multiline draft text.

This makes the doctrine "data decides, not human meatpuppet" visible every tick:
the lint/enforcement side creates receipt rows, and doctor turns the rows into a
stable machine-readable signal.

**Evidence:** bead `flywheel-7mq1`; implementation in
`~/.claude/skills/.flywheel/lib/misc.sh` and
`~/.claude/skills/.flywheel/lib/portable/core.sh`; regressions
`tests/test_doctor_data_backed_deferral_clean_state.sh`,
`tests/test_doctor_data_backed_deferral_warn_threshold.sh`,
`tests/test_doctor_data_backed_deferral_fail_threshold.sh`, and
`tests/test_doctor_data_backed_deferral_no_raw_pane_text.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

