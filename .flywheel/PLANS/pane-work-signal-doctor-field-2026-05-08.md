# Pane Work Signal Doctor Field

`flywheel-loop doctor --json` now exposes `.pane_work_signal` as a defense-in-depth health surface for Codex false-idle disagreement after ntm#124.

Schema marker: `pane-work-signal-doctor/v1`

Required fields:

- `status`: `ok`, `warn`, `fail`, or `disabled`
- `disabled`: boolean rollback-state marker
- `disabled_reason`: `pws_disabled_via_env`, `pws_disabled_via_file`, or null
- `disagreements_by_pane`: map of pane index to false-idle disagreement count
- `streak_counts`: map of pane index to observed disagreement streak count
- `warnings`: warning-severity `ntm_codex_false_idle` signals
- `errors`: error-severity `ntm_codex_false_idle` signals after 3 observed disagreements or >30 minutes

Promotion target:

- `ntm-health-codex-false-idle-followup`

Reference:

- `.flywheel/PLANS/pws-vs-islivebusy-2026-05-08.md`
