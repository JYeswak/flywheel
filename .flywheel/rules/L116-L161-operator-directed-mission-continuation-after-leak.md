# L161 — OPERATOR-DIRECTED-MISSION-CONTINUATION-AFTER-LEAK

---
id: L161
title: Mission continuation after a leak requires operator direction and mitigation proof
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: mission-continued-after-leak-without-operator-proof
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md
ratification: .flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md
---

After a credential or irreversible-breach-class leak, the mission may continue
only when the operator directs continuation and the mitigation receipt exists.
"Operator-directed" means Joshua or an explicitly delegated human operator, not
an orchestrator deciding that a hook is clear enough to resume.

Rotation means actual credential replacement or tenant-specific containment
proof. A cache flush, pane restart, or prompt reset is not rotation.

## Flywheel application

Flywheel closeouts for leak-class incidents must separate three facts:

1. What halted.
2. What mitigation proof exists.
3. Who authorized continuation.

If any of those facts is missing, the bead remains blocked and the next safe
action is evidence collection or human decision, not a green close.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md`

