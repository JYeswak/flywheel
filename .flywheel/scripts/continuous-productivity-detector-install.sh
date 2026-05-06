#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
DETECTOR="${CPD_DETECTOR:-$ROOT/.flywheel/scripts/continuous-productivity-detector.sh}"
LABEL="${CPD_LABEL:-ai.zeststream.continuous-productivity-detector}"
DOMAIN="${CPD_DOMAIN:-gui/$(id -u)}"
LAUNCH_AGENTS_DIR="${CPD_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
LEDGER="${CPD_LEDGER:-$HOME/.local/state/flywheel/continuous-productivity-escalations.jsonl}"
NTM="${CPD_NTM:-/Users/josh/.local/bin/ntm}"
LAUNCHCTL="${CPD_LAUNCHCTL:-launchctl}"
WATCHERS_BIN="${CPD_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
INTERVAL="${CPD_INTERVAL_SECONDS:-300}"
MODE="dry-run"
JSON=0
QUIET=0
NO_NOTIFY=0
usage() {
  cat <<'EOF'
usage: continuous-productivity-detector-install.sh [--apply|--dry-run] [--run-once] [--json] [--quiet] [--no-notify]
Installs a GUI-domain LaunchAgent that runs the continuous productivity
detector every five minutes. The detector is read-only; this runner owns local
ledger append, peer-orchestrator xpane send, and allowlisted Joshua notify.
EOF
}
info_json() {
  jq -nc --arg label "$LABEL" --arg domain "$DOMAIN" --arg plist "$PLIST" --arg detector "$DETECTOR" --arg ledger "$LEDGER" \
    '{schema_version:"continuous-productivity-detector-install/v1",label:$label,domain:$domain,plist:$plist,detector:$detector,ledger:$ledger,canonical_cli:["--info","--help","--examples","--json","--quiet"],gui_domain:($domain|startswith("gui/"))}'
}
examples() {
  cat <<EOF
$0 --dry-run --json
$0 --apply --json
$0 --run-once --json
EOF
}
write_plist() {
  mkdir -p "$LAUNCH_AGENTS_DIR" "$HOME/.local/logs" "$(dirname "$LEDGER")"
  python3 - "$PLIST" "$LABEL" "$SELF" "$INTERVAL" <<'PY'
import plistlib, sys
path, label, script, interval = sys.argv[1:5]
data = {
    "Label": label,
    "ProgramArguments": ["/bin/bash", script, "--run-once", "--quiet"],
    "StartInterval": int(interval),
    "RunAtLoad": False,
    "StandardOutPath": f"{__import__('os').path.expanduser('~')}/.local/logs/continuous-productivity-detector.out.log",
    "StandardErrorPath": f"{__import__('os').path.expanduser('~')}/.local/logs/continuous-productivity-detector.err.log",
}
with open(path, "wb") as handle:
    plistlib.dump(data, handle, sort_keys=False)
PY
}
append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$row" >>"$LEDGER"
}
run_once() {
  local tmp rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/continuous-productivity.XXXXXX")"
  set +e
  "$DETECTOR" --json >"$tmp"
  rc=$?
  set -e
  if [[ "$rc" -eq 1 ]]; then
    jq -c '.sessions[] | . as $s | $s.planned_actions[] | {ts:now|todateiso8601,event:"continuous_productivity_action",session:$s.session,productivity_state:$s.productivity_state,action:.}' "$tmp" |
      while IFS= read -r row; do
        append_ledger "$row"
        type="$(jq -r '.action.type' <<<"$row")"
        if [[ "$type" == "xpane_productivity_escalation" ]]; then
          session="$(jq -r '.session' <<<"$row")"
          pane="$(jq -r '.action.target_pane' <<<"$row")"
          prompt="$(mktemp "${TMPDIR:-/tmp}/continuous-productivity-prompt.XXXXXX")"
          jq -r '.action.message' <<<"$row" >"$prompt"
          "$NTM" send "$session" --pane="$pane" --no-cass-check --file "$prompt" >/dev/null
        elif [[ "$type" == "josh_notify" && "$NO_NOTIFY" -eq 0 ]]; then
          if command -v notify >/dev/null 2>&1; then
            notify "Flywheel blocker" "$(jq -r '.session + \" \" + .action.allowlist_class' <<<"$row")" || true
          fi
        fi
      done
  fi
  if [[ "$JSON" -eq 1 && "$QUIET" -eq 0 ]]; then
    cat "$tmp"
  fi
  rm -f "$tmp"
  return "$rc"
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply|--install) MODE="apply"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --run-once) MODE="run-once"; shift ;;
    --json) JSON=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --no-notify) NO_NOTIFY=1; shift ;;
    --info) info_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done
if [[ "$MODE" == "run-once" ]]; then
  run_once
  exit $?
fi
if [[ "$MODE" == "apply" ]]; then
  write_plist
  if [[ -x "$WATCHERS_BIN" ]]; then "$WATCHERS_BIN" register --label "$LABEL" --owner flywheel-orch --reason "continuous productivity detector" --bead flywheel-wire-flywheel-owns-continuous-productiv-5ad20901 --apply --idempotency-key "$LABEL" --json >/dev/null; fi
  "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" bootstrap "$DOMAIN" "$PLIST"
fi
if [[ "$JSON" -eq 1 ]]; then
  jq -nc --arg mode "$MODE" --arg label "$LABEL" --arg domain "$DOMAIN" --arg plist "$PLIST" --argjson interval "$INTERVAL" \
    '{schema_version:"continuous-productivity-detector-install/v1",mode:$mode,label:$label,domain:$domain,plist:$plist,interval_seconds:$interval,gui_domain:($domain|startswith("gui/")),would_bootstrap:($mode=="apply")}'
elif [[ "$QUIET" -eq 0 ]]; then
  printf 'label=%s domain=%s mode=%s plist=%s\n' "$LABEL" "$DOMAIN" "$MODE" "$PLIST"
fi
