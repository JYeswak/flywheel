#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-success-measurement.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-success-measurement-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_count=0

pass() { printf 'PASS %s\n' "$1" >&2; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

digest_text() {
  python3 - "$1" <<'PY'
import hashlib, sys
text = sys.argv[1]
print(hashlib.sha256("\n".join(text.splitlines()[-30:]).encode()).hexdigest())
PY
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_fake_ntm() {
  cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_NTM_STATE:?}"
mkdir -p "$state"
case "${1:-}" in
  copy)
    count_file="$state/copy-count"
    count="$(($(cat "$count_file" 2>/dev/null || printf 0) + 1))"
    printf '%s\n' "$count" >"$count_file"
    out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --output) out="${2:?}"; shift 2 ;;
        --output=*) out="${1#*=}"; shift ;;
        *) shift ;;
      esac
    done
    mode="$(cat "$state/mode")"
    [[ "$mode" != "probe-error" ]] || exit 7
    cat "$state/sample-$count.txt" >"$out"
    ;;
  --robot-activity=*)
    count_file="$state/activity-count"
    count="$(($(cat "$count_file" 2>/dev/null || printf 0) + 1))"
    printf '%s\n' "$count" >"$count_file"
    cat "$state/activity-$count.json" 2>/dev/null || jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
  chmod +x "$TMP/fake-ntm.sh"
}

make_state() {
  local name="$1" mode="$2" s1="$3" s2="$4" s3="$5" activity="${6:-waiting}"
  local dir="$TMP/$name-state"
  mkdir -p "$dir"
  printf '%s\n' "$mode" >"$dir/mode"
  printf '%s\n' "$s1" >"$dir/sample-1.txt"
  printf '%s\n' "$s2" >"$dir/sample-2.txt"
  printf '%s\n' "$s3" >"$dir/sample-3.txt"
  case "$activity" in
    transition)
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-1.json"
      jq -nc '{agents:[{pane_idx:2,state:"THINKING",velocity:0}]}' >"$dir/activity-2.json"
      jq -nc '{agents:[{pane_idx:2,state:"THINKING",velocity:0}]}' >"$dir/activity-3.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-4.json"
      ;;
    velocity)
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-1.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:2}]}' >"$dir/activity-2.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-3.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-4.json"
      ;;
    *)
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-1.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-2.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-3.json"
      jq -nc '{agents:[{pane_idx:2,state:"WAITING",velocity:0}]}' >"$dir/activity-4.json"
      ;;
  esac
  printf '%s\n' "$dir"
}

run_case() {
  local name="$1" expected_rc="$2" state="$3" pre_digest="$4" out rc
  out="$TMP/$name.out"
  set +e
  FAKE_NTM_STATE="$state" bash "$SCRIPT" --ntm-bin "$TMP/fake-ntm.sh" --session fixture --pane 2 --pre-digest "$pre_digest" --sample-delays 0,0,0 --json >"$out" 2>"$TMP/$name.err"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$out" >&2 || true
  fi
  case_count=$((case_count + 1))
  RUN_OUT="$out"
}

write_fake_ntm
bash -n "$SCRIPT" && pass "success_measurement_syntax" || fail "success_measurement_syntax"
"$SCRIPT" --info --json | jq -e '.read_only==true and (.verbs | length)==8 and (.verbs | index("--pre-digest"))' >/dev/null && pass "info_json" || fail "info_json"
"$SCRIPT" --examples --json | jq -e '.examples | length == 2' >/dev/null && pass "examples_json" || fail "examples_json"

capacity=$'selected model is at capacity\n\n›'
clean=$'normal output\n\n› continue accepted'
changed_capacity=$'selected model is at capacity\nnew token\n\n›'
capacity_digest="$(digest_text "$capacity")"
clean_digest="$(digest_text "$clean")"

state="$(make_state delta_text_gone ok "$capacity" "$clean" "$clean")"
run_case delta_text_gone 0 "$state" "$capacity_digest"
assert_jq "$RUN_OUT" '.status=="success" and .criteria.output_delta==true and .criteria.capacity_text_gone==true' "delta_text_gone_success"

state="$(make_state unchanged_capacity ok "$capacity" "$capacity" "$capacity")"
run_case unchanged_capacity 1 "$state" "$capacity_digest"
assert_jq "$RUN_OUT" '.status=="failure" and .criteria.output_delta==false and .criteria.capacity_text_gone==false' "unchanged_capacity_failure"

state="$(make_state delta_wins ok "$capacity" "$changed_capacity" "$changed_capacity")"
run_case delta_wins 0 "$state" "$capacity_digest"
assert_jq "$RUN_OUT" '.status=="success" and .criteria.output_delta==true and .criteria.capacity_text_gone==false' "delta_wins_success"

state="$(make_state text_gone_wins ok "$clean" "$clean" "$clean")"
run_case text_gone_wins 0 "$state" "$clean_digest"
assert_jq "$RUN_OUT" '.status=="success" and .criteria.output_delta==false and .criteria.capacity_text_gone==true' "text_gone_wins_success"

state="$(make_state activity_transition ok "$capacity" "$capacity" "$capacity" transition)"
run_case activity_transition 0 "$state" "$capacity_digest"
assert_jq "$RUN_OUT" '.status=="success" and .criteria.activity_transition==true' "activity_transition_success"

state="$(make_state probe_error probe-error "$capacity" "$capacity" "$capacity")"
run_case probe_error 4 "$state" "$capacity_digest"
assert_jq "$RUN_OUT" '.status=="inconclusive" and .reason=="probe_error"' "probe_error_inconclusive"

out="$TMP/malformed.out"
set +e
bash "$SCRIPT" --ntm-bin "$TMP/fake-ntm.sh" --session fixture --pane nope --pre-digest "$capacity_digest" --sample-delays 0,0,0 --json >"$out" 2>/dev/null
rc=$?
set -e
[[ "$rc" -eq 3 ]] && pass "malformed rc=3" || fail "malformed rc=3"
assert_jq "$out" '.status=="malformed" and .verdict=="inconclusive"' "malformed_payload"
case_count=$((case_count + 1))

printf 'Summary: %s cases, %s passed, %s failed\n' "$case_count" "$pass_count" "$fail_count"
[[ "$case_count" -eq 7 && "$fail_count" -eq 0 ]]
