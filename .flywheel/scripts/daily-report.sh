#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PYTHON_REPORT="$SCRIPT_DIR/daily-report.py"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
REPO="$PWD"; SESSION="${FLYWHEEL_DAILY_REPORT_SESSION:-}"; WANT_JSON=0; PASSTHRU=0
PY_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; PY_ARGS+=("$1" "$2"); shift 2 ;;
    --repo=*) REPO="${1#--repo=}"; PY_ARGS+=("$1"); shift ;;
    --session) SESSION="$2"; shift 2 ;;
    --session=*) SESSION="${1#--session=}"; shift ;;
    --json) WANT_JSON=1; PY_ARGS+=("$1"); shift ;;
    --schema|--info|--examples) PASSTHRU=1; PY_ARGS+=("$1"); shift ;;
    *) PY_ARGS+=("$1"); shift ;;
  esac
done
[[ "$PASSTHRU" -eq 0 ]] || exec python3 "$PYTHON_REPORT" "${PY_ARGS[@]}"

REPO="$(cd "$REPO" && pwd -P)"
SESSION="${SESSION:-$(basename "$REPO")}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/daily-report-ntm.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT

json_probe() {
  local env_name="$1" file_env_name="$2" raw; shift 2
  if [[ -n "${!env_name:-}" ]]; then raw="${!env_name}"
  elif [[ -n "${!file_env_name:-}" ]]; then raw="$(cat "${!file_env_name}" 2>/dev/null || true)"
  else raw="$("$@" 2>/dev/null || true)"
  fi
  jq -e . >/dev/null 2>&1 <<<"$raw" && printf '%s\n' "$raw" || printf '{}\n'
}

ANALYTICS="$(json_probe NTM_ANALYTICS_JSON NTM_ANALYTICS_JSON_FILE "$NTM" analytics --days 1 --format json)"
SUMMARY="$(json_probe NTM_SUMMARY_JSON NTM_SUMMARY_JSON_FILE "$NTM" summary "$SESSION" --since 24h --json)"
BUGS="$(json_probe NTM_BUGS_JSON NTM_BUGS_JSON_FILE "$NTM" bugs summary "$REPO" --json)"
SCAN="$(json_probe NTM_SCAN_JSON NTM_SCAN_JSON_FILE "$NTM" scan "$REPO" --json --dry-run --timeout "${NTM_SCAN_TIMEOUT:-30}")"
ROLLUP="$(jq -nc --arg session "$SESSION" --argjson analytics "$ANALYTICS" --argjson summary "$SUMMARY" --argjson bugs "$BUGS" --argjson scan "$SCAN" '
def n($x): (($x // 0) | tonumber? // 0);
def t($x): {critical:n($x.critical//$x.totals.critical//$x.summary.critical//$x.scan.totals.critical),warning:n($x.warning//$x.totals.warning//$x.summary.warning//$x.scan.totals.warning),info:n($x.info//$x.totals.info//$x.summary.info//$x.scan.totals.info)};
{session:$session,analytics_totals:($analytics.summary//$analytics.totals//$analytics),per_agent_rollup:(($summary.agents//$summary.agent_summaries//$summary.per_agent//[])|if type=="array" then . else [] end),ubs_counts:{bugs:t($bugs),scan:t($scan),combined:{critical:(t($bugs).critical+t($scan).critical),warning:(t($bugs).warning+t($scan).warning),info:(t($bugs).info+t($scan).info)}}}')"

PY_OUT="$TMP/python.out"
python3 "$PYTHON_REPORT" "${PY_ARGS[@]}" >"$PY_OUT"
REPORT_PATH="$(jq -r '.report_path // empty' "$PY_OUT" 2>/dev/null || head -n 1 "$PY_OUT")"
if [[ -f "$REPORT_PATH" ]]; then
  {
    printf '\n## Native NTM rollup\n'
    jq -r '"- session: \(.session)\n- per_agent_rollup_count: \(.per_agent_rollup|length)\n- ubs_bugs: critical=\(.ubs_counts.bugs.critical) warning=\(.ubs_counts.bugs.warning) info=\(.ubs_counts.bugs.info)\n- ubs_scan: critical=\(.ubs_counts.scan.critical) warning=\(.ubs_counts.scan.warning) info=\(.ubs_counts.scan.info)"' <<<"$ROLLUP"
  } >>"$REPORT_PATH"
fi

if [[ "$WANT_JSON" -eq 1 ]]; then
  jq -c --argjson ntm_rollup "$ROLLUP" '. + {ntm_rollup:$ntm_rollup}' "$PY_OUT"
else
  cat "$PY_OUT"
fi
