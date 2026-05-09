#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
vault="/Users/josh/.local/state/flywheel/fleet-mail-tokens"
routed="/Users/josh/.local/state/flywheel/skillos-routed.jsonl"
mail_db="/Users/josh/.local/share/mcp_agent_mail/storage.sqlite3"

cd "$repo"

[[ "$(stat -f '%Lp' "$vault/FoggyBear.token")" == "600" ]]
[[ "$(stat -f '%Lp' "$vault/LavenderGlen.token")" == "600" ]]

bash .flywheel/scripts/fleet-mail-vault-doctor.sh >/dev/null

jq -e -s '
  [.[] | select(.event == "notification_status_update" and .task_id == "foggybear-vault-wire-2026_05_03")]
  | length == 5
  and (map(.target_skill_id) | sort == [
      "google-youtube-workspace-oauth",
      "meta-graph-publishing",
      "nango-integrations",
      "railway-api+nango-integrations",
      "x-api-saas-posting"
    ])
  and all(.[]; (.notification_status // .new_notification_status // .status) == "notified")
' "$routed" >/dev/null

sqlite3 "$mail_db" "
select case when count(*) = 1 then 'ok' else 'missing' end
from messages m
join agents s on s.id=m.sender_id
join message_recipients mr on mr.message_id=m.id
join agents r on r.id=mr.agent_id
where m.project_id=11
  and m.id=41
  and s.name='FoggyBear'
  and r.name='LavenderGlen'
  and m.topic='foggybear-vault-wire'
  and mr.read_ts is not null;
" | grep -qx ok

sqlite3 "$mail_db" "
select case when count(*) = 1 then 'ok' else 'missing' end
from messages m
join agents s on s.id=m.sender_id
join message_recipients mr on mr.message_id=m.id
join agents r on r.id=mr.agent_id
where m.project_id=11
  and m.id=42
  and s.name='FoggyBear'
  and r.name='LavenderGlen'
  and m.topic='skillos-routed-decisions'
  and m.ack_required=1
  and mr.read_ts is not null
  and mr.ack_ts is not null;
" | grep -qx ok

printf 'pass\n'
