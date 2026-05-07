# EXECUTION-PROGRESS — ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07

**Snapshot:** 2026-05-07T18:28:47Z
**Status:** 34/38 closed (89%), ~7,483 LOC ripped, 8 ISSUE/PARTIAL verdicts. `ki5s9` landed during polish prep; `r4hmy` remains in flight/open. ntm#124 still OPEN no Jeff response 2026-05-07T14:31Z (~4h since filing at snapshot).

## Wave 1 — Tier-1 highest-LOC-delete (10 beads, 10/10 closed)

| Bead | Script | LOC delta | Four-lens | ntm surface |
|------|--------|---:|---|---|
| zqiw2 | peer-orch-productivity-watch.sh DELETED | -621 | 9/9/9/9 | ntm coordinator digest |
| sjdj2 | fleet-coherence-scan.sh 722→34 | -688 | 9/9/9/9 | ntm sessions+activity+health |
| 8bnz8 | frozen-pane-detector.sh 1557→80 | -1477 | 9/9/9/9 | ntm errors+activity+wait |
| p0wwm | codex-template-stuck-detector.sh 1165→49 | -1116 | 9/9/9/9 | ntm errors+activity+wait |
| zhr6s | worker-auto-respawn-watchdog.sh 451→100 | -351 | 9/9/10/9 | ntm wait+respawn |
| zr12c | team-pulse-heartbeat.sh 470→105 | -365 | 9/9/9/9 | ntm health+summary |
| 8tp66 | worker-stall-alert-probe.sh 370→128 | -242 | 9/9/9/9 | ntm wait --until=GENERATING |
| 9gnjl | recency-weighted-two-truth-classifier.sh 220→46 | -174 | 9/9/9/9 | ntm diff+activity |
| gndhc | recovery-escape-then-reprompt.sh 200→39 | -161 | 9/9/9/9 | ntm interrupt+replay |
| 7rerv | verify-callback-delivery.sh 183→61 | -122 | 9/9/9/9 | ntm history --json |

**Wave 1 total: -5,317 LOC across 10 scripts.**

## Wave 2 — ISSUE research (8 beads, 8/8 closed, all verdict captured)

| Bead | ntm surface | Companion script | Verdict | Outcome |
|------|---|---|---|---|
| txeui | review-queue | idle-state-probe.sh L85 taxonomy | **ISSUE** | gap bead flywheel-txeui.1 filed |
| 8e1fx | locks | shared-surface-reservation-check.sh | **ISSUE** | jeff_issue_body drafted at `/tmp/ntm-wire-in-W2-8e1fx-2026-05-07-jeff-issue-body.md` |
| m9aoh | unlock | shared-surface-reservation-check.sh | **ISSUE** | jeff_issue_body drafted |
| melgv | lock | MCP Agent Mail reserve_files | **PARTIAL/keep wrapper** | Until upstream issue ships |
| clt8w | scrub | secret-scan-wrapper.sh (W2S) | **PARTIAL/keep wrapper** | Native lacks fail-closed callback contract |
| zhryi | redact | agent-mail-send-redacted.sh | **ISSUE/partial** | jeff_issue_body drafted; native does not cover SEC-class fixtures |
| ro663 | work vs assign | dispatch-and-log.sh | **ISSUE/pick `assign`** | jeff_issue_body drafted; pick `ntm assign`, deprecate `work` |
| i32lt | worktree(s) | plan-to-bead-auto-trigger.sh, prd skill | **PARTIAL/keep wrapper** | Native covers prd-skill worktree iso, not plan→bead trigger |

**8 ISSUE/PARTIAL verdicts captured.**

## Wave 3 — P1 rewrites (11 beads, 11/11 closed)

