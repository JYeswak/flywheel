# Doctrine Update Broadcast

Session: `<target-session>`
Doctrine version: `<YYYY-MM-DD.LNNN>`
Canonical source: `/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md@<sha>`

## What Changed

- `<L-rule or skill delta 1>`
- `<L-rule or skill delta 2>`
- `<L-rule or skill delta 3>`

## Required Check

Run this from the target repo:

```bash
/Users/josh/.local/bin/flywheel-doctrine-sync \
  --target-repo "$PWD" \
  --dry-run \
  --json \
  | jq '{status,current_doctrine_version,proposed_doctrine_version,missing_l_rules_count,soft_violation}'
```

## Apply Path

Do not auto-apply from tick. If the orchestrator chooses to accept the doctrine
delta, apply one repo at a time:

```bash
/Users/josh/.local/bin/flywheel-doctrine-sync \
  --target-repo "$PWD" \
  --apply \
  --idempotency-key "<session>-doctrine-<YYYYMMDDTHHMMSSZ>" \
  --json
```

## Callback Shape

```text
DONE doctrine-sync session=<target-session> doctrine_version=<YYYY-MM-DD.LNNN> receipt=<path> compliance_pack_path=<path>
```
