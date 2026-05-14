#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-recovery.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-recovery-session-paths.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
NOW="2026-05-07T03:00:00Z"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

assert_rc() {
  local want="$1" label="$2"; shift 2
  set +e
  "$@"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] && pass "$label" || fail "$label rc=$got want=$want"
}

sha() { shasum -a 256 "$1" | awk '{print $1}'; }

make_fake_ntm() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--config" ]]; then
  cfg="$2"; shift 2
fi
case "$*" in
  "list --json")
    jq -nc '{sessions:[{name:"flywheel"},{name:"{session}"},{name:"{capability-control-plane}"},{name:"vrtx"}]}'
    ;;
  "config validate --json")
    if [[ -n "${cfg:-}" && -s "$cfg" ]]; then jq -nc '{status:"ok"}'; else jq -nc '{status:"error"}'; exit 1; fi
    ;;
  *)
    printf 'unsupported fake ntm: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "$path"
}

make_config() {
  local path="$1" wrong="$2"
  cat >"$path" <<TOML
# fixture config
projects_base = "$TMP/projects"

[agents]
codex = "codex"

# Per-session path overrides.
[session_paths]
"bearnecessities" = "$TMP/other/bear"
# Resolve symlinks; preserve this comment.
"flywheel" = "$wrong"
"alps-insurance" = "$TMP/old/alps-insurance"
"{session}" = "$TMP/repos/polymarket-pico-z"
"zesttube" = "$TMP/repos/zesttube"

[coordinator]
auto_assign = false
TOML
}

canonical_json() {
  jq -nc \
    --arg root "$TMP/repos" \
    '{
      flywheel:($root+"/flywheel"),
      {session}:($root+"/{session}"),
      clutterfreespaces:($root+"/clutterfreespaces"),
      {session}:($root+"/polymarket-pico-z"),
      {capability-control-plane}:($root+"/{capability-control-plane}"),
      vrtx:($root+"/vrtx"),
      "zeststream-v2":($root+"/zeststream-v2"),
      zesttube:($root+"/zesttube")
    }'
}

run_tool() {
  FLYWHEEL_RECOVERY_CANONICAL_JSON="$(canonical_json)" "$SCRIPT" \
    --config "$config" \
    --topology "$topology" \
    --report "$report" \
    --audit "$audit" \
    --ntm-bin "$ntm" \
    --now "$NOW" \
    "$@"
}

mkdir -p "$TMP/repos"/{flywheel,{session},clutterfreespaces,polymarket-pico-z,{capability-control-plane},vrtx,zeststream-v2,zesttube} "$TMP/other" "$TMP/old"
ntm="$TMP/ntm"; make_fake_ntm "$ntm"
topology="$TMP/topology.jsonl"
jq -nc --arg ts "$NOW" '{session:"flywheel",effective_at:$ts,orchestrator_pane:1,worker_panes:[2,3]}' >"$topology"
config="$TMP/config.toml"; report="$TMP/report.json"; audit="$TMP/audit.jsonl"; wrong="$TMP/repos/wrong-repo"
mkdir -p "$wrong"
make_config "$config" "$wrong"
initial_sha="$(sha "$config")"

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "01_script_syntax" || fail "01_script_syntax"
python3 -m py_compile <(sed '1,4d;$d' "$SCRIPT") && pass "02_python_syntax" || fail "02_python_syntax"

run_tool status --json >"$TMP/status.json"
assert_jq "$TMP/status.json" '.schema_version=="flywheel-recovery-preinstall-report.v1" and .source_plan_path and (.targets|length)==8 and (.normalization_candidates[0].action=="leave_alias_unmodified")' "03_status_emits_report_with_source_plan_and_normalization"
test -s "$report" && pass "04_status_writes_report" || fail "04_status_writes_report"

