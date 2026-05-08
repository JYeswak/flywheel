# flywheel-p4nu receipt

## Probe

Command receipts preserved:
- `/tmp/flywheel-p4nu-robot-activity-r3.json` (`rc=0`)
- `/tmp/flywheel-p4nu-robot-is-working-r3.json` (`rc=0`)
- `/tmp/flywheel-p4nu-robot-agent-health-r3.json` (`rc=0`)
- `/tmp/flywheel-p4nu-mismatch-table.json`

Commands:

```bash
ntm --robot-activity=flywheel --panes=2,3,4
ntm --robot-is-working=flywheel --panes=2,3,4
ntm --robot-agent-health=flywheel --panes=2,3,4 --no-caut
```

## Mismatch Table

| Pane | activity | activity patterns | is-working | is-working recommendation | health local working | health recommendation | mismatch |
|---|---|---|---|---|---|---|---|
| 2 | THINKING | codex_working, codex_esc_interrupt, codex_chevron_prompt | false | SAFE_TO_RESTART | false | HEALTHY | true |
| 3 | THINKING | codex_working, codex_esc_interrupt, codex_chevron_prompt | false | SAFE_TO_RESTART | false | HEALTHY | true |
| 4 | WAITING | codex_chevron_prompt | false | SAFE_TO_RESTART | false | HEALTHY | false |

## Source Trace

- `/Users/josh/Developer/ntm/internal/robot/activity.go:19` defines the 15-line live thinking window.
- `/Users/josh/Developer/ntm/internal/robot/activity.go:828` says `IsLiveBusy` is the canonical cheap check for whether `--robot-activity` would classify a pane as `THINKING`.
- `/Users/josh/Developer/ntm/internal/robot/is_working.go:19` describes `--robot-is-working` as the direct answer to never interrupting useful work.
- `/Users/josh/Developer/ntm/internal/robot/is_working.go:254` hints `ParseWithHint`, but `/Users/josh/Developer/ntm/internal/robot/is_working.go:270` builds `PaneWorkStatus` from parser state without the `IsLiveBusy` override.
- `/Users/josh/Developer/ntm/internal/robot/agent_health.go:22` defines agent-health as local state plus provider usage; `/Users/josh/Developer/ntm/internal/robot/agent_health.go:303` derives health from that `PaneWorkStatus`.
- `/Users/josh/Developer/ntm/internal/cli/assign.go:998` already applies `robot.IsLiveBusy` before dispatching.

## Decision

Decision: `file_upstream`.

The mismatch reproduces on current local main. The upstream issue was filed as:
https://github.com/Dicklesworthstone/ntm/issues/133

Issue body:
- `/tmp/flywheel-p4nu-ntm-robot-surface-divergence-issue.md`
- Post-submit verification: `body_length=3929`, `forbidden_hits=0`.

Internal tracking update:
- `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md`

## Joshua Lens

From Joshua's 25-year operations-management and company-building lens, this is
not cosmetic divergence. Scheduling-gate disagreement is the class of brittle
ops process that erodes trust in auto-recovery because a team cannot tell which
green surface is safe to act on. Filing upstream is the durable move: it forces
the substrate to converge instead of making each downstream operator remember
which JSON field to distrust after the original author leaves.
