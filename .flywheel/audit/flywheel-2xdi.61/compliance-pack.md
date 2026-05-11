# Compliance Pack: flywheel-2xdi.61 — score 960/1000

| Axis              | Score | Notes |
|-------------------|-------|-------|
| Scope discipline  | 100 | INCIDENTS.md append only; no script mutation |
| Acceptance gate   | 100 | gap closed via doctrine surface citation; re-probe verifies |
| Reservation       | 100 |  |
| Pathspec staging  | 100 |  |
| L112 probe        | 100 |  |
| Mission fitness   | 90  | Adjacent — fleet-substrate documentation quality |
| Evidence presence | 100 |  |
| Sniff             | 95  | Honest bug-shape correction: operator-on-demand, not orphan |
| Doctrinal align   | 95  | INCIDENTS.md is the canonical surface for this pattern |
| Brand             | 90  | 36-line citation + cross-ref to beads_rust#289 + sister 2xdi.59 |

## Skill discoveries
- pattern-emerged: "operator-on-demand probe disposition" — distinct from 2xdi.59's tick-loop-orphan disposition. When a `*-probe.sh` is intentionally an operator-invoked diagnostic (not per-tick), the right wire-in is INCIDENTS.md / doctrine citation describing when to invoke. Captures real doctrine value AND satisfies probe's receivers_text check.
