#!/usr/bin/env bash
set -euo pipefail

VERSION="ntm-wave2-native-probes/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="${NTM_WAVE2_SESSION:-flywheel}"
TASK_TITLE="${NTM_WAVE2_TASK_TITLE:-flywheel native surface probe}"

usage() {
  cat <<'USAGE'
usage: ntm-wave2-native-probes.sh <surface> [--json]
surfaces: agents analytics cass config extract get-all-session-text memory resume
USAGE
}

json_or_null() {
  local tmp rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/ntm-wave2.XXXXXX")"
  set +e
  "$@" >"$tmp" 2>/dev/null
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]] && jq -e . "$tmp" >/dev/null 2>&1; then
    jq -c . "$tmp"
  else
    printf 'null\n'
  fi
  rm -f "$tmp"
}

surface_agents() {
  local profiles stats recommendation
  profiles="$(json_or_null "$NTM_BIN" agents list --json)"
  stats="$(json_or_null "$NTM_BIN" agents stats --json)"
  recommendation="$(json_or_null "$NTM_BIN" agents recommend --title "$TASK_TITLE" --type task --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "agents" \
    --argjson profiles "$profiles" \
    --argjson stats "$stats" \
    --argjson recommendation "$recommendation" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm agents list --json","ntm agents stats --json","ntm agents recommend --json"],profiles:$profiles,stats:$stats,recommendation:$recommendation}'
}

surface_analytics() {
  local summary sessions prometheus
  summary="$(json_or_null "$NTM_BIN" analytics --format json --days 7 --json)"
  sessions="$(json_or_null "$NTM_BIN" analytics --format json --sessions --days 7 --json)"
  prometheus="$(json_or_null "$NTM_BIN" analytics --format prometheus --days 7 --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "analytics" \
    --argjson summary "$summary" \
    --argjson sessions "$sessions" \
    --argjson prometheus "$prometheus" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm analytics --format json --days 7 --json","ntm analytics --format json --sessions --json","ntm analytics --format prometheus --json"],summary:$summary,sessions:$sessions,prometheus:$prometheus}'
}

surface_cass() {
  local status search insights
  status="$(json_or_null "$NTM_BIN" cass status --json)"
  search="$(json_or_null "$NTM_BIN" cass search "substrate amnesia" --limit 5 --workspace "$PWD" --json)"
  insights="$(json_or_null "$NTM_BIN" cass insights --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "cass" \
    --argjson status_json "$status" \
    --argjson search "$search" \
    --argjson insights "$insights" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm cass status --json","ntm cass search --json","ntm cass insights --json"],cass_status:$status_json,search:$search,insights:$insights}'
}

surface_config() {
  local show validate diff
  show="$(json_or_null "$NTM_BIN" config show --json)"
  validate="$(json_or_null "$NTM_BIN" config validate --json)"
  diff="$(json_or_null "$NTM_BIN" config diff --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "config" \
    --argjson show "$show" \
    --argjson validate "$validate" \
    --argjson diff "$diff" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm config show --json","ntm config validate --json","ntm config diff --json"],show:$show,validate:$validate,diff:$diff}'
}

surface_extract() {
  local last bash_blocks all_blocks
  last="$(json_or_null "$NTM_BIN" extract "$SESSION" --last --json --lines 120)"
  bash_blocks="$(json_or_null "$NTM_BIN" extract "$SESSION" --last --lang bash --json --lines 120)"
  all_blocks="$(json_or_null "$NTM_BIN" extract "$SESSION" --json --lines 120)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "extract" \
    --arg session "$SESSION" \
    --argjson last "$last" \
    --argjson bash_blocks "$bash_blocks" \
    --argjson all_blocks "$all_blocks" \
    '{schema_version:$version,surface:$surface,status:"ok",session:$session,native_calls:["ntm extract <session> --last --json","ntm extract <session> --lang bash --json","ntm extract <session> --json"],last:$last,bash_blocks:$bash_blocks,all_blocks:$all_blocks}'
}

surface_get_all_session_text() {
  local full compact short
  full="$(json_or_null "$NTM_BIN" get-all-session-text --lines 10 --json)"
  compact="$(json_or_null "$NTM_BIN" get-all-session-text --compact --lines 10 --json)"
  short="$(json_or_null "$NTM_BIN" get-all-session-text --lines 3 --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "get-all-session-text" \
    --argjson full "$full" \
    --argjson compact "$compact" \
    --argjson short "$short" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm get-all-session-text --lines 10 --json","ntm get-all-session-text --compact --json","ntm get-all-session-text --lines 3 --json"],full:$full,compact:$compact,short:$short}'
}

surface_memory() {
  local context outcome_privacy privacy
  context="$(json_or_null "$NTM_BIN" memory context "$TASK_TITLE" --json)"
  privacy="$(json_or_null "$NTM_BIN" memory privacy --json)"
  outcome_privacy="$(json_or_null "$NTM_BIN" memory context "callback validation substrate memory" --json)"
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "memory" \
    --argjson context "$context" \
    --argjson privacy "$privacy" \
    --argjson outcome_privacy "$outcome_privacy" \
    '{schema_version:$version,surface:$surface,status:"ok",native_calls:["ntm memory context <task> --json","ntm memory privacy --json","ntm memory context callback-validation --json"],context:$context,privacy:$privacy,callback_context:$outcome_privacy}'
}

surface_resume() {
  local latest dry explicit
  latest="$(json_or_null "$NTM_BIN" resume "$SESSION" --dry-run --json)"
  dry="$(json_or_null "$NTM_BIN" resume "$SESSION" --dry-run --json)"
  if [[ -n "${NTM_WAVE2_HANDOFF_FILE:-}" ]]; then
    explicit="$(json_or_null "$NTM_BIN" resume --from "$NTM_WAVE2_HANDOFF_FILE" --dry-run --json)"
  else
    explicit='null'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --arg surface "resume" \
    --arg session "$SESSION" \
    --argjson latest "$latest" \
    --argjson dry "$dry" \
    --argjson explicit "$explicit" \
    '{schema_version:$version,surface:$surface,status:"ok",session:$session,native_calls:["ntm resume <session> --dry-run --json","ntm resume <session> --dry-run --json","ntm resume --from <file> --dry-run --json"],latest:$latest,dry_run:$dry,explicit:$explicit}'
}

SURFACE="${1:-}"; [[ $# -gt 0 ]] && shift || true
JSON_OUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$SURFACE" in
  agents) payload="$(surface_agents)" ;;
  analytics) payload="$(surface_analytics)" ;;
  cass) payload="$(surface_cass)" ;;
  config) payload="$(surface_config)" ;;
  extract) payload="$(surface_extract)" ;;
  get-all-session-text) payload="$(surface_get_all_session_text)" ;;
  memory) payload="$(surface_memory)" ;;
  resume) payload="$(surface_resume)" ;;
  --help|-h|"") usage; exit 0 ;;
  *) echo "unknown surface: $SURFACE" >&2; usage >&2; exit 2 ;;
esac

if [[ "$JSON_OUT" == "1" ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"\(.surface) status=\(.status)"' <<<"$payload"
fi
