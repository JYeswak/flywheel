# flywheel-cg0mr Compliance Pack

## Scope
- Bead: `flywheel-cg0mr`
- Task: verify fleet callback adoption of `evidence_redacted=yes|no|n/a` after `flywheel-dwavb`.
- Target sessions: `mobile-eats:1`, `alpsinsurance:1`, `skillos:1`.

## Result
- Doctrine/rule sync evidence is present in all three peer repos.
- Worker callback adoption is not present in the observed NTM history sample.
- Follow-up bead filed: `flywheel-kvt8v`.
- Broad `sync-canonical-doctrine --apply` was not run.

## Evidence
- `flywheel-dwavb` closed at `2026-05-09T03:46:43.879649Z`.
- Peer repo doctrine/rule mentions:
  - `mobile-eats`: 2 files under `.flywheel/doctrine` / `.flywheel/rules`
  - `alpsinsurance`: 2 files under `.flywheel/doctrine` / `.flywheel/rules`
  - `skillos`: 2 files under `.flywheel/doctrine` / `.flywheel/rules`
- Callback history probes:
  - `mobile-eats`: `callback_strings=249`, `callback_strings_with_evidence_redacted=0`
  - `alpsinsurance`: `callback_strings=261`, `callback_strings_with_evidence_redacted=0`
  - `skillos`: `callback_strings=141`, `callback_strings_with_evidence_redacted=0`

## Commands
```bash
br show flywheel-cg0mr
br dep tree flywheel-cg0mr

for repo in /Users/josh/Developer/mobile-eats /Users/josh/Developer/alpsinsurance /Users/josh/Developer/skillos; do
  printf '%s ' "$(basename "$repo")"
  rg -l "evidence_redacted" "$repo/.flywheel/doctrine" "$repo/.flywheel/rules" 2>/dev/null | wc -l | tr -d ' '
done

for s in mobile-eats alpsinsurance skillos; do
  /Users/josh/.local/bin/ntm history --session "$s" --limit 200 --json |
    jq -r '.. | strings? // empty' |
    awk -v session="$s" 'BEGIN{callbacks=0; redacted=0} /(^|[[:space:]])(DONE|BLOCKED|DECLINED)([[:space:]]|$)|Callback: task_id/ {callbacks++; if ($0 ~ /evidence_redacted=/) redacted++} END{printf "%s callback_strings=%d callback_strings_with_evidence_redacted=%d\n", session, callbacks, redacted}'
done

bash .flywheel/receipts/flywheel-dwavb/l112-probe.sh
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-cg0mr-295767.md
```

## Validator Gate
- `bash .flywheel/receipts/flywheel-dwavb/l112-probe.sh`
- Output: `L112_PASS_flywheel-dwavb_evidence_redacted_contract`
- This proves the local validator requires `evidence_redacted=yes` for evidence-class reservation paths.

## L52 Disposition
- `beads_filed=flywheel-kvt8v`
- Reason: peer callback authoring surfaces still emit callback strings without the `evidence_redacted` field despite synced doctrine/rule text.

## Four-Lens Self-Grade
- brand: 8
- sniff: 9
- jeff: 9
- public: 8
