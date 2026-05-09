#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
routed="/Users/josh/.local/state/flywheel/skillos-routed.jsonl"
mail_db="/Users/josh/.local/share/mcp_agent_mail/storage.sqlite3"
skills="/Users/josh/.claude/skills"

cd "$repo"

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

for skill in meta-graph-publishing x-api-saas-posting google-youtube-workspace-oauth; do
  test -f "$skills/$skill/SKILL.md"
  grep -Eq "^name:[[:space:]]*$skill$" "$skills/$skill/SKILL.md"
done

br show flywheel-vd2c --json | jq -e '.[0].priority == 3 and .[0].status == "closed" and (.[0].close_reason | test("skill updated"))' >/dev/null
br show flywheel-a2eo --json | jq -e '.[0].priority == 3 and .[0].status == "closed" and (.[0].close_reason | test("skill updated"))' >/dev/null

printf 'pass\n'
