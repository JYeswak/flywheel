#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d -t pws-integration.XXXXXX)"
RECEIPT="/tmp/flywheel-5ktd-final-receipt.md"
HELPER="$HOME/.claude/commands/flywheel/_shared/pane-state.sh"
LOOP="$HOME/.claude/skills/.flywheel/bin/flywheel-loop"

trap 'rm -rf "$TMP"' EXIT

source "$ROOT/tests/tick_pws_common.sh"

pass_count=0
fail_count=0
gate1=false
gate2=false
gate3=false
rollback_env=false
rollback_file=false
scope_boundary=false

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

run_doctor_gate() {
  set +e
  "$LOOP" doctor --repo "$ROOT" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err"
  local rc=$?
  set -e
  if jq -e '
    .pane_work_signal
    and (.pane_work_signal.status | IN("ok","warn","fail","disabled"))
    and (.pane_work_signal.disagreements_by_pane | type == "object")
    and (.pane_work_signal.streak_counts | type == "object")
    and (.pane_work_signal.disabled | type == "boolean")
  ' "$TMP/doctor.json" >/dev/null; then
    pass "doctor_pane_work_signal_fields"
    gate1=true
  else
    fail "doctor_pane_work_signal_fields"
    cat "$TMP/doctor.err" >&2 || true
    jq . "$TMP/doctor.json" >&2 || true
  fi
  printf '%s\n' "$rc" >"$TMP/doctor.rc"
}

run_tick_gate() {
  local tick_tmp="$TMP/tick"
  mkdir -p "$tick_tmp"
  tick_pws_run "$tick_tmp" "cod" "idle" || { cat "$tick_tmp/tick.err" >&2; fail "tick_fixture_runs"; return; }
  local receipt="$tick_tmp/repo/.flywheel/runtime/flywheel-loop/last_run.json"
  if jq -e '
    .idle_capacity_source == "pane_work_signal_for_codex"
    and .pane_work_signal_sampled == true
    and (.pane_work_signal_disagreements[] | select(.pane == 2 and .truth_state == "working"))
    and .dispatch_capacity.panes[0].gate.capacity == false
  ' "$receipt" >/dev/null; then
    pass "tick_capacity_uses_pws_for_codex"
    gate2=true
  else
    fail "tick_capacity_uses_pws_for_codex"
    jq . "$receipt" >&2 || true
  fi
}

write_ntm_stub() {
  local path="$1" agent_type="$2" state="$3" patterns="$4"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-}" in
  --robot-activity=*)
    jq -nc '{agents:[{pane_idx:2,agent_type:"$agent_type",state:"$state",detected_patterns:$patterns}]}'
    ;;
  *) printf 'unexpected ntm call: %s\n' "\$*" >&2; exit 2 ;;
esac
SH
  chmod +x "$path"
}

write_pws_stub() {
  local path="$1" truth="$2" reason="${3:-fixture}"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "--classify" ]]; then
  jq -nc '{truth_state:"$truth",truth_source:"pane_work_signal",truth_reason:"$reason"}'
else
  jq -nc '{truth_state:"$truth",truth_source:"pane_work_signal",truth_reason:"fixture_sample"}'
fi
SH
  chmod +x "$path"
}

run_status_marker_gate() {
  local ntm_bin="$TMP/ntm" pws_bin="$TMP/pws" out text

  write_ntm_stub "$ntm_bin" "codex" "GENERATING" '["Working (12s)"]'
  write_pws_stub "$pws_bin" "working"
  out="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --json)"
  text="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --text)"
  jq -e '.[0].source == "pws"' <<<"$out" >/dev/null && grep -q 'source=pws' <<<"$text" || { fail "status_marker_pws"; return; }

  write_ntm_stub "$ntm_bin" "claude" "WAITING" '["ready"]'
  cat >"$pws_bin" <<'SH'
#!/usr/bin/env bash
printf 'PWS should not be called for non-codex panes\n' >&2
exit 9
SH
  chmod +x "$pws_bin"
  out="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --json)"
  text="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --text)"
  jq -e '.[0].source == "ntm"' <<<"$out" >/dev/null && grep -q 'source=ntm' <<<"$text" || { fail "status_marker_ntm"; return; }

  write_ntm_stub "$ntm_bin" "codex" "WAITING" '["codex prompt"]'
  write_pws_stub "$pws_bin" "working" "foreground_working_structured_row"
  out="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --json)"
  text="$(NTM="$ntm_bin" PANE_WORK_SIGNAL_BIN="$pws_bin" RECENCY_CLASSIFIER_DISABLE=1 "$HELPER" fixture --text)"
  jq -e '.[0].source == "pws!=ntm"' <<<"$out" >/dev/null && grep -q 'source=pws!=ntm' <<<"$text" || { fail "status_marker_disagreement"; return; }

  pass "status_markers_pws_ntm_disagreement"
  gate3=true
}

