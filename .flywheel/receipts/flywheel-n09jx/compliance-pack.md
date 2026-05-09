# flywheel-n09jx compliance pack

## Scope

Hotfix for P0 incident class: aggressive `/private/tmp` pruning removed a
socket directory entry and orphaned fleet sessions.

## Evidence

- Socraticode survey: 10 queries, 100 indexed chunks observed.
- Reservation paths:
  - `.flywheel/scripts/tmp-aggressive-prune.sh`
  - `tests/test-tmp-aggressive-prune.sh`
  - `.flywheel/receipts/flywheel-n09jx-tmux-socket-prune-hotfix.md`
  - `.flywheel/receipts/flywheel-n09jx/compliance-pack.md`
  - `.beads/issues.jsonl`
- L112 probe: `bash tests/test-tmp-aggressive-prune.sh`
- Live-safe probe: `.flywheel/scripts/tmp-aggressive-prune.sh --max-mtime-days 1 --dry-run --json`

## Verification

```text
bash -n .flywheel/scripts/tmp-aggressive-prune.sh
bash -n tests/test-tmp-aggressive-prune.sh
bash tests/test-tmp-aggressive-prune.sh
bash tests/test-tmp-prune.sh
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-n09jx-f5a22f.md
```

All verification commands passed.

## L52 Receipt

`no_bead_reason=no_new_gap_after_hotfix_and_fixture`

## L61

No doctrine, INCIDENTS, canonical L-rule, skill, README, or AGENTS surface was
edited. This was a script/test hotfix against an already-filed incident bead.

## Score

`compliance_score=930/1000`
