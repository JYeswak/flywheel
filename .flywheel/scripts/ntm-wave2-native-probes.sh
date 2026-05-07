#!/usr/bin/env bash
set -euo pipefail

VERSION="ntm-wave2-native-probes/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="${NTM_WAVE2_SESSION:-flywheel}"
TASK_TITLE="${NTM_WAVE2_TASK_TITLE:-flywheel native surface probe}"

usage() {
  cat <<'USAGE'
usage: ntm-wave2-native-probes.sh <surface> [--json]
surfaces: agents analytics
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
  --help|-h|"") usage; exit 0 ;;
  *) echo "unknown surface: $SURFACE" >&2; usage >&2; exit 2 ;;
esac

if [[ "$JSON_OUT" == "1" ]]; then
  printf '%s\n' "$payload"
else
  jq -r '"\(.surface) status=\(.status)"' <<<"$payload"
fi
