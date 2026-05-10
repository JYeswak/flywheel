---
title: "PWS vs ntm IsLiveBusy Audit"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# PWS vs ntm IsLiveBusy Audit

Date: 2026-05-08
Bead: flywheel-yqbku
Upstream reference: ntm commit `3e44fe9e` (`fix(assign): watch loop honors live pane state, stops dispatching to busy panes (#124)`)

## Verdict

Recommendation: **KEEP-PWS-AS-DEFENSE-IN-DEPTH**

Do not deprecate `pane-work-signal.sh` yet. The original false-idle root cause
is now fixed upstream for ntm assign/watch and robot activity via
`robot.IsLiveBusy()`, but the current PWS layer is no longer the old independent
scrollback parser. It is an audit/receipt overlay around native `ntm activity`
and `ntm history`, with stale-sample and history-delta behavior that native
`IsLiveBusy()` does not provide.

Operational interpretation: native ntm activity is the primary activity truth;
PWS is a Codex dispatch-capacity guardrail and receipt surface that records
when `ntm health` still disagrees with the native activity path.

No follow-up bead filed for deprecation or scope restriction.

## Evidence

### ntm IsLiveBusy

- `/Users/josh/Developer/ntm/internal/robot/activity.go:19-27` defines a
  15-line live thinking window.
- `/Users/josh/Developer/ntm/internal/robot/activity.go:828-850` exposes
  `IsLiveBusy(scrollback, agentType)` as a single-snapshot live-window
  THINKING check.
- `/Users/josh/Developer/ntm/internal/cli/assign.go:991-1023` wires
  `robot.IsLiveBusy()` into `determineAgentState`; a live thinking pattern
  overrides idle.
- `/Users/josh/Developer/ntm/internal/assignment/store.go:368-382` permits
  `assigned->completed`, removing the invalid-transition warning class.
- `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md:321-333`
  records the 2026-05-08 sweep row for ntm#124.

### PWS as shipped in flywheel

- `.flywheel/scripts/pane-work-signal.sh:8-10` defines `WORK_WINDOW_S=90`,
  `STALE_S=300`, and `HISTORY_LIMIT=20`.
- `.flywheel/scripts/pane-work-signal.sh:22` accepts `--lines` for
  compatibility but explicitly performs no scrollback read.
- `.flywheel/scripts/pane-work-signal.sh:27-31` samples native
  `ntm activity` and `ntm history`, not raw pane text.
- `.flywheel/scripts/pane-work-signal.sh:50-51` writes a sample row; native
  working states (`THINKING|GENERATING|WORKING|RUNNING|STALLED`) become
  `truth_state=working`.
- `.flywheel/scripts/pane-work-signal.sh:57-86` classifies recent rows:
  foreground structured row, native activity, history hash delta in 90s,
  stale sample over 300s, then idle.
- `.flywheel/flywheel-loop-tick:894-931` applies PWS only to `cod|codex`
  panes and blocks capacity when PWS truth is not idle.
- `.flywheel/flywheel-loop-tick:905-921` emits SOFT
  `pane_work_signal_disagrees_with_ntm_health` when health says idle/error
  while PWS says working.

## Coverage Matrix

| Case | ntm IsLiveBusy | PWS current layer | Verdict |
|---|---|---|---|
| Fresh Codex `Working` bullet in live tail | Covered by `codex_working` over 15-line live tail | Covered indirectly when `ntm activity` reports THINKING; legacy fixture rows can also carry `foreground_working_state` | Overlap |
| Codex `esc to interrupt` or truncated `esc to i...` | Covered by `codex_esc_interrupt` | Covered indirectly via `ntm activity` | Overlap via native activity |
| `Waiting for background terminal` | Covered by `codex_waiting_background` | Covered indirectly via `ntm activity` | Overlap via native activity |
| Generic spinner/text thinking patterns | Covered by default robot CategoryThinking patterns | Covered indirectly via `ntm activity` | Native broader than PWS |
| Historical stale `Working` bullet above current idle prompt | Ignored by 15-line live-window filter | Current PWS does not raw-scan scrollback; stale rows older than 300s classify stale for Codex | Both avoid stale busy, PWS adds stale receipt |
| Velocity-based GENERATING | `IsLiveBusy()` itself cannot detect velocity; `ntm activity` can | PWS uses `ntm activity`, so it can inherit GENERATING | PWS useful as activity wrapper |
| STALLED state | Not detected by `IsLiveBusy()` itself | PWS treats STALLED as working capacity block | PWS adds conservative dispatch safety |
| History changed without visible thinking pattern | Not covered by `IsLiveBusy()` | PWS classifies `distinct_hashes > 1` in 90s as working | PWS adds weak signal |
| No recent sample | Not applicable | PWS emits `no_data` or `stale` with explicit reason | PWS adds observability |
| Non-Codex panes | Available by agent-specific/default robot patterns | Tick integration keeps non-Codex on ntm health/activity surfaces, PWS advisory only | No expansion recommended |

## Pattern Delta

Patterns IsLiveBusy matches that current PWS does not match directly:

- Codex-specific robot patterns:
  `codex_working`, `codex_waiting_background`, `codex_esc_interrupt`,
  `codex_thinking_bullet`.
- Default robot thinking patterns:
  braille spinner, dots spinner, `thinking`, `processing`, `analyzing`,
  `extended thinking`, `loading`, and `waiting`.

Patterns PWS matches that IsLiveBusy does not:

- Current PWS does not direct-match raw scrollback patterns in normal sample
  mode. It accepts `--lines` but does not read scrollback.
- PWS adds state predicates outside a single live-window regex check:
  `ntm activity` working states, 90s history hash delta, and 300s stale-sample
  classification.

## Recommendation Details

Keep PWS because it now does three useful jobs:

1. It records a durable receipt explaining Codex capacity decisions:
   `pane_work_signal_by_pane`, `pane_work_signal_disagreements`, and
   `idle_capacity_source`.
2. It preserves a local rollback/audit surface for health-vs-activity
   disagreements while ntm health, ntm activity, and assign/watch continue to
   evolve.
3. It adds conservative signals not present in `IsLiveBusy()` alone: STALLED
   as non-capacity, history delta, and stale/no-data classification.

Do not treat PWS as an independent replacement for ntm activity. The doctrine
should now read: **ntm activity is IsLiveBusy-backed primary truth; PWS is
defense-in-depth for Codex capacity and receipt evidence when `ntm health`
disagrees.**

## Action Items

- No deprecation bead filed.
- No scope-restriction bead filed.
- Memory updated in
  `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_pane_state_ntm_health.md`.
