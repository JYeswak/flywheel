# Naming Convention Gate

Created: 2026-05-12T23:05Z
Primary downstream concern: public-share naming polish across B11/B12/B13/B15.

## Why This Exists

Joshua approved the charter and then tightened the publication requirement:
Flywheel should not read like generic infrastructure. A business owner may land
on the GitHub repo from social media and needs confidence that ZestStream knows
how to operate advanced AI work safely. A technical reader needs stable names
for the engine, method, proof surfaces, and upstream substrate.

Earlier Yuzu naming work already exists, but it was marked promotion-pending:

- `.flywheel/doctrine/naming-convention-distinguishable-ownership.md`
- `.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md`
- `.flywheel/doctrine/scope-aware-rename-domain-collision-protection.md`
- `.flywheel/rules/L101-L150-skill-naming-constraint.md`

For publication, this becomes a gate: document the naming contract now, defer
broad renames until the wire-or-explain and scope-aware machinery can coordinate
them safely.

## Public Contract

The public naming contract now lives at:

```text
docs/brand/naming-conventions.md
```

Focused proof:

```bash
bash tests/naming-conventions.sh
```

The test verifies:

- canonical roles for ZestStream, Flywheel, Yuzu Method, SkillOS, ZestTube, and
  Jeff/Dicklesworthstone substrate;
- live links to the three internal naming/rename doctrines;
- explicit domain-collision guard for `doctor`, `ledger`, `worker`,
  `dispatch`, `tick`, and `reap`;
- no stale `PROMOTION-PENDING` or old email marker in the public naming doc.

## Closeout Implication

B11/B12/B13/B15 should not close on public copy unless the naming contract is
referenced or the relevant surface passes an equivalent naming review.

This document does not authorize a repo-wide Yuzu rename. Any mechanical rename
must follow cross-repo wire-or-explain discovery and scope-aware apply rules.
