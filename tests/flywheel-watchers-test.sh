#!/usr/bin/env bash
# shellcheck disable=SC2015
set -euo pipefail

BIN="${FLYWHEEL_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
LIB="${FLYWHEEL_WATCHERS_LIB:-$HOME/.local/lib/flywheel-watchers}"
SCANNER="${FLYWHEEL_WATCHERS_BACKUP_SCANNER:-$HOME/.local/share/flywheel-watchers/scripts/check-executable-bak-vulnerability.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-watchers-test.XXXXXX")"
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

assert_text() {
    local file="$1" pattern="$2" label="$3"
    if rg -q "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label"
        sed -n '1,120p' "$file" >&2 || true
    fi
}

run_backup_scan_case() {
    local name="$1" content="$2" mode="$3" expected_rc="$4" jq_filter="$5"
    local dir="$TMP/backup-scan-$name" out="$TMP/backup-scan-$name.json" rc=0
    mkdir -p "$dir"
    printf '%s\n' "$content" >"$dir/flywheel-fixture.bak.20260505"
    chmod "$mode" "$dir/flywheel-fixture.bak.20260505"
    FLYWHEEL_WATCHERS_BACKUP_SCAN_DIR="$dir" "$SCANNER" --json >"$out" || rc=$?
    if [[ "$rc" == "$expected_rc" ]]; then
        pass "backup scanner rc $name"
    else
        fail "backup scanner rc $name expected=$expected_rc got=$rc"
    fi
    assert_jq "$out" "$jq_filter" "backup scanner json $name"
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

cat >"$TMP/launchctl-list.txt" <<'EOF'
PID	Status	Label
101	0	ai.zeststream.flywheel-alpha
102	0	ai.zeststream.unregistered-live
EOF
: >"$TMP/launchctl.log"

cat >"$HOME_FIX/Library/LaunchAgents/ai.zeststream.flywheel-alpha.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.flywheel-alpha</string></dict></plist>
EOF
cat >"$HOME_FIX/Library/LaunchAgents/.disabled/ai.zeststream.flywheel-beta.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.flywheel-beta</string></dict></plist>
EOF
cat >"$HOME_FIX/Library/LaunchAgents/com.google.keystone.agent.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>ProgramArguments</key><array><string>/usr/bin/true</string></array></dict></plist>
EOF

export FLYWHEEL_WATCHERS_HOME="$HOME_FIX"
export FLYWHEEL_WATCHERS_STATE_DIR="$STATE"
export FLYWHEEL_WATCHERS_LAUNCHCTL="$FAKE_BIN/launchctl"
export FLYWHEEL_WATCHERS_PLUTIL="$FAKE_BIN/plutil"
export FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LOG="$TMP/launchctl.log"
export FLYWHEEL_WATCHERS_FAKE_LAUNCHCTL_LIST="$TMP/launchctl-list.txt"
export FLYWHEEL_WATCHERS_WATCH_COUNT=2

bash -n "$BIN" && pass "dispatcher syntax" || fail "dispatcher syntax"
for file in "$LIB"/*.sh; do
    bash -n "$file" && pass "library syntax $(basename "$file")" || fail "library syntax $(basename "$file")"
done
bash -n "$SCANNER" && pass "backup scanner syntax" || fail "backup scanner syntax"
test -x "$SCANNER" && pass "backup scanner executable" || fail "backup scanner executable"

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.command == "info" and .mutation_posture.apply_required == true' "info json"

"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.command == "examples" and (.examples | length) >= 5' "examples json"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.command == "quickstart" and (.steps | length) >= 5' "quickstart json"

"$BIN" help repair --json >"$TMP/help-repair.json"
assert_jq "$TMP/help-repair.json" '.command == "help" and .topic == "repair" and (.text | test("Exit codes") | not)' "help topic json"

"$BIN" --help >"$TMP/help.txt"
assert_text "$TMP/help.txt" '0=success 1=domain-fail 2=usage 3=transient 4=blocked-by-gate' "help documents exit codes"

"$BIN" completion bash >"$TMP/completion.bash"
assert_text "$TMP/completion.bash" 'complete -F _flywheel_watchers_completion flywheel-watchers' "bash completion"

"$BIN" completion zsh >"$TMP/completion.zsh"
assert_text "$TMP/completion.zsh" '^compadd ' "zsh completion"

"$BIN" schema register --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel-watchers.canonical.v1" and .command == "register"' "schema command"

"$BIN" register --label ai.zeststream.flywheel-alpha --owner flywheel --reason fixture --bead flywheel-2yj96 --dry-run --json >"$TMP/register-dry.json"
assert_jq "$TMP/register-dry.json" '.command == "register" and .dry_run == true and (.planned_actions | length) == 1' "register dry-run"
test ! -e "$STATE/plist-registry.jsonl" && pass "register dry-run does not create registry" || fail "register dry-run does not create registry"

"$BIN" register --label ai.zeststream.flywheel-alpha --owner flywheel --reason fixture --bead flywheel-2yj96 --apply --idempotency-key fixture-register --json >"$TMP/register-apply.json"
assert_jq "$TMP/register-apply.json" '.command == "register" and .mode == "applied" and .registered.label == "ai.zeststream.flywheel-alpha"' "register apply"
test "$(grep -c '^[[:space:]]*$' "$STATE/plist-registry.jsonl")" = "0" && pass "registry has zero blank lines" || fail "registry has zero blank lines"
jq -e '.label == "ai.zeststream.flywheel-alpha"' "$STATE/plist-registry.jsonl" >/dev/null && pass "registry row valid json" || fail "registry row valid json"

"$BIN" register --label ai.zeststream.flywheel-gamma --owner flywheel --reason fixture --apply --idempotency-key fixture-replay --json >"$TMP/register-replay-1.json"
"$BIN" register --label ai.zeststream.flywheel-gamma --owner flywheel --reason fixture --apply --idempotency-key fixture-replay --json >"$TMP/register-replay-2.json"
assert_jq "$TMP/register-replay-2.json" '.command == "register" and .replayed == true' "idempotency replay"

"$BIN" registry --json >"$TMP/registry.json"
assert_jq "$TMP/registry.json" '.active_count == 2 and (.active[] | select(.label == "ai.zeststream.flywheel-alpha"))' "registry active state"

registry_lines_before="$(wc -l <"$STATE/plist-registry.jsonl" | tr -d ' ')"
"$BIN" unregister --label ai.zeststream.flywheel-gamma --dry-run --json >"$TMP/unregister-dry.json"
assert_jq "$TMP/unregister-dry.json" '.command == "unregister" and .dry_run == true and (.planned_actions | length) == 1' "unregister dry-run"
registry_lines_after="$(wc -l <"$STATE/plist-registry.jsonl" | tr -d ' ')"
test "$registry_lines_before" = "$registry_lines_after" && pass "unregister dry-run does not mutate registry" || fail "unregister dry-run does not mutate registry"

"$BIN" unregister --label ai.zeststream.flywheel-gamma --apply --idempotency-key fixture-unregister --json >"$TMP/unregister-apply.json"
assert_jq "$TMP/unregister-apply.json" '.command == "unregister" and .mode == "applied" and .label == "ai.zeststream.flywheel-gamma"' "unregister apply"

"$BIN" doctor --scope launchctl --json >"$TMP/doctor-launchctl-missing.json" || true
assert_jq "$TMP/doctor-launchctl-missing.json" '.scope == "launchctl" and .status == "fail" and .subsystems[0].extra.unregistered_flywheel_plist_count == 1 and .subsystems[0].extra.unregistered_flywheel_plists[0].label == "ai.zeststream.flywheel-beta"' "doctor launchctl fails on unregistered flywheel plist"

"$BIN" register --label ai.zeststream.flywheel-beta --owner flywheel --reason fixture-disabled --bead flywheel-2psye --apply --idempotency-key fixture-register-beta --json >"$TMP/register-beta.json"
assert_jq "$TMP/register-beta.json" '.command == "register" and .mode == "applied" and .registered.label == "ai.zeststream.flywheel-beta"' "register disabled flywheel fixture"

"$BIN" doctor --scope launchctl --json >"$TMP/doctor-launchctl-registered.json"
assert_jq "$TMP/doctor-launchctl-registered.json" '.scope == "launchctl" and .status == "pass" and .subsystems[0].extra.unregistered_flywheel_plist_count == 0 and .subsystems[0].extra.flywheel_plist_count == 2' "doctor launchctl passes when flywheel plists registered"

"$BIN" validate ai.zeststream.flywheel-alpha --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command == "validate" and .status == "pass" and .pure_read == true' "validate label"

"$BIN" why ai.zeststream.flywheel-alpha --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command == "why" and .label == "ai.zeststream.flywheel-alpha" and .plist.sha256' "why provenance"

"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and (.subsystems | length) == 5' "doctor all subsystems"

"$BIN" doctor --scope plist-disk --json >"$TMP/doctor-plist-disk.json"
assert_jq "$TMP/doctor-plist-disk.json" '.scope == "plist-disk" and .status == "pass" and .subsystems[0].extra.third_party_plist_count == 1 and .subsystems[0].extra.invalid_plist_count_zeststream == 0' "doctor plist-disk separates third-party missing label"

"$BIN" doctor --scope executable-backups --json >"$TMP/doctor-executable-backups.json"
assert_jq "$TMP/doctor-executable-backups.json" '.scope == "executable-backups" and .status == "pass" and .subsystems[0].extra.vulnerable_count == 0' "doctor scoped executable backups"

"$BIN" doctor --scope registry --json >"$TMP/doctor-registry.json"
assert_jq "$TMP/doctor-registry.json" '.scope == "registry" and (.subsystems | length) == 1' "doctor scoped registry"

"$BIN" doctor --fix --json >"$TMP/doctor-fix.json"
assert_jq "$TMP/doctor-fix.json" '.fix_mode == "dry_run" and .dry_run_default == true' "doctor fix dry-run default"

"$BIN" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .repo == "all"' "health json"

"$BIN" health --watch -i 0 --json >"$TMP/health-watch.jsonl"
test "$(wc -l <"$TMP/health-watch.jsonl" | tr -d ' ')" = "2" && pass "health watch emits two samples under fixture limit" || fail "health watch emits two samples under fixture limit"

run_backup_scan_case "executable-danger" 'launchctl bootout gui/501/ai.zeststream.bad' 755 1 '.vulnerable_count == 1 and .items[0].executable == true and (.items[0].dangerous_patterns_found | index("launchctl bootout"))'
run_backup_scan_case "executable-clean" 'printf safe' 755 0 '.vulnerable_count == 0 and .items[0].executable == true and (.items[0].dangerous_patterns_found | length) == 0'
run_backup_scan_case "nonexecutable-danger" 'kill -9 12345' 644 0 '.vulnerable_count == 0 and .items[0].executable == false and (.items[0].dangerous_patterns_found | index("kill -9"))'

"$BIN" repair --scope registry --dry-run --json >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.command == "repair" and .dry_run == true and has("planned_actions")' "repair dry-run"

"$BIN" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command == "audit" and .count >= 2' "audit mutations"

"$BIN" audit-mutations --json >"$TMP/audit-mutations.json"
assert_jq "$TMP/audit-mutations.json" '.command == "audit" and .count >= 2' "audit-mutations alias"

"$BIN" audit-orphans --kill-unregistered --dry-run --json >"$TMP/audit-orphans-dry.json"
assert_jq "$TMP/audit-orphans-dry.json" '.command == "audit-orphans" and .dry_run == true and (.would_call_external | length) >= 1' "audit-orphans kill dry-run"
test ! -s "$TMP/launchctl.log" && pass "audit-orphans dry-run does not call launchctl" || fail "audit-orphans dry-run does not call launchctl"

"$BIN" off --repo flywheel --reason fixture --dry-run --json >"$TMP/off-dry.json"
assert_jq "$TMP/off-dry.json" '.command == "off" and .dry_run == true and (.would_call_external | length) >= 1' "off dry-run"
test ! -s "$TMP/launchctl.log" && pass "off dry-run does not call launchctl" || fail "off dry-run does not call launchctl"

"$BIN" off --repo flywheel --reason fixture --apply --idempotency-key off-fixture --json >"$TMP/off-apply.json"
assert_jq "$TMP/off-apply.json" '.command == "off" and .mode == "applied" and .jobs_affected >= 1' "off apply with fake launchctl"
grep -q '^bootout ' "$TMP/launchctl.log" && pass "fake bootout recorded" || fail "fake bootout recorded"

"$BIN" on --repo flywheel --apply --idempotency-key on-fixture --json >"$TMP/on-apply.json"
assert_jq "$TMP/on-apply.json" '.command == "on" and .mode == "applied" and .jobs_affected >= 1' "on apply with fake launchctl"
grep -q '^bootstrap ' "$TMP/launchctl.log" && pass "fake bootstrap recorded" || fail "fake bootstrap recorded"

"$BIN" robot/activity --json >"$TMP/robot-activity.json"
assert_jq "$TMP/robot-activity.json" '.success == true and .output_format == "json" and .query == "activity"' "robot activity envelope"

"$BIN" robot/diagnose ai.zeststream.flywheel-alpha --json >"$TMP/robot-diagnose.json"
assert_jq "$TMP/robot-diagnose.json" '.success == true and .query == "diagnose" and .label == "ai.zeststream.flywheel-alpha"' "robot diagnose envelope"

"$BIN" robot/registry-state --json >"$TMP/robot-registry.json"
assert_jq "$TMP/robot-registry.json" '.success == true and .query == "registry-state" and .active_count >= 1' "robot registry-state envelope"

"$BIN" robot/capabilities --json >"$TMP/robot-capabilities.json"
assert_jq "$TMP/robot-capabilities.json" '.success == true and (.capabilities | length) >= 5' "robot capabilities envelope"

"$BIN" robot/schema=activity --json >"$TMP/robot-schema.json"
assert_jq "$TMP/robot-schema.json" '.success == true and .schema_version == "flywheel-watchers.robot.v1"' "robot schema envelope"

"$BIN" robot/tail ai.zeststream.flywheel-alpha --json >"$TMP/robot-tail.json"
assert_jq "$TMP/robot-tail.json" '.success == true and .query == "tail"' "robot tail envelope"

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" flywheel-watchers >"$TMP/check-cli-scoping.txt"
assert_text "$TMP/check-cli-scoping.txt" 'Summary: 4 pass, 0 fail' "canonical cli scoping checker"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
