# Compliance Pack: flywheel-2xdi.49 — score 970/1000

| Axis              | Score | Notes |
|-------------------|-------|-------|
| Scope discipline  | 100 | Single probe fix + new test. Wrapper file NOT touched (it was documented + intentional). |
| Acceptance gate   | 100 | Bead asked to address wired-but-cold gap; root-cause fix delivers it + any future SKILL.md-documented scripts. |
| Reservation       | 90  |  |
| Pathspec staging  | 100 |  |
| L112 probe        | 100 |  |
| Mission fitness   | 95  | Direct — probe accuracy is fleet-substrate quality |
| Evidence presence | 100 |  |
| Sniff             | 100 | Bug-shape correction: documented-compat-wrapper, not dead code |
| Doctrinal align   | 100 | N=3 of bead-hypothesis-is-prior-not-posterior META-RULE this session; Meadows #5 leverage applied |
| Brand             | 95  | ~55-line probe patch + 5/5 regression test |

## Skill discoveries
- pattern-recurrence (N=3): bead-hypothesis-is-starting-point-not-conclusion. Three consecutive beads (o40x0, 2xdi.47, 2xdi.49) all had bead hypothesis → investigation reveals different root cause → fix at the actual property. META-RULE already memorized; this is the 3rd applied instance.
- pattern-emerged: "documentation-as-wiring" — when a script is referenced in SKILL.md (its own or another skill's docs), the documentation IS evidence of wiring. Probe corpora should include canonical documentation surfaces (SKILL.md), not just executable code paths.
