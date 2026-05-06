#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-watchers-doctor-launchctl.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
    local file="$1" filter="$2" label="$3"
    if jq -e "$filter" "$file" >/dev/null; then
        pass "$label"
    else
        fail "$label"
        jq . "$file" >&2 || true
    fi
}

HOME_FIX="$TMP/home"
STATE="$TMP/state"
FAKE_BIN="$TMP/bin"
mkdir -p "$HOME_FIX/Library/LaunchAgents/.disabled" "$STATE" "$FAKE_BIN"

cat >"$FAKE_BIN/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "list" ]] || { printf 'forbidden launchctl verb: %s\n' "${1:-}" >&2; exit 9; }
cat "${FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LIST:?}"
SH
chmod +x "$FAKE_BIN/launchctl"

cat >"$TMP/launchctl-list.txt" <<'EOF'
PID	Status	Label
101	0	ai.zeststream.flywheel-alpha
EOF

write_plist() {
    local path="$1" label="$2"
    cat >"$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>$label</string></dict></plist>
EOF
}

write_plist "$HOME_FIX/Library/LaunchAgents/ai.zeststream.flywheel-alpha.plist" "ai.zeststream.flywheel-alpha"
write_plist "$HOME_FIX/Library/LaunchAgents/.disabled/ai.zeststream.flywheel-beta.plist" "ai.zeststream.flywheel-beta"

export FLYWHEEL_WATCHERS_HOME="$HOME_FIX"
export FLYWHEEL_WATCHERS_STATE_DIR="$STATE"
export FLYWHEEL_WATCHERS_LAUNCHCTL="$FAKE_BIN/launchctl"
export FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LIST="$TMP/launchctl-list.txt"

"$BIN" register --label ai.zeststream.flywheel-alpha --owner flywheel-orch --reason fixture-alpha --bead flywheel-2psye --apply --json >/dev/null
"$BIN" register --label ai.zeststream.flywheel-beta --owner flywheel-orch --reason fixture-beta --bead flywheel-2psye --apply --json >/dev/null

"$BIN" doctor --scope launchctl --json >"$TMP/pass.json"
assert_jq "$TMP/pass.json" '.status == "pass" and .subsystems[0].extra.flywheel_plist_count == 2 and .subsystems[0].extra.unregistered_flywheel_plist_count == 0' "all flywheel plists registered"

write_plist "$HOME_FIX/Library/LaunchAgents/.disabled/ai.zeststream.flywheel-gamma.plist" "ai.zeststream.flywheel-gamma"
"$BIN" doctor --scope launchctl --json >"$TMP/fail.json" || true
assert_jq "$TMP/fail.json" '.status == "fail" and .subsystems[0].detail == "unregistered flywheel plist on disk" and .subsystems[0].extra.unregistered_flywheel_plist_count == 1 and .subsystems[0].extra.unregistered_flywheel_plists[0].label == "ai.zeststream.flywheel-gamma"' "unregistered flywheel plist fails doctor"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