run_tool repair --scope session-paths --dry-run --json >"$TMP/dry.json"
[[ "$(sha "$config")" == "$initial_sha" ]] && pass "05_dry_run_preserves_config" || fail "05_dry_run_preserves_config"
assert_jq "$TMP/dry.json" '.status=="planned" and .dry_run==true and .l112_observed=="OK_recovery_session_paths" and (.planned_changes|length)==6 and (.failure_modes_covered[]|select(.mode=="wrong_repo_path" and .session=="flywheel"))' "06_dry_run_reports_planned_changes_and_wrong_repo_mode"

run_tool repair --scope session-paths --apply --idempotency-key fixed-key --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status=="applied" and .backup_path and .old_sha256 and .new_sha256 and .post_repair_validation.status=="pass" and .audit_row_written==true' "07_apply_writes_backup_audit_and_validates"
backup="$(jq -r '.backup_path' "$TMP/apply.json")"
[[ "$(sha "$backup")" == "$initial_sha" ]] && pass "08_backup_matches_original" || fail "08_backup_matches_original"
grep -q 'auto_assign = false' "$config" && grep -q 'Resolve symlinks' "$config" && grep -q '"alps-insurance"' "$config" \
  && pass "09_apply_preserves_unrelated_format_and_alias" || fail "09_apply_preserves_unrelated_format_and_alias"
grep -q '"{session}" = ' "$config" && grep -q '"zeststream-v2" = ' "$config" \
  && pass "10_apply_adds_missing_target_paths" || fail "10_apply_adds_missing_target_paths"
assert_jq "$audit" '.schema_version=="flywheel-recovery.session-path-repair.audit.v1" and .idempotency_key=="fixed-key" and (.sessions_changed|index("flywheel")) and .source_plan_path' "11_audit_row_has_required_receipt_fields"

run_tool repair --scope session-paths --apply --idempotency-key fixed-key --json >"$TMP/noop.json"
assert_jq "$TMP/noop.json" '.status=="noop" and .post_repair_validation.status=="pass"' "12_reapply_same_key_is_noop"
[[ "$(grep -c '"flywheel" = ' "$config")" == "1" ]] && pass "13_reapply_does_not_duplicate_keys" || fail "13_reapply_does_not_duplicate_keys"

run_tool validate config --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status=="pass" and .unconverged_sessions==[]' "14_validate_config_converges"

cp "$backup" "$config"
[[ "$(sha "$config")" == "$initial_sha" ]] && pass "15_copy_backup_rollback_restores_original_sha" || fail "15_copy_backup_rollback_restores_original_sha"

block_report="$TMP/block-report.json"
jq -nc --arg plan "<flywheel-repo>/.flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md" --arg desired "$TMP/repos/flywheel" '{
  schema_version:"flywheel-recovery-preinstall-report.v1",
  source_plan_path:$plan,
  targets:[
    {session:"flywheel",current_path:"/tmp/wrong",desired_path:$desired,confidence:"low",protected:false},
    {session:"{capability-control-plane}",current_path:"/tmp/wrong",desired_path:$desired,confidence:"high",protected:true}
  ]
}' >"$block_report"
report="$block_report"
make_config "$config" "$wrong"
before_block="$(sha "$config")"
set +e
run_tool repair --scope session-paths --apply --json >"$TMP/block.json"
block_rc=$?
set -e
[[ "$block_rc" -eq 4 ]] && pass "16_low_confidence_or_protected_blocks_apply" || fail "16_low_confidence_or_protected_blocks_apply rc=$block_rc"
assert_jq "$TMP/block.json" '.status=="blocked" and (.blockers[]|select(.reason=="low_confidence")) and (.blockers[]|select(.reason=="protected_session"))' "17_block_receipt_names_low_confidence_and_protected"
[[ "$(sha "$config")" == "$before_block" ]] && pass "18_blocked_apply_preserves_config" || fail "18_blocked_apply_preserves_config"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 18 && "$fail_count" -eq 0 ]]
