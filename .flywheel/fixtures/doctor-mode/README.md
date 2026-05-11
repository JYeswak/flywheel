# doctor-mode fixture suite — 10 FMs (flywheel-oxzyr.2.6)

Real fixture data + round-trip tests for the 10 failure modes (FMs) covered
by flywheel-loop doctor mode. Sister deliverable to oxzyr.2.1 (chokepoint),
oxzyr.2.2 (`doctor undo`), oxzyr.2.3 (FM-5+FM-10), oxzyr.2.4 (FM-6+FM-9),
oxzyr.2.5 (FM-8).

## FM coverage matrix

| FM | Class | flywheel-loop doctor function | Test mode | Class |
|---|---|---|---|---|
| FM-1 | loop-state-without-driver | none (covered upstream / wire-status surface) | SKIPPED-fixture-ready | substrate-config |
| FM-2 | pulse-stale → DEAD misclassification | none (covered in pulse-log classifier) | SKIPPED-fixture-ready | classifier |
| FM-3 | stale-error preflight bypass | none (covered in preflight scope) | SKIPPED-fixture-ready | gating |
| FM-4 | callback Monitor not armed | none (covered in dispatch surface) | SKIPPED-fixture-ready | dispatch |
| FM-5 | stale-prompt time-heartbeat | `_flywheel_loop_fm5_detect_fix` (.2.3) | RUN | audit-only-retraction |
| FM-6 | legacy loop-config schema drift | `_flywheel_loop_fm6_detect_fix` (.2.4) | RUN+UNDO | byte-exact-undo |
| FM-7 | topology-resolved-pane mismatch | none (covered in session-topology resolver) | SKIPPED-fixture-ready | substrate-config |
| FM-8 | dispatch during input-deaf | `_flywheel_loop_fm8_detect_fix` (.2.5) | RUN | audit-only-retraction+quarantine |
| FM-9 | frozen-projection in templates | `_flywheel_loop_fm9_detect_fix` (.2.4) | RUN+UNDO | byte-exact-undo |
| FM-10 | stale-chevron false-positive | `_flywheel_loop_fm10_detect_fix` (.2.3) | RUN | audit-only-retraction |

## Fixture shape (per FM directory)

| File | Purpose |
|---|---|
| `README.md` | FM class + detect predicate + fix strategy + MEMORY source |
| `corrupt-<class>.<ext>` | Input demonstrating the failure mode |
| `expected-<class>.<ext>` | What a correct fix should produce (or quarantine-receipt shape for audit-only retraction FMs) |
| `undo-original.bak` | Byte-exact baseline used by byte-exact-undo round-trip (verifies `doctor undo <run-id>` restores `corrupt` exactly) |

## Round-trip protocol

Per spec at `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md`:

```
corrupt
  ↓ flywheel-loop doctor fmN --apply
applied (mutated state OR retraction-row written)
  ↓ assert outcome matches expected
healthy
  ↓ flywheel-loop doctor undo <run-id>  (byte-exact-undo class only)
restored
  ↓ byte-identical(corrupt, restored)   (verified via sha256 equality)
```

For audit-only-retraction FMs (FM-5, FM-8, FM-10), step 4 is N/A — those
FMs don't mutate substrate; the "undo" of an audit-only retraction is to
clear the retraction row (out of scope of this fixture suite).

## Runner

`.flywheel/tests/test-oxzyr.2.6-fm-fixtures-round-trip.sh` — single
bash invocation runs all 10 fixtures + reports per-FM PASS/SKIPPED/FAIL.

## Boundary

These fixtures are READ-ONLY references. The test runner copies each
`corrupt-*` to a scratch sandbox before mutating it, so the canonical
fixture stays byte-exact and re-runnable.

## Cross-references

- Repair spec: `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md`
- Sibling sub-bead audit packs: `.flywheel/audit/flywheel-oxzyr.2.{1..5}/`
- doctor-mode skill rubric: `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md`
