#!/usr/bin/env bash
# Surface unread Agent Mail messages to the flywheel tick prompt.
set -euo pipefail

SESSION="${SESSION:-flywheel}"
ORCH_PANE="${ORCH_PANE:-1}"
TOKEN_DIR="${AGENT_MAIL_TOKEN_DIR:-$HOME/.local/state/flywheel/agent-mail-tokens}"
DB_PATH="${AGENT_MAIL_DB_PATH:-$HOME/.local/share/mcp_agent_mail/storage.sqlite3}"
LIMIT="${INBOX_CHECK_LIMIT:-10}"

case "$SESSION" in
  flywheel)
    IDENTITY="RubyCreek"
    PROJECT_KEY="/Users/josh/Developer/flywheel"
    ;;
  *)
    jq -nc --arg session "$SESSION" '{action:"noop",reason:"not_flywheel_session",session:$session}'
    exit 0
    ;;
esac

TOKEN_FILE="$TOKEN_DIR/$(printf '%s' "$IDENTITY" | tr '[:upper:]' '[:lower:]').json"
if [[ ! -f "$TOKEN_FILE" ]]; then
  jq -nc --arg identity "$IDENTITY" --arg path "$TOKEN_FILE" \
    '{action:"error",reason:"no_token_file",identity:$identity,token_file:$path}'
  exit 0
fi

if [[ ! -r "$DB_PATH" ]]; then
  jq -nc --arg identity "$IDENTITY" --arg db "$DB_PATH" \
    '{action:"error",reason:"db_unreadable",identity:$identity,db_path:$db}'
  exit 0
fi

if ! command -v jq >/dev/null 2>&1 || ! command -v sqlite3 >/dev/null 2>&1; then
  jq -nc --arg identity "$IDENTITY" '{action:"error",reason:"missing_jq_or_sqlite3",identity:$identity}'
  exit 0
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -lt 1 ]]; then
  LIMIT=10
fi

MESSAGES="$(
  sqlite3 -json "$DB_PATH" <<SQL
SELECT
  messages.id AS message_id,
  senders.name AS sender,
  messages.subject AS subject,
  substr(replace(replace(messages.body_md, char(10), ' '), char(13), ' '), 1, 500) AS body_excerpt,
  messages.created_ts AS created_ts,
  messages.importance AS importance,
  messages.ack_required AS ack_required,
  messages.thread_id AS thread_id
FROM message_recipients
JOIN agents AS recipients ON recipients.id = message_recipients.agent_id
JOIN projects ON projects.id = recipients.project_id
JOIN messages ON messages.id = message_recipients.message_id
JOIN agents AS senders ON senders.id = messages.sender_id
WHERE projects.human_key = '$PROJECT_KEY'
  AND recipients.name = '$IDENTITY'
  AND message_recipients.read_ts IS NULL
ORDER BY messages.created_ts ASC
LIMIT $LIMIT;
SQL
)"

COUNT="$(jq 'length' <<<"$MESSAGES" 2>/dev/null || printf '0')"
if [[ "${COUNT:-0}" -eq 0 ]]; then
  jq -nc \
    --arg identity "$IDENTITY" \
    --arg project_key "$PROJECT_KEY" \
    --arg session "$SESSION" \
    --arg pane "$ORCH_PANE" \
    '{action:"noop",reason:"no_unread",identity:$identity,project_key:$project_key,session:$session,orch_pane:($pane|tonumber? // $pane),unread_count:0}'
  exit 0
fi

jq -nc \
  --arg identity "$IDENTITY" \
  --arg project_key "$PROJECT_KEY" \
  --arg session "$SESSION" \
  --arg pane "$ORCH_PANE" \
  --argjson messages "$MESSAGES" \
  '{
    action:"surfaced",
    identity:$identity,
    project_key:$project_key,
    session:$session,
    orch_pane:($pane|tonumber? // $pane),
    unread_count:($messages | length),
    messages:$messages,
    auto_reply:false,
    operator_action:"For each message, decide in the orchestrator pane whether to reply via Agent Mail reply_message; if replying, also notify the sender session/pane with ntm send."
  }'
