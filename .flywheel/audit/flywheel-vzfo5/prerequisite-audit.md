# flywheel-vzfo5 (= flywheel-hzsro.4 split execution) — Prerequisite Audit

## Phase 4 contract (per .flywheel/audit/flywheel-hzsro/split-plan.md)

Per split-plan order-of-operations table line 235-236:
  flywheel-hzsro.3  →  fixture: identity.py parity contract  (~50 assertions)
  flywheel-hzsro.4  →  split:    identity.py → 6 sub-modules with re-export  (P2, depends on .3)

## Live prerequisite check

### .3 parity fixture present?
ls: /Users/josh/Developer/flywheel/.flywheel/tests/test-identity-py-parity.sh: No such file or directory

### .3 audit dir present?
ls: /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-hzsro.3/: No such file or directory

### identity.py current line count (target of split)
    1098 /Users/josh/.claude/skills/.flywheel/lib/portable/identity.d/identity.py

## Conclusion

Phase 3 fixture absent. Phase 4 split cannot execute safely — split-plan's
apply-gate requires "pre-split fixture passes AND post-split fixture passes
AND JSON shapes byte-equal". Without the fixture, byte-equality cannot be
asserted; any regression in the 32-function callable module's surface
would land silently.

Recommended path: orch dispatches flywheel-hzsro.3 first (or its execution
bead), then re-dispatches THIS bead (flywheel-vzfo5).
