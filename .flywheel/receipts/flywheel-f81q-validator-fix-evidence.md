---
schema_version: flywheel-validator-fix-evidence/v1
contract_version: four-lens-close-validator/v1
receipt_schema_version: four-lens-close-validator/v1
---

# flywheel-f81q validator-fix evidence

task_id: flywheel-f81q
bead: flywheel-f81q
did=7/7 didnt=none gaps=none tests=PASS
socraticode_queries=4
indexed_chunks_observed=40

## Acceptance gates

| gate | result | evidence |
|---|---|---|
| Read validator envelope path | PASS | `.flywheel/scripts/validate-callback-before-close.sh` had no `--envelope` option and only emitted four-lens JSON before this patch. |
| Add structural did/total check | PASS | Validator now accepts `--envelope TEXT`, parses `did=N/M`, and fails close when `N<M` or `didnt` is not `none`. |
| Emit structural fields | PASS | JSON now includes `validator_structural_pass`, `envelope_did_total_mismatch`, and a `structural` object with source, did, didnt, gaps, and mismatch. |
| Add regression fixture | PASS | `tests/test_four_lens_validator_did_total_structural.sh` proves `did=5/9` blocks even while brand/sniff/Jeff/public all pass. |
| Synthetic did<total caught | PASS | `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/f81q.XXXXXX.3LCnDWiW6o/synthetic-did-5-of-9.json` reports `BLOCK_CLOSE`, `validator_structural_pass=false`, and `envelope_did_total_mismatch=5/9`. |
| Synthetic did=total passes | PASS | `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/f81q.XXXXXX.3LCnDWiW6o/synthetic-did-9-of-9.json` reports `SAFE_TO_CLOSE`, `validator_structural_pass=true`, and no mismatch. |
| Existing validator fixtures still pass | PASS | `tests/validate-callback-before-close.sh`, `tests/test_four_lens_jeff_version_contract_pass.sh`, `tests/test_four_lens_jeff_version_contract_fail.sh`, and the Bash 3.2 compatibility fixture passed. |

## Files changed

- `.flywheel/scripts/validate-callback-before-close.sh`
- `tests/test_four_lens_validator_did_total_structural.sh`
- `.flywheel/receipts/flywheel-f81q-validator-fix-evidence.md`

## Commands run

```bash
bash -n .flywheel/scripts/validate-callback-before-close.sh tests/test_four_lens_validator_did_total_structural.sh
# PASS

bash tests/test_four_lens_validator_did_total_structural.sh
# PASS: four-lens validator did-total structural

bash tests/validate-callback-before-close.sh
# PASS: validate-callback-before-close

bash tests/test_four_lens_jeff_version_contract_pass.sh
# PASS: four-lens Jeff version contract pass fixture

bash tests/test_four_lens_jeff_version_contract_fail.sh
# PASS: four-lens Jeff contract marker fail fixture

/bin/bash tests/test_four_lens_validator_bash_3_2_compat.sh
# SUMMARY pass=8 fail=0

.flywheel/scripts/validate-callback-before-close.sh --repo "$repo" --bead "$bead" --evidence "$evidence" --envelope "DONE fixture did=5/9 didnt=4 continuation=test-followup tests_passing=true validator_brand_pass=true validator_sniff_pass=true validator_jeff_pass=true validator_public_pass=true" --json
# rc=1; BLOCK_CLOSE structural=false mismatch=5/9

.flywheel/scripts/validate-callback-before-close.sh --repo "$repo" --bead "$bead" --evidence "$evidence" --envelope "DONE fixture did=9/9 didnt=none continuation=none tests_passing=true validator_brand_pass=true validator_sniff_pass=true validator_jeff_pass=true validator_public_pass=true" --json
# rc=0; SAFE_TO_CLOSE structural=true mismatch=none
```

## Four-Lens Self-Grade

Brand voice: PASS. The change upgrades a close gate with a small structural rule and a receipt fixture; it does not rely on callback optimism.

Sniff / Three Judges: PASS. Jeffrey sees a concrete versioned contract gate in `validate-callback-before-close.v1.1.0`; Donella sees a rule that changes the information flow before bead close; Joshua sees the 25-year operations manager pattern: did=5/9 with all-PASS lens is the rubber-stamp drift signal, and every silenced partial becomes tomorrow's broken regression.

Jeff doctrine: PASS. The evidence is runnable and version-marked: `contract_version=four-lens-close-validator/v1`, JSON fields are named, and the fixture proves the exact failure mode.

Public publishability: PASS. A public reviewer can fork this because the behavior is easy to inspect: one flag, one structural field, one failing synthetic envelope, one passing synthetic envelope, and an executable test. Outcome: the validator refuses APPROVE_CLOSE on partial work even when brand, sniff, Jeff, and public lenses all pass.
