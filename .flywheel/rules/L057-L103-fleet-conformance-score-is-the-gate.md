## L103 — FLEET-CONFORMANCE-SCORE-IS-THE-GATE

---
id: L103
title: Fleet conformance score is the gate
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: fragmented-fleet-conformance-drift
---

Every flywheel-installed session MUST expose one bounded fleet-conformance
score that composes doctrine coverage, root AGENTS freshness, mission-lock age,
doctor status, META-RULE cache freshness, and identity drift. The score is the
gate; per-rule and per-axis audits are drill-down only.

**How to apply:**
- `.flywheel/scripts/fleet-conformance-probe.sh --fleet --json` emits
  `fleet_conformance[]`, color counts, worst session, and min score.
- `flywheel-loop doctor --json` exposes `fleet_conformance`,
  `fleet_conformance_red_count`, `fleet_conformance_yellow_count`,
  `fleet_conformance_green_count`, `fleet_conformance_worst_session`, and
  `fleet_conformance_min_score`.
- `/flywheel:status` renders one compact line after Fleet productivity:
  `Fleet conformance: <green>/<total> green | yellow=<N> | red=<N> | worst=<session>:<score>`.
- Red sessions get same-tick `CONFORMANCE-DRIFT` xpane packets via
  `fleet-conformance-probe.sh --apply`; the packet names the session, score,
  repo, and red axes without ranking individual agents.

**Forbidden outputs:**
- Treating separate L-rule, identity, mission-lock, or META-RULE audits as the
  primary fleet health gate when the conformance score is available.
- Publishing per-agent rankings or blame labels from conformance data. This is
  a session/substrate score, not an individual performance score.
- Letting a red conformance session wait for the next tick without either a
  `CONFORMANCE-DRIFT` packet or a concrete `chain_blocked_reason`.

**Evidence:** probe `.flywheel/scripts/fleet-conformance-probe.sh`; tests
`tests/fleet-conformance-probe.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L61 (ecosystem wire-in), L70 (same-tick chain-forward),
L96 (doctrine 3-surface diff), L98 (measured system health, not individual
agents), L101 (continuous fleet productivity), and L102 (META-RULE cache
freshness).

