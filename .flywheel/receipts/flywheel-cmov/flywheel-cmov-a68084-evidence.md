# flywheel-cmov-a68084 evidence receipt

Bead: `flywheel-cmov`
Status before close evidence: `open`
Evidence redacted: `yes`

## Result

FoggyBear vault/routed-decision evidence was verified without printing token values.

## Commands Run

```bash
br show flywheel-cmov --json
br dep tree flywheel-cmov
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-cmov-a68084.md
bash .flywheel/scripts/fleet-mail-vault-doctor.sh
stat -f '%Lp %N' ~/.local/state/flywheel/fleet-mail-tokens/FoggyBear.token ~/.local/state/flywheel/fleet-mail-tokens/LavenderGlen.token
jq -s '[.[] | select(.event=="notification_status_update" and .task_id=="foggybear-vault-wire-2026_05_03")] | {count:length, target_skill_ids:map(.target_skill_id), notification_statuses:map(.notification_status // .new_notification_status // .status // null)}' ~/.local/state/flywheel/skillos-routed.jsonl
sqlite3 -json ~/.local/share/mcp_agent_mail/storage.sqlite3 'select m.id, a.name as sender, m.topic, m.subject, m.importance, m.ack_required, m.created_ts from messages m join agents a on a.id=m.sender_id where m.project_id=11 and m.id in (41,42);'
sqlite3 -json ~/.local/share/mcp_agent_mail/storage.sqlite3 'select mr.message_id, a.name as recipient, mr.kind, mr.read_ts, mr.ack_ts from message_recipients mr join agents a on a.id=mr.agent_id where mr.message_id in (41,42) order by mr.message_id, a.name;'
```

## Redacted Facts

- FoggyBear token path exists at the canonical vault location and mode is `600`.
- LavenderGlen token path exists at the canonical vault location and mode is `600`.
- Agent Mail message `41` is the FoggyBear-to-LavenderGlen smoke message and was read.
- Agent Mail message `42` carries topic `skillos-routed-decisions`, `ack_required=1`, and was read/acked by LavenderGlen.
- Five `notification_status_update` rows exist for `foggybear-vault-wire-2026_05_03`; all five have notification status `notified`.

## Acceptance

- AG1: pass
- AG2: pass
- AG3: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
