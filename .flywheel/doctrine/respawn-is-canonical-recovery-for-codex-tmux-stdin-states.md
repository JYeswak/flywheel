---
title: "Respawn is Canonical Recovery for Codex+Tmux Stdin States (L91 detector-only + L95 recovery ladder)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Respawn is Canonical Recovery for Codex+Tmux Stdin States

Version: `respawn-canonical-recovery-codex-tmux-stdin/v1`
Owner: orchestrator + worker-recovery substrate
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.125 (memory-without-cross-link wire-in)
Sister beads: flywheel-2xdi.109 (silent-deaf), flywheel-2xdi.110 (parallel-impl P2 receipts), flywheel-2xdi.117 (jeff-response-shape-5 not-yet-promoted)

## TL;DR

The codex+tmux pair has **no programmatic recovery** for stuck-input states
(QUEUED_NOT_SUBMITTED, stale-chevron-input-deaf, rotate-stdin-contamination,
post-callback-input-deaf). The L91 four-state probe DETECTS these states
reliably; the auto-retry-helper that was supposed to RECOVER has failed
empirically across 4+ data points. **Recovery primitive = `ntm respawn`**
(canonical), or Joshua-side Enter as fallback. Future auto-retry helpers that
operate in the same stuck-input space will fail for the same reason — always
escape to respawn.

## Canonical memory source

