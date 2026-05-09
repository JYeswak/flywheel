# flywheel-2xdi.10 evidence receipt

Bead: `flywheel-2xdi.10`
Task: `flywheel-2xdi.10-94b069`
Evidence redacted: `yes`

## Result

Patched `.flywheel/scripts/gap-hunt-probe.sh` so the cross-source-silos scan does not re-file `gap-hunt-false-positives.jsonl` as an orphan ledger.

## Commands Run

```bash
br show flywheel-2xdi.10 --json
br dep tree flywheel-2xdi.10
ls -l /Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl
wc -l /Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl
tail -20 /Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl
bash -n .flywheel/scripts/gap-hunt-probe.sh
GAP_HUNT_AUTO_BEAD_CAP=0 .flywheel/scripts/gap-hunt-probe.sh --dry-run --json | jq -e '([.gaps_by_class["cross-source-silos"][]?.id] | index("cross-source-silos:gap-hunt-false-positives.jsonl") | not)'
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2xdi.10-94b069.md
bash .flywheel/receipts/flywheel-2xdi.10/l112-probe.sh
```

## Redacted Facts

- `gap-hunt-false-positives.jsonl` contains four 2026-05-03 false-positive rows.
- The probe already uses those rows conceptually as suppression guidance.
- The target ID `cross-source-silos:gap-hunt-false-positives.jsonl` is absent from current dry-run output after the patch.

## Acceptance

- AG1: pass
- AG2: pass
- AG3: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
