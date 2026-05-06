#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-watchers-allowlist.XXXXXX")"
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
log="${FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LOG:?}"
state="${FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LIST:?}"
cmd="${1:-list}"
shift || true
case "$cmd" in
  list)
    cat "$state"
    ;;
  bootout|bootstrap)
    printf '%s %s\n' "$cmd" "$*" >>"$log"
    ;;
  *)
    printf 'fake launchctl unsupported: %s\n' "$cmd" >&2
    exit 9
    ;;
esac
SH
chmod +x "$FAKE_BIN/launchctl"

cat >"$FAKE_BIN/plutil" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$FAKE_BIN/plutil"

cat >"$FAKE_BIN/ps" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "-ef" ]]; then
  printf 'UID PID PPID C STIME TTY TIME CMD\n'
  exit 0
fi
/bin/ps "$@"
SH
chmod +x "$FAKE_BIN/ps"

cat >"$TMP/launchctl-list.txt" <<'EOF'
PID	Status	Label
101	0	ai.zeststream.flywheel-alpha
102	0	homebrew.mxcl.sleepwatcher
103	0	ai.zeststream.fixture-orphan
EOF
: >"$TMP/launchctl.log"

write_plist() {
    local path="$1" label="$2"
    cat >"$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>$label</string></dict></plist>
EOF
}

write_plist "$HOME_FIX/Library/LaunchAgents/ai.zeststream.flywheel-alpha.plist" "ai.zeststream.flywheel-alpha"
write_plist "$HOME_FIX/Library/LaunchAgents/homebrew.mxcl.sleepwatcher.plist" "homebrew.mxcl.sleepwatcher"
write_plist "$HOME_FIX/Library/LaunchAgents/ai.zeststream.fixture-orphan.plist" "ai.zeststream.fixture-orphan"

export FLYWHEEL_WATCHERS_HOME="$HOME_FIX"
export FLYWHEEL_WATCHERS_STATE_DIR="$STATE"
export FLYWHEEL_WATCHERS_LAUNCHCTL="$FAKE_BIN/launchctl"
export FLYWHEEL_WATCHERS_PLUTIL="$FAKE_BIN/plutil"
export FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LOG="$TMP/launchctl.log"
export FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LIST="$TMP/launchctl-list.txt"
export PATH="$FAKE_BIN:$PATH"

"$BIN" allowlist add --pattern 'homebrew.mxcl.*' --reason fixture-homebrew --scope third-party --json >"$TMP/allowlist-dry.json"
assert_jq "$TMP/allowlist-dry.json" '.command == "allowlist" and .dry_run == true and (.planned_actions[0].kind == "allowlist_append")' "allowlist add dry-run default"
test ! -e "$STATE/plist-allowlist.jsonl" && pass "allowlist dry-run does not create ledger" || fail "allowlist dry-run does not create ledger"

"$BIN" allowlist add --pattern 'homebrew.mxcl.*' --reason fixture-homebrew --scope third-party --apply --json >"$TMP/allowlist-add.json"
"$BIN" allowlist match homebrew.mxcl.sleepwatcher --json >"$TMP/allowlist-match.json"
"$BIN" allowlist list --json >"$TMP/allowlist-list.json"
assert_jq "$TMP/allowlist-add.json" '.command == "allowlist" and .mode == "applied" and .row.pattern == "homebrew.mxcl.*"' "allowlist add apply"
assert_jq "$TMP/allowlist-match.json" '.matched == true and .pattern == "homebrew.mxcl.*"' "allowlist match wildcard"
assert_jq "$TMP/allowlist-list.json" 'length == 1 and .[0].pattern == "homebrew.mxcl.*"' "allowlist list active"

"$BIN" allowlist add --pattern 'com.apple.*' --reason fixture-apple --scope system --apply --json >/dev/null
"$BIN" allowlist remove --pattern 'com.apple.*' --reason fixture-remove --apply --json >"$TMP/allowlist-remove.json"
"$BIN" allowlist list --json >"$TMP/allowlist-list-after-remove.json"
assert_jq "$TMP/allowlist-remove.json" '.command == "allowlist" and .mode == "applied" and .pattern == "com.apple.*"' "allowlist remove apply"
assert_jq "$TMP/allowlist-list-after-remove.json" 'length == 1 and (map(.pattern) | index("com.apple.*") == null)' "allowlist remove tombstones active pattern"

"$BIN" register --label ai.zeststream.flywheel-alpha --owner flywheel --reason fixture --bead flywheel-3gzo7 --apply --json >/dev/null
"$BIN" audit-orphans --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.taxonomy_classes == ["OK","ALLOWLISTED","ORPHAN","MISSING"] and .class_counts.OK == 1 and .class_counts.ALLOWLISTED == 1 and .class_counts.ORPHAN == 1' "audit taxonomy classes"
assert_jq "$TMP/audit.json" '(.items[] | select(.label == "homebrew.mxcl.sleepwatcher")).status == "ALLOWLISTED" and (.items[] | select(.label == "ai.zeststream.fixture-orphan")).status == "ORPHAN"' "audit classifies allowlisted and orphan"

"$BIN" audit-orphans --kill-unregistered --dry-run --json >"$TMP/audit-kill-dry.json"
assert_jq "$TMP/audit-kill-dry.json" '.dry_run == true and (.would_call_external | map(.label) | index("ai.zeststream.fixture-orphan")) and ((.would_call_external | map(.label) | index("homebrew.mxcl.sleepwatcher")) == null)' "kill dry-run targets only orphan"
test ! -s "$TMP/launchctl.log" && pass "kill dry-run does not call launchctl" || fail "kill dry-run does not call launchctl"

"$BIN" audit-orphans --kill-unregistered --apply --json >"$TMP/audit-kill-apply.json"
assert_jq "$TMP/audit-kill-apply.json" '.mode == "applied" and (.unregistered_launchctl == ["ai.zeststream.fixture-orphan"])' "kill apply output only orphan"
grep -q 'ai.zeststream.fixture-orphan' "$TMP/launchctl.log" && pass "kill apply bootouts orphan fixture" || fail "kill apply bootouts orphan fixture"
! grep -q 'homebrew.mxcl.sleepwatcher' "$TMP/launchctl.log" && pass "kill apply skips allowlisted fixture" || fail "kill apply skips allowlisted fixture"

"$BIN" doctor --scope launchctl --json >"$TMP/doctor-launchctl.json" || true
assert_jq "$TMP/doctor-launchctl.json" '.status == "fail" and .subsystems[0].extra.allowlist_count == 1 and .subsystems[0].extra.orphan_count == 1 and .subsystems[0].extra.missing_count == 0' "doctor launchctl allowlist and orphan extras"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