This doctrine summarizes
`feedback_l91_auto_retry_helper_failed_4_data_points.md` — the META-RULE
memory documenting the empirical failure of auto-retry helpers and the
canonical respawn fallback. Read the memory for the original
W2-dispatch-hardening reframing context (2026-05-07 audit-pivot plan-arc:
split L91 into detector-only + recovery-doesn't-exist-programmatically).

## The pattern

### Why programmatic recovery fails

The codex CLI's input handler runs over a tmux pane's stdin. When the input
buffer becomes stuck (QUEUED_NOT_SUBMITTED chevron, stale-chevron post-callback,
rotate-banner contamination, post-callback input-deaf), the agent's stdin reader
no longer drains in response to subsequent `ntm send` writes. The text lands at
the transport layer but never crosses the input boundary into agent processing.

Auto-retry helpers that re-send the same packet operate in the SAME stuck-input
space — they fail for the same reason. The only reliable escape is a
**session-state reset** (kill + relaunch pane → fresh stdin handler).

### Canonical recovery primitive

```bash
# Detect (L91 four-state probe)
ntm robot-tail <session> --panes=<N> --lines=10
# If state is QUEUED_NOT_SUBMITTED / input_deaf / stale_chevron:

# Recover (respawn)
/flywheel:respawn <session> --panes=<N>
# Internally:
#   tmux kill-pane → respawn-pane → relaunch codex --dangerously-bypass-approvals-and-sandbox
#   → wait for fresh chevron → redispatch original packet
```

The `ntm respawn` + `codex --dangerously-bypass-approvals-and-sandbox` flow is
the canonical recovery path. Sister primitive:
`fleet-rotate-on-caam-swap.sh` uses the same respawn shape for credential
rotation.

### What NOT to do

- **Re-send the same packet without respawn** — operates in the same stuck-input
  space; will fail for the same reason
- **Bare-tmux send-keys Enter** — bypass-attempt via tmux primitives; works
  sometimes (per `feedback_enter_press_not_respawn_class.md`) but unreliable
- **Design new auto-retry helpers** — they will hit the same trauma class
- **Wait longer** — codex+tmux stuck-input is a state-space, not a time-budget
  problem; waiting does not unstick

## Anti-pattern

Designing more "auto-retry" helpers that operate in the SAME stuck-input space
the original send used. The memory's empirical evidence: 4 separate failure data
points on j018 re-dispatch attempts. Always escape to respawn.

## Trauma class siblings (4 sister memories cited in source)

The codex+tmux stdin trauma class is documented across 5 memories. This
doctrine doc anchors the cluster:

| # | Memory | Class | First fire |
|---|---|---|---|
| 1 | `feedback_l91_auto_retry_helper_failed_4_data_points.md` (this) | QUEUED_NOT_SUBMITTED auto-retry failure | 2026-05-07 |
| 2 | `feedback_ntm_rotate_stdin_contamination_use_respawn_path.md` | Rotate banner pollutes target stdin | 2026-05-06 |
| 3 | `feedback_chevron_visible_does_not_mean_submits_work.md` | Visual classifier ≠ work submitted | 2026-05-06 |
| 4 | `feedback_post_callback_stale_chevron_input_deaf_class.md` | Post-callback input-deaf | (sister class) |
| 5 | `feedback_enter_press_not_respawn_class.md` | Bare-Enter sometimes works (different shape) | 2026-05-06 |

**Cluster meta-rule:** tmux+codex stdin states are not deterministic; respawn
is the catch-all. Detection primitives (L91 four-state, frozen-pane-detector v2,
idle-state-probe) help triage which state we're in; recovery primitive is
uniformly `ntm respawn`.

## Behavioral vs name cross-linking

This doctrine doc gives the memory a **name cross-link** so gap-hunt-probe's
memory-without-cross-link class clears. The memory's discipline was ALREADY
embedded behaviorally:

| Surface | Discipline embedded |
|---|---|
| `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md` | L91 detector-only contract |
| `.flywheel/rules/L049-L95-worker-stall-recovery-protocol.md` | Recovery ladder ending in respawn (`if same worker stalls after redispatch, file or update a bead`) |
| `.flywheel/rules/L053-L99-worker-recovery-slo-180s.md` | Cross-references L91+L95; SLO=180s |
| `.flywheel/scripts/fleet-rotate-on-caam-swap.sh` | Canonical respawn primitive for credential rotation |
| `~/.claude/skills/.flywheel/bin/flywheel` | Doctor probe references L91 + recovery primitives |

But the probe's name-grep didn't see those as citations of the meta-rule's
CLASS string. This is the SAME shape as 2xdi.109 (silent-deaf) and 2xdi.110
(parallel-impl P2) — **3rd instance of recurring `semantically-embedded-discipline-name-grep-blind-spot`** (xbsd8's harvest class).

Per substrate-self-improving loop (validated in 2xdi.110): no new calibration
bead filed here; xbsd8 owns the harvest for faqj2 next-tick.

## Sister doctrine

- `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md`
  (L91 detector contract)
- `.flywheel/rules/L049-L95-worker-stall-recovery-protocol.md`
  (recovery ladder ending in respawn)
- `.flywheel/rules/L053-L99-worker-recovery-slo-180s.md`
  (recovery SLO 180s; references L91+L95)
- `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md`
  (sister memory-without-cross-link wire-in, 2xdi.109; same blind-spot shape)
- `.flywheel/doctrine/parallel-impl-self-validates-via-p2-receipts.md`
  (sister memory-without-cross-link wire-in, 2xdi.110; same blind-spot shape)
- `~/.claude/skills/.flywheel/scripts/fleet-rotate-on-caam-swap.sh`
  (canonical respawn primitive)
- 4 trauma sister memories (above table)

## Conformance

A worker stuck-input recovery proves conformance via:

- L91 four-state probe runs first (detection); state classified
- If classified as not_started/stuck-input: skip auto-retry, escape directly to
  respawn
- `/flywheel:respawn <session> --panes=<N>` invoked (or
  `fleet-rotate-on-caam-swap.sh` if caam-paired)
- Post-respawn: relaunch codex via canonical bare command
  (`codex --dangerously-bypass-approvals-and-sandbox`) — no model/reasoning flags
- Redispatch original packet (same task_id, same path)
- Recovery latency tracked against L99 180s SLO; breach surfaced

## Below-trauma-class tracking

5-class trauma cluster confirmed (4 sibling memories + this one). Promotion
threshold (N=4 for trauma-class) MET. This doctrine doc IS the cluster
canonicalization.

If a 6th sibling memory surfaces (e.g., a new tmux+codex stdin state we haven't
seen): add it to the cluster table above and reinforce the
"respawn-is-the-catch-all" meta-rule.

## Harvest signal for faqj2 next-tick

This is the **3rd instance of `semantically-embedded-discipline-name-grep-blind-spot`**
shape (after 2xdi.109 + 2xdi.110). xbsd8 owns the harvest pattern. The
substrate-self-improving loop validated in 2xdi.110 + this bead handles the
class:

- Discipline IS load-bearing (5 rules + 1 script + canonical CLI)
- Probe name-grep blind
- Forward-link doctrine doc clears the probe class
- No new calibration bead (xbsd8 captures the pattern for faqj2)
