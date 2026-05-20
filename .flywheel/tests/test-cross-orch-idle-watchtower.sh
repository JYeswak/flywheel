#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-orch-idle-watchtower.sh"
PLIST="$ROOT/.flywheel/launchd/ai.zeststream.cross-orch-idle-watchtower.plist"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/cross-orch-idle-watchtower.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
    jq . "$file" >&2 || true
  fi
}

cat >"$TMP/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  has-session)
    [[ "${3:-}" == "skillos" ]]
    ;;
  list-panes)
    printf '2\n3\n'
    ;;
  capture-pane)
    case "${3:-}" in
      skillos:0.2) printf '› Use /skills to list available skills\n' ;;
      skillos:0.3) printf 'Pursuing goal (31s)\n' ;;
      *) printf 'josh@host %%\n' ;;
    esac
    ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TMP/tmux"

cat >"$TMP/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "ready" && "${2:-}" == "--json" ]] || exit 2
cat "${FAKE_BR_READY:?}"
SH
chmod +x "$TMP/br"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  send) exit 0 ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

mkdir -p "$TMP/skillos/.beads" "$TMP/home/.local/state/flywheel"
cat >"$TMP/ready.json" <<'JSON'
[
  {"id":"skillos-p0","priority":0},
  {"id":"skillos-p1","priority":1},
  {"id":"skillos-p2","priority":2}
]
JSON

env_base=(
  "HOME=$TMP/home"
  "PATH=/usr/bin:/bin:/usr/sbin:/sbin"
  "WATCHTOWER_TMUX_BIN=$TMP/tmux"
  "WATCHTOWER_BR_BIN=$TMP/br"
  "WATCHTOWER_NTM_BIN=$TMP/ntm"
  "WATCHTOWER_SESSIONS=skillos:$TMP/skillos"
  "FAKE_BR_READY=$TMP/ready.json"
  "FAKE_NTM_ARGV=$TMP/ntm.argv"
)

bash -n "$SCRIPT" && ok "script syntax" true || ok "script syntax" false
plutil -lint "$PLIST" >/dev/null && ok "source plist lint" true || ok "source plist lint" false

env "${env_base[@]}" "$SCRIPT" validate plist --plist "$PLIST" --json >"$TMP/validate.json"
ok_jq "plist validates cadence and nudge apply args" '.status == "pass" and .label_ok == true and .cadence_ok == true and .nudge_apply_json == true' "$TMP/validate.json"

env "${env_base[@]}" "$SCRIPT" run --mode nudge --dry-run --ledger "$TMP/ledger-dry.jsonl" --json >"$TMP/dry.json"
ok_jq "dry-run reports would-nudge without sending" '.mode == "nudge" and .dry_run == true and .apply == false and .idle_panes_with_ready_beads == 1 and .nudges_sent == 0' "$TMP/dry.json"
ok "dry-run ledger records would-nudge" jq -e 'select(.action == "would-nudge" and .reason == "requires-apply" and .session == "skillos" and .pane == 2)' "$TMP/ledger-dry.jsonl" >/dev/null
ok "dry-run did not call ntm" test ! -s "$TMP/ntm.argv"

env "${env_base[@]}" "$SCRIPT" run --mode nudge --apply --ledger "$TMP/ledger-apply.jsonl" --json >"$TMP/apply.json"
ok_jq "apply sends exactly one nudge" '.mode == "nudge" and .apply == true and .idle_panes_with_ready_beads == 1 and .nudges_sent == 1' "$TMP/apply.json"
ok "apply ledger records nudge-sent" jq -e 'select(.action == "nudge-sent" and .session == "skillos" and .pane == 2 and .p0_ready == 1 and .p1_ready == 1)' "$TMP/ledger-apply.jsonl" >/dev/null
ok "ntm send targets sister orch pane 1" grep -q '^send skillos --pane=1 --no-cass-check ORCH-IDLE NUDGE from flywheel:1 cross-orch-idle-watchtower' "$TMP/ntm.argv"

env "${env_base[@]}" "$SCRIPT" doctor --ledger "$TMP/ledger-apply.jsonl" --plist "$PLIST" --json >"$TMP/doctor.json"
ok_jq "doctor reports canonical status" '.command == "doctor" and .status == "pass" and ([.checks[].name] | index("source_plist_lint"))' "$TMP/doctor.json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -eq 10 ]]
