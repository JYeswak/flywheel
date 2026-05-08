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
    jq -nc '{agents:[{pane_idx:1,agent_type:"claude",state:"WAITING",detected_patterns:["ready"]}]}'
    ;;
  *) printf 'unexpected ntm call: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

cat >"$TMP/pws" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'PWS should not be called for non-codex panes\n' >&2
exit 9
SH
chmod +x "$TMP/pws"

out="$(NTM="$TMP/ntm" PANE_WORK_SIGNAL_BIN="$TMP/pws" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --json)"
jq -e '.[0].state == "idle" and .[0].source == "ntm"' <<<"$out" >/dev/null
text="$(NTM="$TMP/ntm" PANE_WORK_SIGNAL_BIN="$TMP/pws" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --text)"
grep -q 'source=ntm' <<<"$text"

printf 'PASS status_marker_ntm\n'
