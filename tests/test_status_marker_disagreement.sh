#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t status-marker.XXXXXX)"
HELPER="$HOME/.claude/commands/flywheel/_shared/pane-state.sh"
cleanup() {
  find "$TMP" -type f -delete 2>/dev/null || true
  find "$TMP" -depth -type d -empty -delete 2>/dev/null || true
}
trap cleanup EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --robot-activity=*)
    jq -nc '{agents:[{pane_idx:2,agent_type:"codex",state:"WAITING",detected_patterns:["codex prompt"]}]}'
    ;;
  *) printf 'unexpected ntm call: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

cat >"$TMP/pws" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--classify" ]]; then
  jq -nc '{truth_state:"working",truth_source:"pane_work_signal",truth_reason:"foreground_working_structured_row"}'
else
  jq -nc '{truth_state:"working",foreground_working_state:true,foreground_working_evidence:"Working (47s) | fixture"}'
fi
SH
chmod +x "$TMP/pws"

out="$(NTM="$TMP/ntm" PANE_WORK_SIGNAL_BIN="$TMP/pws" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --json)"
jq -e '.[0].state == "working" and .[0].ntm_state == "idle" and .[0].source == "pws!=ntm"' <<<"$out" >/dev/null
text="$(NTM="$TMP/ntm" PANE_WORK_SIGNAL_BIN="$TMP/pws" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --text)"
grep -q 'source=pws!=ntm' <<<"$text"

printf 'PASS status_marker_disagreement\n'
