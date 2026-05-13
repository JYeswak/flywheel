# Loops

Flywheel treats AI-assisted work as a loop, not a chat transcript. A loop has a
goal, repo state, a safe next action, a doctor check, a work step, a receipt,
and a follow-up action.

The reduced public loop is:

```text
preflight -> init -> doctor -> tick -> dispatch or simulate -> validate receipt -> inspect
```

Full mode can add NTM panes, Agent Mail reservations, Socraticode searches,
Beads, and SkillOS capability checks. Reduced mode keeps the same shape without
requiring private fleet substrate.

The important rule is that a loop ends with evidence. If the doctor fails, the
receipt says why. If dispatch is simulated, the receipt says it was simulated.
If a lane is only a compatibility target, the public copy says so.
