#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-install-plist-{capability-control-plane}.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-install-{capability-control-plane}.XXXXXX")"
export TMP
trap 'python3 -c "import os, shutil; shutil.rmtree(os.environ[\"TMP\"], ignore_errors=True)"' EXIT

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

mkdir -p "$TMP/bin" "$TMP/{capability-control-plane}" "$TMP/skills/.flywheel" "$TMP/logs"
ntm="$TMP/bin/ntm"
jsm="$TMP/bin/jsm"
audit="$TMP/bin/audit"
launchctl="$TMP/bin/launchctl"
plist="$TMP/LaunchAgents/com.zeststream.{capability-control-plane}.watcher.plist"
status="$TMP/status.json"
audit_receipt="$TMP/preinstall-{capability-control-plane}.json"
config="$TMP/ntm.toml"

printf '#!/usr/bin/env bash\nexit 0\n' >"$ntm"
printf '#!/usr/bin/env bash\nprintf "jsm fixture\\n"\n' >"$jsm"
cat >"$audit" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
out=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
jq -nc '{schema_version:"recovery-preinstall-audit/v1",source_plan:".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md",confidence_per_session:{{capability-control-plane}:80},sessions:[{session:"{capability-control-plane}",confidence:80,low_confidence:false}]}'>"$out"
cat "$out"
SH
cat >"$launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "list" ]]; then
  printf "123\t0\tcom.example.other\n"
fi
SH
chmod +x "$ntm" "$jsm" "$audit" "$launchctl"
printf '[session_paths]\n{capability-control-plane} = "%s/{capability-control-plane}"\n' "$TMP" >"$config"

chmod +x "$SCRIPT"
if bash -n "$SCRIPT"; then
  pass "01_script_syntax"
else
  fail "01_script_syntax"
fi

"$SCRIPT" \
  --audit-script "$audit" \
  --audit-receipt "$audit_receipt" \
  --plist "$plist" \
  --status "$status" \
  --repo "$TMP/{capability-control-plane}" \
  --ntm-bin "$ntm" \
  --ntm-config "$config" \
  --launchctl-bin "$launchctl" \
  --jsm-bin "$jsm" \
  --skills-flywheel "$TMP/skills/.flywheel" \
  --log-dir "$TMP/logs" \
  --json >"$TMP/stdout.json"

if test -s "$plist"; then
  pass "02_plist_exists"
else
  fail "02_plist_exists"
fi
if plutil -lint "$plist" >/dev/null; then
  pass "03_plutil_valid"
else
  fail "03_plutil_valid"
fi
if jq empty "$status"; then
  pass "04_status_json_valid"
else
  fail "04_status_json_valid"
fi
assert_jq "$status" '.source_plan==".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md" and .label=="com.zeststream.{capability-control-plane}.watcher" and .dry_run_pass==true and .exactly_one_label==true and .reboot_recovery_claimed==false' "05_status_required_fields"
assert_jq "$status" '.skill_authoring_health.ok==true and (.audit_receipt_path|endswith("preinstall-{capability-control-plane}.json"))' "06_skill_authoring_health_and_audit_receipt"
assert_jq "$status" '(.program_arguments[0]|endswith("/ntm")) and .program_arguments[3]=="watch" and .program_arguments[4]=="{capability-control-plane}"' "07_program_arguments_resolved"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 7 && "$fail_count" -eq 0 ]]
