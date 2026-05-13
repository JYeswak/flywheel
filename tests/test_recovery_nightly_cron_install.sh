#!/usr/bin/env bash
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.zeststream.recovery.nightly-snapshot.plist"
pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

[[ -f "$PLIST" ]] && pass "plist_exists" || fail "plist_exists"
plutil -lint "$PLIST" >/dev/null && pass "plist_lint" || fail "plist_lint"

python3 - "$PLIST" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    p = plistlib.load(fh)
assert p["Label"] == "com.zeststream.recovery.nightly-snapshot"
assert p["ProgramArguments"][0] == "<flywheel-repo>/.flywheel/scripts/recovery-baseline-snapshot.sh"
assert p["ProgramArguments"][1:4] == ["--trigger", "nightly", "--json"]
assert p["StartCalendarInterval"] == {"Hour": 3, "Minute": 0}
assert p["StandardOutPath"] == "$HOME/.local/state/flywheel/logs/recovery-nightly.stdout.log"
assert p["StandardErrorPath"] == "$HOME/.local/state/flywheel/logs/recovery-nightly.stderr.log"
print("ok")
PY
pass "plist_shape"

label_count="$(python3 - "$PLIST" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    p = plistlib.load(fh)
print(1 if p.get("Label") == "com.zeststream.recovery.nightly-snapshot" else 0)
PY
)"
[[ "$label_count" == "1" ]] && pass "exactly_one_label" || fail "exactly_one_label"

if /bin/launchctl list 2>/dev/null | awk '{print $3}' | grep -Fxq "com.zeststream.recovery.nightly-snapshot"; then
  fail "launchagent_not_auto_activated"
else
  pass "launchagent_not_auto_activated"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 5 ]]
