# flywheel-kvt8v Evidence Pack

## Summary

- Patched `.flywheel/scripts/build-dispatch-packet.sh` so canonical generated DONE, BLOCKED, and DECLINED callback contracts include `evidence_redacted`.
- Added `tests/build-dispatch-packet-evidence-redacted.sh` to prevent callback contract drift.
- Patched `/Users/josh/.claude/commands/flywheel/tick.md` callback boilerplate so peer tick-authored callbacks emit `evidence_redacted=<yes|no|n/a>`.
- Sent adoption-probe callbacks to `mobile-eats`, `alpsinsurance`, and `skillos`; fresh history probes recorded one delivered `evidence_redacted=yes` callback per target.

## Commands

```bash
ntm history --session mobile-eats --limit 200 --json > .flywheel/receipts/flywheel-kvt8v/mobile-eats-history.json
ntm history --session alpsinsurance --limit 200 --json > .flywheel/receipts/flywheel-kvt8v/alpsinsurance-history.json
ntm history --session skillos --limit 200 --json > .flywheel/receipts/flywheel-kvt8v/skillos-history.json
bash -n .flywheel/scripts/build-dispatch-packet.sh
bash -n tests/build-dispatch-packet-evidence-redacted.sh
tests/build-dispatch-packet-evidence-redacted.sh
tests/validate-callback.sh
.flywheel/validation-schema/v1/dispatch-template-audit.sh /var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-kvt8v.XXXXXX.gZ5p0wWMnB/packet-proof/dispatch_flywheel-kvt8v-proof.md
```

## Adoption Probe Results

Each command below returned `1`. The query filters out failed `ntm send` rows by requiring an empty `error` field.

```bash
jq -r '[.. | objects | select((.prompt? // "") | contains("flywheel-kvt8v-evidence-redacted-adoption-probe-v2")) | select((.prompt? // "") | test("evidence_redacted=yes")) | select(((.error? // "") == ""))] | length' .flywheel/receipts/flywheel-kvt8v/mobile-eats-history.json
jq -r '[.. | objects | select((.prompt? // "") | contains("flywheel-kvt8v-evidence-redacted-adoption-probe-v2")) | select((.prompt? // "") | test("evidence_redacted=yes")) | select(((.error? // "") == ""))] | length' .flywheel/receipts/flywheel-kvt8v/alpsinsurance-history.json
jq -r '[.. | objects | select((.prompt? // "") | contains("flywheel-kvt8v-evidence-redacted-adoption-probe-v2")) | select((.prompt? // "") | test("evidence_redacted=yes")) | select(((.error? // "") == ""))] | length' .flywheel/receipts/flywheel-kvt8v/skillos-history.json
```

Probe callback body observed in all three target sessions:

```text
Callback: task_id=flywheel-kvt8v-evidence-redacted-adoption-probe-v2 status=done source_session=flywheel source_worker=CloudyMill evidence=/Users/josh/Developer/flywheel/.flywheel/receipts/flywheel-kvt8v/evidence.md evidence_redacted=yes tests=PASS adoption_probe=true no_repo_mutation=true
```

Note: `mobile-eats:1` was in tmux copy-mode and rejected the v2 send with `not in a mode`, so the delivered v2 adoption probe landed on idle `mobile-eats:3` with `callback_target_workaround=mobile-eats-pane1-copy-mode`.

## Redaction Scan

```bash
gitleaks detect --no-git --source .flywheel/receipts/flywheel-kvt8v --redact --no-banner
```

Result: `no leaks found`.

## Validator Output

`tests/validate-callback.sh`:

```text
Summary: 30 passed, 0 failed
```

The fixture includes the evidence-class acceptance path:

- `dwavb evidence-class reservation requires redacted yes`
- `dwavb missing evidence_redacted blocks evidence close`
- `dwavb evidence_redacted no returns remediation`
- `dwavb n/a rejected for evidence-class paths`

## Dispatch Template Audit

`.flywheel/validation-schema/v1/dispatch-template-audit.sh` returned:

```json
{"valid": true, "schema": "dispatch-template-validation/v1", "files_checked": 1}
```

The generated proof packet is copied to `.flywheel/receipts/flywheel-kvt8v/dispatch_flywheel-kvt8v-proof.md`.

## Four-Lens Self-Grade

brand: 8
sniff: 8
jeff: 8
public: 8

Three Judges: skeptical operator can rerun the exact commands, maintainer can inspect a two-file repo diff plus one global template line, and future worker gets a regression test for the callback contract.
