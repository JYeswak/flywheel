# flywheel-2bd2r.1 compliance pack

## Scope

Patch `tmp-aggressive-prune.sh` so dry-run JSON survives sample-size failures.

## Evidence

- Socraticode survey: 10 queries, 100 chunks observed.
- Commit: pending at receipt creation.
- Reserved paths:
  - `.flywheel/scripts/tmp-aggressive-prune.sh`
  - `tests/test-tmp-aggressive-prune.sh`
  - `.flywheel/receipts/flywheel-2bd2r.1/sample-size-json-hotfix.md`
  - `.flywheel/receipts/flywheel-2bd2r.1/compliance-pack.md`
  - `.beads/issues.jsonl`

## Verification

```text
bash -n .flywheel/scripts/tmp-aggressive-prune.sh tests/test-tmp-aggressive-prune.sh
bash tests/test-tmp-aggressive-prune.sh
.flywheel/scripts/tmp-aggressive-prune.sh --max-mtime-days 1 --dry-run --json
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2bd2r.1-4448db.md
br show flywheel-2bd2r.1 --json
```

## L52 Receipt

`no_bead_reason=no_new_gap_sample_size_failure_covered`

## L61

No doctrine, INCIDENTS, canonical L-rule, skill, README, or AGENTS surface was
edited. This was a script/test hotfix for a named follow-up bead.

## Score

`compliance_score=930/1000`