| Bead | Script | LOC delta | Status |
|------|--------|---:|---|
| 3atlk | leverage-ceiling-probe.sh 489→173 | -316 | CLOSED 9/9/9/9 |
| rb88g | peer-orch-respawn-permit.sh | -194 | CLOSED 8/8/9/8 |
| vw6am | agent-mail-send-redacted.sh | -243 | CLOSED 9/9/9/9 |
| h9gr6 | build-dispatch-packet.sh | -321 | CLOSED 9/9/9/8 |
| 47ife | agentmail-registration-broadcast.sh | -232 | CLOSED 9/9/9/8 |
| a8opj | pane-work-signal.sh | -165 | CLOSED 9/9/9/9 |
| gg1mj | stale-error-auto-ping.sh | -151 | CLOSED 9/9/9/8 |
| ctd96 | dispatch-delivery-verify.sh | -174 | CLOSED 9/9/9/9 |
| v0smn | dispatch-capacity-gate.sh | -65 | CLOSED 9/9/9/9 |
| dj4a3 | dispatch-and-log.sh | -81 | CLOSED 9/9/9/9 |
| dnv8o | ntm-fleet-health.sh | -209 | CLOSED 9/9/9/9 |

Dispatch-log sanity: `vw6am`, `h9gr6`, `47ife`, `dnv8o`, `ctd96`, and `a8opj` have legacy `event:"closed"` rows without `pipeline_slug`; canonical `event:"close"` rows should be normalized before final close.

## Wave 4 — P2 wire-ins (6 beads, 5/6 closed)

| Bead | Script | LOC delta | Status |
|------|--------|---:|---|
| 7bs2z | flywheel-onboard.sh → ntm setup/init/shell/completion/bind | -484 | CLOSED 9/9/9/9 |
| 50q5d | jeff-binary-version-watchtower.sh → ntm version+upgrade | -215 | CLOSED 9/9/9/9 |
| 43c8f | daily-report.sh → ntm analytics+summary+bugs+scan | 0 | CLOSED 9/9/9/9 |
| 8y034 | dispatch-log-fitness-invariant.sh → ntm timeline | -145 | CLOSED 9/9/9/9 |
| ki5s9 | peer-orch-blocker-watch.sh → ntm swarm+rebalance | -136 | CLOSED 9/9/9/9 |
| r4hmy | private-tmp-prune.sh → ntm cleanup | -157 expected | OPEN/in flight on pane 4 |

## ntm#124 upstream watch

`flywheel-xyyfg` remains OPEN. Upstream: `https://github.com/Dicklesworthstone/ntm/issues/124`.

Filed 2026-05-07T14:31Z. No Jeff response is recorded in local bead state as of this snapshot. The issue blocks watch/`--watch` enablement because `ntm assign --watch` over-dispatches against busy panes.

Deferred beads:
- `flywheel-rd8oa` halt-disease-watchdog.sh → ntm watch+grep: -237 expected
- `flywheel-sox9n` peer-orch-freeze-monitor.sh → ntm watch+activity: -622 expected
- `flywheel-7fcki` idle-pane-auto-dispatch.sh → ntm wait+assign --watch: -559 expected

Deferred expected LOC: **-1,418**.

## Total LOC delta to date

**~-7,483 LOC ripped from flywheel** by replacing hand-rolled implementations with native ntm primitives.

Notes:
- This is the close-gate planning total requested by the orchestrator for the 34/38 state.
- Raw title-expected deltas over the 34 closed beads sum differently because several worker close rows report measured deltas that differ from original inventory estimates.
- Remaining non-ntm#124 open work: `r4hmy` at -157 expected.

## Phase 5 polish gate — dry-run result

Read-only command:

```bash
.flywheel/scripts/quality-bar-close-gate.sh --plan-slug ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07 --json
```

Result: **FAIL**.

Reasons:
- `quality_bar_passed_false`
- `current_phase_not_polish_or_ready:decompose`
- `audit_findings_missing`
- `jeff_score_missing`
- `donella_score_missing`
- `joshua_score_missing`
- `composite_missing`

Phase 5 r1 polish artifact: `.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/05-POLISH-r1.md`.
