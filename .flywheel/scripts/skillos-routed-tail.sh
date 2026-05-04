#!/usr/bin/env bash
# Tail skillos routing decisions without writing to skillos-owned routed JSONL.
set -euo pipefail

VERSION="2026-05-03"
ROUTED_FILE="${SKILLOS_ROUTED_PATH:-$HOME/.local/state/flywheel/skillos-routed.jsonl}"
MARKER_FILE="${SKILLOS_MARKER_PATH:-$HOME/.local/state/flywheel/skillos-routed-tail.last_seen}"

since=""
source_session=""
json=0
since_override=0
mode="run"

usage() {
  cat <<'EOF'
Usage: skillos-routed-tail.sh [--since <iso>] [--source-session <name>] [--json]

Options:
  --since <iso>              Read rows newer than this timestamp instead of marker.
  --source-session <name>    Filter rows that include matching source_session.
  --json                     Machine-readable summary with rows and decisions.
  --info                     Print version, paths, env defaults, and exit codes.
  --examples                 Print usage examples.
  --schema                   Emit output schema.
  --no-color                 Accepted for deterministic logs.
  --no-emoji                 Accepted for deterministic logs.
  --width <n>                Accepted for deterministic logs.

Exit codes:
  0 rows found
  1 no rows
  2 usage error
EOF
}

examples() {
  cat <<'EOF'
# Tick integration: read new skillos routing decisions and advance marker
skillos-routed-tail.sh --json

# Audit without touching marker
skillos-routed-tail.sh --since 2026-05-03T00:00:00Z --json

# Filter rows that carry source_session
skillos-routed-tail.sh --source-session flywheel --json
EOF
}

schema() {
  cat <<'EOF'
{
  "type": "object",
  "required": ["status", "count", "since", "routed_file", "marker_file", "rows", "decisions"],
  "properties": {
    "status": {"enum": ["rows_found", "no_rows"]},
    "count": {"type": "integer"},
    "since": {"type": "string"},
    "routed_file": {"type": "string"},
    "marker_file": {"type": "string"},
    "marker_advanced_to": {"type": ["string", "null"]},
    "rows": {"type": "array"},
    "decisions": {"type": "array", "items": {"type": "object"}}
  }
}
EOF
}

info() {
  if [ "$json" -eq 1 ]; then
    jq -nc --arg version "$VERSION" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{name:"skillos-routed-tail.sh", version:$version, routed_file:$routed_file, marker_file:$marker_file, exit_codes:{rows_found:0, no_rows:1, usage:2}}'
  else
    cat <<EOF
skillos-routed-tail.sh $VERSION
routed_file=$ROUTED_FILE
marker_file=$MARKER_FILE
env_overrides=SKILLOS_ROUTED_PATH,SKILLOS_MARKER_PATH
exit_codes=0 rows found; 1 no rows; 2 usage
EOF
  fi
}

die_usage() {
  echo "ERROR: $1" >&2
  usage >&2
  exit 2
}

need_value() {
  if [ "$#" -lt 2 ] || [[ "$2" == --* ]]; then
    die_usage "$1 requires a value"
  fi
}

safe_stamp() {
  date -u +%Y%m%dT%H%M%SZ
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --since=*) since="${1#*=}"; since_override=1; shift ;;
    --since) need_value "$@"; since="$2"; since_override=1; shift 2 ;;
    --source-session=*) source_session="${1#*=}"; shift ;;
    --source-session) need_value "$@"; source_session="$2"; shift 2 ;;
    --json) json=1; shift ;;
    --info) mode="info"; shift ;;
    --examples) mode="examples"; shift ;;
    --schema) mode="schema"; shift ;;
    --no-color|--no-emoji) shift ;;
    --width=*) shift ;;
    --width) need_value "$@"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

if [ "$mode" = "info" ]; then
  if [ "$json" -eq 1 ]; then
    command -v jq >/dev/null 2>&1 || die_usage "jq is required for --json"
  fi
  info
  exit 0
fi
if [ "$mode" = "examples" ]; then
  examples
  exit 0
fi
if [ "$mode" = "schema" ]; then
  schema
  exit 0
fi

command -v jq >/dev/null 2>&1 || die_usage "jq is required"

if [ -z "$since" ]; then
  if [ -f "$MARKER_FILE" ]; then
    since="$(tr -d '\n' < "$MARKER_FILE")"
  else
    since="1970-01-01T00:00:00Z"
  fi
fi

if [ ! -f "$ROUTED_FILE" ]; then
  if [ "$json" -eq 1 ]; then
    jq -nc --arg since "$since" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{status:"no_rows",count:0,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:null,rows:[],decisions:[]}'
  fi
  exit 1
fi

rows="$(jq -c --arg since "$since" --arg source_session "$source_session" '
  select((.ts // "") > $since)
  | select($source_session == "" or ((.source_session // .source_session_name // "") == $source_session))
' "$ROUTED_FILE" 2>/dev/null || true)"

count="$(printf '%s\n' "$rows" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$count" -eq 0 ]; then
  if [ "$json" -eq 1 ]; then
    jq -nc --arg since "$since" --arg routed_file "$ROUTED_FILE" --arg marker_file "$MARKER_FILE" \
      '{status:"no_rows",count:0,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:null,rows:[],decisions:[]}'
  fi
  exit 1
fi

rows_json="$(printf '%s\n' "$rows" | jq -s '.')"
decisions_json="$(printf '%s\n' "$rows" | jq -s '
  group_by((.decision // "unknown") + "\u0000" + ((.target_skill_id // "") | tostring))
  | map({decision:(.[0].decision // "unknown"), target_skill_id:(.[0].target_skill_id // null), count:length})
')"
max_ts="$(printf '%s\n' "$rows" | jq -r -s 'map(.ts // empty) | max // empty')"
marker_advanced_to="null"

if [ "$since_override" -eq 0 ] && [ -n "$max_ts" ]; then
  mkdir -p "$(dirname "$MARKER_FILE")"
  if [ -f "$MARKER_FILE" ]; then
    cp "$MARKER_FILE" "$MARKER_FILE.bak.$(safe_stamp)"
  fi
  tmp="$(mktemp "${MARKER_FILE}.tmp.XXXXXX")"
  printf '%s\n' "$max_ts" > "$tmp"
  mv "$tmp" "$MARKER_FILE"
  marker_advanced_to="$max_ts"
fi

if [ "$json" -eq 1 ]; then
  jq -nc \
    --arg status "rows_found" \
    --arg since "$since" \
    --arg routed_file "$ROUTED_FILE" \
    --arg marker_file "$MARKER_FILE" \
    --arg marker_advanced_to "$marker_advanced_to" \
    --argjson count "$count" \
    --argjson rows "$rows_json" \
    --argjson decisions "$decisions_json" \
    '{status:$status,count:$count,since:$since,routed_file:$routed_file,marker_file:$marker_file,marker_advanced_to:(if $marker_advanced_to == "null" then null else $marker_advanced_to end),rows:$rows,decisions:$decisions}'
else
  printf '%s\n' "$rows"
fi
