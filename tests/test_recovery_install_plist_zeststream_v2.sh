#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-install-plist-zeststream-v2.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-install-zsv2.XXXXXX")"
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

mkdir -p "$TMP/bin" "$TMP/zeststream-v2" "$TMP/logs" "$TMP/LaunchAgents"
ntm="$TMP/bin/ntm"
audit="$TMP/bin/audit"
launchctl="$TMP/bin/launchctl"
plist="$TMP/LaunchAgents/com.zeststream.zeststream-v2.watcher.plist"
status="$TMP/recovery-install-zeststream-v2-status.json"
audit_receipt="$TMP/preinstall-zeststream-v2.json"
config="$TMP/ntm.toml"
probe="$TMP/label-probe.txt"

printf '#!/usr/bin/env bash\nexit 0\n' >"$ntm"
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
jq -nc '{schema_version:"recovery-preinstall-audit/v1",source_plan:".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md",confidence_per_session:{"zeststream-v2":20},sessions:[{session:"zeststream-v2",confidence:20,confidence_min:20,low_confidence:false}]}'>"$out"
cat "$out"
SH
cat >"$launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "list" ]]; then
  printf "321\t0\tcom.example.other\n"
fi
SH
chmod +x "$ntm" "$audit" "$launchctl"
printf '[session_paths]\n"zeststream-v2" = "%s/zeststream-v2"\n' "$TMP" >"$config"

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
  --repo "$TMP/zeststream-v2" \
  --ntm-bin "$ntm" \
  --ntm-config "$config" \
  --launchctl-bin "$launchctl" \
  --log-dir "$TMP/logs" \
  --launchctl-probe-path "$probe" \
  --confidence-min 20 \
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
assert_jq "$status" '.schema_version=="recovery-session-watcher-install/v1" and .source_plan==".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md" and .label=="com.zeststream.zeststream-v2.watcher" and .dry_run_pass==true and .exactly_one_label==true and .reboot_recovery_claimed==false and .launchctl_load_attempted==false' "05_status_shape"
assert_jq "$status" '.zeststream_v2_repo_path_validated==true and .readiness.ntm_binary.executable==true and .readiness.ntm_config.exists==true and .readiness.repo.exists==true and .readiness.logs_dir.exists==true' "06_readiness_shape"
assert_jq "$status" '.dashed_name_quoting_validated==true and .program_arguments[2]=="zeststream-v2" and (.working_directory|endswith("/zeststream-v2"))' "07_dashed_name_status_assertion"
python3 - "$plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    plist = plistlib.load(fh)
assert plist["Label"] == "com.zeststream.zeststream-v2.watcher"
assert plist["ProgramArguments"][2] == "zeststream-v2"
assert plist["WorkingDirectory"].endswith("/zeststream-v2")
assert "zeststream-v2-watcher.stdout.log" in plist["StandardOutPath"]
assert "zeststream-v2-watcher.stderr.log" in plist["StandardErrorPath"]
PY
pass "08_dashed_name_plist_assertion"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 8 && "$fail_count" -eq 0 ]]
