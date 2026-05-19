#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$ROOT/.flywheel/scripts/install-pane1-bridge-tailer-launchd.sh"
HEALTH="$ROOT/.flywheel/scripts/pane1-bridge-tailer-process-health.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

write_fake_launchctl() {
  cat >"$TMPDIR/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_LAUNCHCTL_STATE:?}"
log="${FAKE_LAUNCHCTL_LOG:?}"
cmd="${1:-}"
shift || true
touch "$state"
case "$cmd" in
  print)
    printf 'print %s\n' "$*" >>"$log"
    label="${1##*/}"
    if grep -Fqx "$label" "$state"; then
      printf '%s = {\n  state = running\n  pid = %s\n}\n' "$1" "${FAKE_LAUNCHCTL_PID:-4242}"
      exit 0
    fi
    exit 3
    ;;
  bootstrap)
    printf 'bootstrap %s\n' "$*" >>"$log"
    plist="${2:?plist required}"
    label="$(python3 - "$plist" <<'PY'
import plistlib
import sys
with open(sys.argv[1], "rb") as handle:
    print(plistlib.load(handle)["Label"])
PY
)"
    grep -Fqx "$label" "$state" || printf '%s\n' "$label" >>"$state"
    ;;
  bootout)
    printf 'bootout %s\n' "$*" >>"$log"
    label="${1##*/}"
    grep -Fvx "$label" "$state" >"$state.tmp" || true
    mv "$state.tmp" "$state"
    ;;
  kickstart)
    printf 'kickstart %s\n' "$*" >>"$log"
    ;;
  list)
    printf '4242\t0\t%s\n' "$(cat "$state")"
    ;;
  *)
    printf 'unsupported fake launchctl: %s\n' "$cmd" >&2
    exit 9
    ;;
esac
SH
  chmod +x "$TMPDIR/launchctl"
}

write_fake_ps() {
  cat >"$TMPDIR/ps" <<'SH'
#!/usr/bin/env bash
printf '123\n'
SH
  chmod +x "$TMPDIR/ps"
}

write_fake_pgrep() {
  cat >"$TMPDIR/pgrep" <<'SH'
#!/usr/bin/env bash
printf '4242\n'
SH
  chmod +x "$TMPDIR/pgrep"
}

write_fake_launchctl
write_fake_ps
write_fake_pgrep
: >"$TMPDIR/launchctl-state"
: >"$TMPDIR/launchctl.log"

env_base=(
  "HOME=$TMPDIR/home"
  "PANE1_BRIDGE_LABEL=ai.zeststream.flywheel-pane1-bridge-tailer"
  "PANE1_BRIDGE_REPO=$ROOT"
  "PANE1_BRIDGE_TAILER=$ROOT/.flywheel/scripts/pane1-bridge-tailer.sh"
  "PANE1_BRIDGE_LAUNCH_AGENTS_DIR=$TMPDIR/home/Library/LaunchAgents"
  "PANE1_BRIDGE_LAUNCHCTL=$TMPDIR/launchctl"
  "PANE1_BRIDGE_LOG_DIR=$TMPDIR/logs"
  "PANE1_BRIDGE_BOOTSTRAP_DOMAIN=gui/501"
  "PANE1_BRIDGE_LOG_DATE=20260519"
  "PANE1_BRIDGE_LEDGER=$TMPDIR/ledger.jsonl"
  "PANE1_BRIDGE_PS=$TMPDIR/ps"
  "PANE1_BRIDGE_PGREP=$TMPDIR/pgrep"
  "FAKE_LAUNCHCTL_STATE=$TMPDIR/launchctl-state"
  "FAKE_LAUNCHCTL_LOG=$TMPDIR/launchctl.log"
)

jq -nc '{ts:"2026-05-19T19:00:00Z",status:"sent"}' >"$TMPDIR/ledger.jsonl"

bash -n "$INSTALLER" && ok "installer syntax" true || ok "installer syntax" false
bash -n "$HEALTH" && ok "health syntax" true || ok "health syntax" false

env "${env_base[@]}" "$INSTALLER" --dry-run --json >"$TMPDIR/dry.json"
ok_jq "dry-run plans install" '.dry_run == true and .action == "would_install_and_bootstrap" and .loaded == false' "$TMPDIR/dry.json"

env "${env_base[@]}" "$INSTALLER" --apply --json >"$TMPDIR/install1.json"
ok_jq "apply installs and loads" '.success == true and .applied == true and .loaded == true and .bootstrap_called == true and .kickstart_called == true' "$TMPDIR/install1.json"
plist="$TMPDIR/home/Library/LaunchAgents/ai.zeststream.flywheel-pane1-bridge-tailer.plist"
ok "installed plist exists" test -f "$plist"
plutil -lint "$plist" >/dev/null && ok "installed plist lint" true || ok "installed plist lint" false
ok "plist program arguments use tailer follow" python3 - "$plist" "$ROOT/.flywheel/scripts/pane1-bridge-tailer.sh" <<'PY'
import plistlib
import sys
with open(sys.argv[1], "rb") as handle:
    plist = plistlib.load(handle)
assert plist["ProgramArguments"] == [sys.argv[2], "--follow"]
assert plist["RunAtLoad"] is True
assert plist["KeepAlive"] is True
assert plist["StandardOutPath"].endswith("pane1-bridge-tailer-20260519.stdout.log")
assert plist["StandardErrorPath"].endswith("pane1-bridge-tailer-20260519.stderr.log")
PY

env "${env_base[@]}" "$INSTALLER" --apply --json >"$TMPDIR/install2.json"
ok_jq "second apply remains loaded" '.success == true and .loaded == true and .action == "already_current" and .kickstart_called == true' "$TMPDIR/install2.json"

printf '' >"$TMPDIR/launchctl-state"
env "${env_base[@]}" "$INSTALLER" --apply --json >"$TMPDIR/restart.json"
ok_jq "crash restart bootstraps missing label" '.success == true and .loaded == true and .bootstrap_called == true and .kickstart_called == true' "$TMPDIR/restart.json"

env "${env_base[@]}" "$HEALTH" >"$TMPDIR/health.json"
ok_jq "health reports alive" '.status == "pass" and .tailer_process_alive == true and .pid == 4242 and .last_ledger_row_age_seconds != null' "$TMPDIR/health.json"

env "${env_base[@]}" "$INSTALLER" --uninstall --apply --json >"$TMPDIR/uninstall.json"
ok_jq "uninstall unloads and removes plist" '.success == true and .loaded == false and .target_exists == false and .bootout_called == true' "$TMPDIR/uninstall.json"
ok "uninstall kept backup" compgen -G "$plist.backup.*" >/dev/null
ok "launchctl called bootstrap and kickstart" grep -q '^bootstrap ' "$TMPDIR/launchctl.log"
ok "launchctl called bootout" grep -q '^bootout ' "$TMPDIR/launchctl.log"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 14 ]]
