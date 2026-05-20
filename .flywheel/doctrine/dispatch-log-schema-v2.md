# Dispatch Log Schema v2

`dispatch-log.jsonl` schema v2 remains append-only and backward compatible.
Existing rows without goal-mode monitor fields are treated as legacy or
non-monitored rows.

## Codex Goal-Mode Extension

Optional fields added for Codex `/goal` semantic monitoring:

- `monitor_probe_id`: UUID string. Present only for Codex pane dispatches that
  are covered by the Layer 2/3/4 goal-mode monitor.
- `goal_mode_trauma_fired`: array of trauma class IDs observed for the
  dispatch. Missing means legacy or not monitored; an empty array means
  monitored and no trauma has fired at row-write time.

The five goal-mode trauma class IDs are:

- `codex-goal-entry-failed`
- `codex-goal-abandoned`
- `codex-goal-mode-bypassed`
- `codex-goal-resume-stuck`
- `codex-goal-mode-flapping`

Layer 3 daemon selection is conservative: it only treats rows as monitored when
`agent_type == "codex"` and `monitor_probe_id` is present.