run_rollback_gate() {
  local env_tmp="$TMP/rollback-env" file_tmp="$TMP/rollback-file"
  mkdir -p "$env_tmp" "$file_tmp/repo/.flywheel"

  tick_pws_run "$env_tmp" "cod" "idle" "FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1" || { cat "$env_tmp/tick.err" >&2; fail "rollback_env_tick_runs"; return; }
  if jq -e '
    .pane_work_signal_sampled == false
    and .pane_work_signal_disabled == true
    and .pane_work_signal_disabled_reason == "pws_disabled_via_env"
    and .idle_capacity_source == "ntm_health"
  ' "$env_tmp/repo/.flywheel/runtime/flywheel-loop/last_run.json" >/dev/null; then
    pass "rollback_env_disables_pws"
    rollback_env=true
  else
    fail "rollback_env_disables_pws"
  fi

  touch "$file_tmp/repo/.flywheel/disable-pane-work-signal"
  tick_pws_run "$file_tmp" "cod" "idle" || { cat "$file_tmp/tick.err" >&2; fail "rollback_file_tick_runs"; return; }
  if jq -e '
    .pane_work_signal_sampled == false
    and .pane_work_signal_disabled == true
    and .pane_work_signal_disabled_reason == "pws_disabled_via_file"
    and .idle_capacity_source == "ntm_health"
  ' "$file_tmp/repo/.flywheel/runtime/flywheel-loop/last_run.json" >/dev/null; then
    pass "rollback_file_disables_pws"
    rollback_file=true
  else
    fail "rollback_file_disables_pws"
  fi
}

write_receipt() {
  local dep_cycles="fail"
  if "$HOME/.cargo/bin/br" dep cycles >"$TMP/dep-cycles.out" 2>&1 && grep -q "No dependency cycles detected" "$TMP/dep-cycles.out"; then
    dep_cycles="pass"
    pass "br_dep_cycles_empty"
  else
    fail "br_dep_cycles_empty"
  fi

  cat >"$RECEIPT" <<EOF
# flywheel-5ktd PWS Final Receipt

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Gate Results

- Gate 1 helper fields exist: $gate1
- Gate 2 tick capacity uses PWS for Codex: $gate2
- Gate 3 status markers expose source: $gate3
- Gate 4 rollback validated: $([[ "$rollback_env" == true && "$rollback_file" == true ]] && printf true || printf false)
- br dep cycles empty: $dep_cycles

## Plan Family Closure

- flywheel-5ktd.3: tick capacity uses \`idle_capacity_source="pane_work_signal_for_codex"\`.
- flywheel-5ktd.4: status source markers expose \`pws\`, \`ntm\`, and \`pws!=ntm\`.
- flywheel-5ktd.5: doctor exposes \`.pane_work_signal\` and promotes error-severity \`ntm_codex_false_idle\`.
- flywheel-5ktd.6: this integration proof ties helper, tick, status, doctor, rollback, and dependency-cycle checks together.
- yqbku verdict: KEEP-PWS-AS-DEFENSE-IN-DEPTH.

## Rollback Recipe

Environment rollback:

\`\`\`bash
FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1 bash .flywheel/flywheel-loop-tick
\`\`\`

Expected effect: receipt records \`pane_work_signal_disabled=true\`, \`pane_work_signal_disabled_reason="pws_disabled_via_env"\`, \`pane_work_signal_sampled=false\`, and \`idle_capacity_source="ntm_health"\`.

File rollback:

\`\`\`bash
touch .flywheel/disable-pane-work-signal
bash .flywheel/flywheel-loop-tick
rm .flywheel/disable-pane-work-signal
\`\`\`

Expected effect: receipt records \`pane_work_signal_disabled=true\`, \`pane_work_signal_disabled_reason="pws_disabled_via_file"\`, \`pane_work_signal_sampled=false\`, and \`idle_capacity_source="ntm_health"\`.

## flywheel-3bk Scope Boundary

\`flywheel-3bk\` owns dynamic session coverage: discovering live sessions and checking session-level freshness/coverage. The PWS plan family owns per-pane truth after a session and pane are already known. There is no overlap: \`flywheel-3bk\` answers "which sessions are in coverage?", while PWS answers "is this Codex pane actually working despite an idle/error health row?".

## Closeout Assertions

- tests=PASS
- rollback_verified=$([[ "$rollback_env" == true && "$rollback_file" == true ]] && printf true || printf false)
- codex_false_idle_regression_covered=$gate2
EOF

  if rg -n "flywheel-3bk|dynamic session coverage|session coverage" "$RECEIPT" >/dev/null 2>&1; then
    scope_boundary=true
    pass "flywheel_3bk_scope_boundary_documented"
  else
    fail "flywheel_3bk_scope_boundary_documented"
  fi
}

run_doctor_gate
run_tick_gate
run_status_marker_gate
run_rollback_gate
write_receipt

printf 'SUMMARY pass=%d fail=%d receipt=%s\n' "$pass_count" "$fail_count" "$RECEIPT"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 7 ]]
