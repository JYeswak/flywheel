# flywheel-hctfn-953629 Evidence

## Changes

- Updated `.flywheel/scripts/build-dispatch-packet.sh` to emit the current canonical dispatch contract from one materializer for operator and daemon flows.
- Wired `.flywheel/scripts/idle-pane-auto-dispatch.sh` to build auto-fired packets through `build-dispatch-packet.sh --dispatch-channel auto` instead of writing a minimal worker prompt.
- Updated `/Users/josh/.claude/commands/flywheel/dispatch.md` to call the materializer with `--dispatch-channel operator` and describe the current contract.

## Verification

```bash
bash -n .flywheel/scripts/build-dispatch-packet.sh .flywheel/scripts/idle-pane-auto-dispatch.sh
shellcheck .flywheel/scripts/build-dispatch-packet.sh .flywheel/scripts/idle-pane-auto-dispatch.sh
FLYWHEEL_PACKET_BUILT_AT=2026-05-08T00:00:00Z .flywheel/scripts/build-dispatch-packet.sh --bead-id flywheel-hctfn --target-pane 3 --target-session flywheel --task-id flywheel-hctfn-test --apply --json
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-hctfn-test.md
```

Result: PASS. Dispatch-template audit returned `valid=true`.

```bash
FLYWHEEL_PACKET_BUILT_AT=2026-05-08T00:00:00Z .flywheel/scripts/build-dispatch-packet.sh --bead-id flywheel-hctfn --target-pane 3 --target-session flywheel --task-id flywheel-hctfn-parity --dispatch-channel operator --output-dir /tmp/flywheel-hctfn-parity/operator --apply --json
FLYWHEEL_PACKET_BUILT_AT=2026-05-08T00:00:00Z .flywheel/scripts/build-dispatch-packet.sh --bead-id flywheel-hctfn --target-pane 3 --target-session flywheel --task-id flywheel-hctfn-parity --dispatch-channel auto --output-dir /tmp/flywheel-hctfn-parity/auto --apply --json
cmp -s /tmp/flywheel-hctfn-parity/operator/dispatch_flywheel-hctfn-parity.md /tmp/flywheel-hctfn-parity/auto/dispatch_flywheel-hctfn-parity.md
```

Result: PASS. Both packet bodies had SHA256 `8d22b149fe0ff9f35f92f54c8d0c48ab588fbd0e6d05d33141385b8c26090bfe`.

```bash
python3 .flywheel/scripts/validate-callback.py --repo /Users/josh/Developer/flywheel --dispatch-id flywheel-hctfn-compat --task-description 'flywheel-olhg-style callback josh_request_id=null' --callback-ref 'DONE flywheel-olhg ...' --json
```

Result: PASS. Validator returned `status=pass`, `schema_valid=true`, `integration_allowed=true`.

## Socraticode

- Queries: 3
- Indexed chunks observed: 1524
