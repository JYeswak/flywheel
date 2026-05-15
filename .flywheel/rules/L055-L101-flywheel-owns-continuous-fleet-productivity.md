## L101 — FLYWHEEL-OWNS-CONTINUOUS-FLEET-PRODUCTIVITY

---
id: L101
title: Flywheel owns continuous fleet productivity
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: idle-with-work-available
---

Flywheel:1 owns continuous productivity across the fleet. A peer session may be
quiet only when it is genuinely caught up or blocked by something Joshua must
personally decide or perform. Workers waiting, empty or low ready queues, and
unfiled findings are not downtime; they are a flywheel:1 action signal.

This ownership is not subordinate to a generic "no cross-repo orchestration"
shortcut. Flywheel is the source-of-truth repo for fleet operating doctrine, so
Flywheel-owned doctrine, rules, validation schemas, install templates, and
transport-gated orchestration packets may cross repo boundaries when the target
surface is Flywheel-owned or has no conflicting owner declaration. Default-deny
protects peer-owned product/client surfaces and explicit non-Flywheel ownership;
it does not block Flywheel from keeping the fleet on the same operating
doctrine.

**Why:** Joshua's 2026-05-04 directive in memory
`feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`
states that every project stays productive unless a true Josh-blocker exists,
and true blockers notify Joshua immediately. Skillos and mobile-eats both went
idle with workers waiting and findings still convertible to beads. The missing
information flow let reports substitute for work. Donella #6 surfaces the stock;
Donella #4 gives flywheel:1 the self-organization loop to compose work for peer
orchestrators.

**States:**
- `productive`: workers are active, commits/callbacks are flowing, or no
  actionable backlog source is present.
- `idle_with_work_available`: workers are waiting past threshold and at least
  one always-available work source is nonzero.
- `substrate_blocked`: peer progress is blocked on a flywheel-owned substrate
  repair with a canonical workaround path.
- `true_josh_blocker`: Joshua-personal action is required, such as a security
  or PHI decision, a paradigm-level shift, or a destructive approval.

**Always-available work hierarchy, in order:**
1. Doctor `errors[]` -> fix-bead per error.
2. `fuckup_triage` candidates -> promotion bead.
3. `closed_bead_audit_pending` -> reopen-or-close evaluation bead.
4. `canonical_drift` / `fleet_repo_l_rule_lag` -> backfill bead.
5. Recent commits without README/AGENTS.md update (L61) -> ecosystem-touch bead.
6. INCIDENTS.md unprocessed events -> promotion bead.
7. Skill citation graph gaps -> audit bead.
8. Gap-hunt-probe findings -> structural-fix bead.
9. Mission-anchor doctrine drift -> mission-lock refresh bead.

**How to apply:**
- `.flywheel/scripts/peer-orch-productivity-watch.sh` reads loop markers,
  topology, worker activity, `br ready`, doctor state, and orchestrator tails.
- `flywheel-loop doctor --json` exposes
  `peer_orch_idle_with_work_available_count`,
  `peer_orch_substrate_blocked_count`, `true_josh_blocker_count`, and
  `peer_orch_productivity_watch`.
- `/flywheel:status` surfaces
  `Fleet productivity: <productive>/<total> | idle-with-work=<N> | substrate-blocked=<N>`.
- `idle_with_work_available` after five minutes triggers an xpane productivity
  escalation packet with three concrete bead-filing or dispatch instructions.
- `true_josh_blocker` triggers the Joshua-notify path: Pushover/mac-alert style
  notification plus a cross-orch ledger row. Substrate corruption with a
  canonical workaround stays flywheel:1-owned.

**Forbidden outputs:**
- Treating "session is idle" as a status report to Joshua.
- Reporting "br ready is empty" as terminal instead of filing beads from the
  hierarchy above.
- Letting a peer orchestrator sit beyond five minutes with workers waiting and
  findings unfiled.
- Notifying Joshua for anything resolvable by xpane productivity escalation.
- Staying silent on a true Josh-blocker.

**Evidence:** memory
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`;
script `.flywheel/scripts/peer-orch-productivity-watch.sh`; tests
`tests/peer-orch-productivity-watch.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L48 (substrate exhaustion), L61 (ecosystem wire-in), L70
(same-tick chain-forward), L75 (peer orchestrator blocker coordination), L85
(idle-state-class canonical), L92 (audit findings route by data), L98
(architecture-health measured, not individual agents), and L99
(worker-recovery SLO).
