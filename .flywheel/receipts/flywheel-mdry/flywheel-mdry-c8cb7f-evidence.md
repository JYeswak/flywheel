# flywheel-mdry-c8cb7f evidence receipt

Bead: `flywheel-mdry`
Status before close evidence: `open`
Evidence redacted: `yes`

## Result

Routed decision processing was verified without printing token values.

## Commands Run

```bash
br show flywheel-mdry --json
br dep tree flywheel-mdry
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-mdry-c8cb7f.md
sqlite3 -json ~/.local/share/mcp_agent_mail/storage.sqlite3 'select m.id, a.name as sender, m.topic, m.subject, m.importance, m.ack_required, m.created_ts from messages m join agents a on a.id=m.sender_id where m.project_id=11 and m.id=42;'
sqlite3 -json ~/.local/share/mcp_agent_mail/storage.sqlite3 'select mr.message_id, a.name as recipient, mr.kind, mr.read_ts, mr.ack_ts from message_recipients mr join agents a on a.id=mr.agent_id where mr.message_id=42 order by a.name;'
jq -s '[.[] | select(.event=="notification_status_update" and .task_id=="foggybear-vault-wire-2026_05_03")] | {count:length, target_skill_ids:map(.target_skill_id), candidate_domains:map(.candidate_domain), statuses:map(.notification_status // .new_notification_status // .status // null)}' ~/.local/state/flywheel/skillos-routed.jsonl
br show flywheel-vd2c --json
br show flywheel-a2eo --json
timeout 10 jsm --json search meta-graph-publishing --limit 5
timeout 10 jsm --json search x-api-saas-posting --limit 5
timeout 10 jsm --json search google-youtube-workspace-oauth --limit 5
```

## Redacted Facts

- Agent Mail message `42` was sent by `FoggyBear` to `LavenderGlen` with topic `skillos-routed-decisions`, `importance=high`, and `ack_required=1`.
- The message `42` recipient row has non-null read and ack timestamps.
- Five routed rows exist for `foggybear-vault-wire-2026_05_03`.
- Three candidates have matching local skill directories: `meta-graph-publishing`, `x-api-saas-posting`, `google-youtube-workspace-oauth`.
- Two priority-3 update beads exist and are closed: `flywheel-vd2c`, `flywheel-a2eo`.
- Bounded live `jsm search` attempts timed out; no token or credential material was printed.

## Acceptance

- AG1: pass
- AG2: pass
- AG3: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
