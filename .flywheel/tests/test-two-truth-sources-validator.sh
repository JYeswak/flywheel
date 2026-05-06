#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/two-truth-sources-validator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/two-truth-sources-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/two-truth-sources-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
outputs=()

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
pane="2"
for arg in "$@"; do
  case "$arg" in
    --panes=*) pane="${arg#*=}" ;;
  esac
done
chevron="$(printf '\342\200\272')"
case "${1:-}" in
  --robot-activity=*)
    case "${FAKE_ACTIVITY_MODE:-waiting}" in
      waiting)
        jq -nc --argjson pane "$pane" '{success:true,agents:[{pane_idx:$pane,agent_type:"codex",state:"WAITING",capture_provenance:"live",capture_collected_at:"2026-05-06T00:00:00Z",detected_patterns:["codex_chevron_prompt"]}],source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      error)
        jq -nc --argjson pane "$pane" '{success:true,agents:[{pane_idx:$pane,agent_type:"codex",state:"ERROR",capture_provenance:"live",capture_collected_at:"2026-05-06T00:00:00Z",detected_patterns:["failed_text","codex_chevron_prompt"]}],source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      thinking)
        jq -nc --argjson pane "$pane" '{success:true,agents:[{pane_idx:$pane,agent_type:"codex",state:"THINKING",capture_provenance:"live",capture_collected_at:"2026-05-06T00:00:00Z",detected_patterns:["codex_working"]}],source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      stale)
        jq -nc --argjson pane "$pane" '{success:true,agents:[{pane_idx:$pane,agent_type:"codex",state:"WAITING",capture_provenance:"stale",capture_collected_at:"2026-05-06T00:00:00Z"}],source_health:{tmux:{provenance:"stale",status:"stale"}}}'
        ;;
      fail)
        printf 'activity failed\n' >&2
        exit 42
        ;;
      *)
        printf 'unknown activity mode\n' >&2
        exit 2
        ;;
    esac
    ;;
  --robot-tail=*)
    case "${FAKE_TAIL_MODE:-chevron}" in
      chevron)
        jq -nc --argjson pane "$pane" --arg line "$chevron Ready for work" '{success:true,panes:{($pane|tostring):{state:"idle",lines:["prior line",$line]}},source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      reminder)
        jq -nc --argjson pane "$pane" '{success:true,panes:{($pane|tostring):{state:"idle",lines:["Improve documentation in @filename"]}},source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      no_chevron)
        jq -nc --argjson pane "$pane" '{success:true,panes:{($pane|tostring):{state:"idle",lines:["plain idle text"]}},source_health:{tmux:{provenance:"live",status:"fresh"}}}'
        ;;
      stale)
        jq -nc --argjson pane "$pane" --arg line "$chevron Ready for work" '{success:true,panes:{($pane|tostring):{state:"idle",lines:[$line]}},source_health:{tmux:{provenance:"stale",status:"stale"}}}'
        ;;
      fail)
        printf 'tail failed\n' >&2
        exit 43
        ;;
      *)
        printf 'unknown tail mode\n' >&2
        exit 2
        ;;
    esac
    ;;
  --robot-agent-health=*)
    jq -nc --arg pane "$pane" '{success:true,panes:{($pane):{agent_type:"cod",health_grade:"A",recommendation:"HEALTHY",issues:[]}}}'
    ;;
  *)
    printf 'unexpected fake ntm args: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

schema_validate() {
  local file="$1"
  python3 - "$SCHEMA" "$file" <<'PY'
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
payload = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(payload)
PY
}

run_case() {
  local label="$1" activity="$2" tail="$3" expected_rc="$4" jq_filter="$5" out rc
  out="$TMP/${label// /_}.json"
  set +e
  env \
    "FAKE_ACTIVITY_MODE=$activity" \
    "FAKE_TAIL_MODE=$tail" \
    "TWO_TRUTH_SOURCES_NTM=$TMP/ntm" \
    "TWO_TRUTH_SOURCES_LEDGER=$TMP/ledger.jsonl" \
    "$SCRIPT" check --session fixture --pane 2 --json >"$out" 2>"$out.err"
  rc=$?
  set -e
  outputs+=("$out")
  if [[ "$rc" == "$expected_rc" ]] && jq -e "$jq_filter" "$out" >/dev/null && schema_validate "$out"; then
    pass "$label"
  else
    fail "$label"
    printf 'rc=%s expected=%s stderr=%s\n' "$rc" "$expected_rc" "$(cat "$out.err")" >&2
    jq . "$out" >&2 || cat "$out" >&2
  fi
}

command -v jq >/dev/null 2>&1 || { fail "missing jq"; exit 1; }
bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --help >/dev/null && pass "help"
"$SCRIPT" --info | jq -e '.name == "two-truth-sources-validator.sh"' >/dev/null && pass "info_json"
"$SCRIPT" --examples | grep -q -- '--required-sources' && pass "examples"
jq empty "$SCHEMA" >/dev/null && pass "schema_json_parses"

run_case "allow waiting chevron" waiting chevron 0 '.decision == "allow" and .agreement == "agree" and .reason == "sources_agree_waiting_chevron" and .sources_probed == 2'
run_case "refuse waiting reminder" waiting reminder 1 '.decision == "refuse" and .reason == "capture_disagreement_reminder_template" and .sources_probed == 3'
run_case "refuse error clean chevron" error chevron 1 '.decision == "refuse" and .reason == "capture_disagreement_robot_activity_misclassification" and .sources_probed == 3'
run_case "refuse stale capture" stale chevron 1 '.decision == "refuse" and .reason == "stale_capture"'
run_case "refuse probe failure" fail chevron 1 '.decision == "refuse" and .reason == "probe_failure"'
run_case "refuse legitimate thinking" thinking no_chevron 1 '.decision == "refuse" and .reason == "pane_not_waiting"'

ledger_rows="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
if [[ "$ledger_rows" == "6" ]]; then
  pass "ledger row appended on every decision"
else
  fail "ledger row appended on every decision"
  cat "$TMP/ledger.jsonl" >&2 || true
fi

python3 - "$SCHEMA" "${outputs[@]}" <<'PY'
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validator = Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER)
for path in sys.argv[2:]:
    validator.validate(json.loads(Path(path).read_text(encoding="utf-8")))
PY
pass "JSON shape valid against schema"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
