#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/pane-work-signal.sh"
FIXTURES="$ROOT/tests/fixtures/pane-work-signal"

pass=0
fail=0
SESSION="fixture"
PANE=2
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
STATE_DIR="$TMPDIR/state"
JSONL="$STATE_DIR/pane-work-signal.jsonl"

check() {
    local label="$1" result="$2"
    if [[ "$result" == "ok" ]]; then
        printf 'PASS: %s\n' "$label"
        pass=$((pass+1))
    else
        printf 'FAIL: %s\n' "$label"
        fail=$((fail+1))
    fi
}

extract_meta() {
    local file="$1" key="$2"
    grep "^# ${key}:" "$file" | head -n1 | sed -E "s/^# ${key}: //" || true
}

classify_fixture() {
    local fixture="$1"
    local ntm_state
    local is_codex
    local age
    local lines
    local rows_hash
    local working_line
    local hash_delta
    local ts_epoch
    local ts

    ntm_state="$(extract_meta "$fixture" "ntm_health")"
    is_codex="$(extract_meta "$fixture" "is_codex")"
    age="$(extract_meta "$fixture" "age_seconds")"
    if [[ -z "$age" ]]; then
        age="0"
    fi
    hash_delta="$(extract_meta "$fixture" "hash_delta")"

    ts_epoch="$(($(date -u +%s) - age))"
    ts="$(date -u -r "$ts_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$ts_epoch" +%Y-%m-%dT%H:%M:%SZ)"
    lines="$(sed '/^#/d' "$fixture")"
    rows_hash="$(printf '%s\n' "$lines" | shasum | cut -c1-12)"
    working_line="$(printf '%s\n' "$lines" | tail -n 12 | grep -m1 -E 'Working \([0-9]+s\)' || true)"
    mkdir -p "$STATE_DIR"
    : > "$JSONL"

    AGENT_KIND="codex"
    if [[ "${is_codex}" == "false" ]]; then
        AGENT_KIND="shell"
    fi

    if [[ "$hash_delta" == "true" ]]; then
        jq -cn \
            --arg ts "$ts" \
            --arg session "$SESSION" \
            --argjson pane "$PANE" \
            --arg agent_kind "$AGENT_KIND" \
            --arg ntm_activity "$ntm_state" \
            '{ts:$ts,session:$session,pane:($pane|tonumber),hash:"previoushash",lines:1,bytes:2,agent_kind:$agent_kind,ntm_activity:$ntm_activity,ntm_stage:$ntm_activity,ntm_idle_s:0,foreground_working_state:false,foreground_working_evidence:"",truth_state:"sample",truth_source:"sample",truth_reason:"fixture_previous_hash"}' \
            >> "$JSONL"
    fi

    jq -cn \
        --arg ts "$ts" \
        --arg session "$SESSION" \
        --argjson pane "$PANE" \
        --arg hash "$rows_hash" \
        --argjson lines_count "$(printf '%s\n' "$lines" | wc -l | tr -d ' ')" \
        --argjson bytes_count "$(printf '%s\n' "$lines" | wc -c | tr -d ' ')" \
        --arg agent_kind "$AGENT_KIND" \
        --arg ntm_activity "$ntm_state" \
        --argjson foreground_working_state "$(if [[ -n "$working_line" ]]; then echo true; else echo false; fi)" \
        --arg foreground_working_evidence "$working_line" \
        '{ts:$ts,session:$session,pane:($pane|tonumber),hash:$hash,lines:$lines_count,bytes:$bytes_count,agent_kind:$agent_kind,ntm_activity:$ntm_activity,ntm_stage:$ntm_activity,ntm_idle_s:0,foreground_working_state:($foreground_working_state),foreground_working_evidence:$foreground_working_evidence,truth_state:"sample",truth_source:"sample",truth_reason:"fixture"}' \
        >> "$JSONL"
}

printf '=== pane-work-signal helper self test ===\n'

if test -d "$FIXTURES"; then
  check "fixture directory exists" "ok"
else
  check "fixture directory exists" "fail"
fi

count=$(find "$FIXTURES" -type f | wc -l | tr -d ' ')
if [[ "$count" -ge 6 ]]; then
  check "at least 6 fixture files (got $count)" "ok"
else
  check "at least 6 fixture files (got $count)" "fail"
fi

for f in "$FIXTURES"/*.txt; do
  fname=$(basename "$f")
  if grep -q "^# truth_state:" "$f" && grep -q "^# ntm_health:" "$f" && grep -q "^# pws_truth:" "$f"; then
    check "fixture $fname has truth metadata" "ok"
  else
    check "fixture $fname has truth metadata" "fail"
  fi
done

rg -q "Working \\(" "$FIXTURES" && check "Working (...) appears in corpus" "ok" || check "Working (...) appears in corpus" "fail"

if grep -rq "ntm_health: idle" "$FIXTURES" && grep -rq "pws_truth: working" "$FIXTURES"; then
  check "false-idle case represented" "ok"
else
  check "false-idle case represented" "fail"
fi

if grep -Eq "Working \([0-9]+s\)" "$FIXTURES/02-codex-tail3-miss.txt" && \
   sed '/^#/d' "$FIXTURES/02-codex-tail3-miss.txt" | tail -n 12 | grep -Eq "Working \([0-9]+s\)"; then
  check "tail-3 false-negative fixture catches foreground within 12 lines" "ok"
else
  check "tail-3 false-negative fixture catches foreground within 12 lines" "fail"
fi

if grep -q "age_seconds: 360" "$FIXTURES/05-stale-sample.txt"; then
  check "fixture 05 stale sample age metadata" "ok"
else
  check "fixture 05 stale sample age metadata" "fail"
fi

for f in "$FIXTURES"/*.txt; do
  fname=$(basename "$f")
  expected_truth="$(extract_meta "$f" "truth_state")"
  expected_source="pane_work_signal"
  if [[ "$fname" == "06-non-codex-ntm-canonical.txt" ]]; then
    expected_source="ntm_health"
  fi

  classify_fixture "$f"
  out="$(FLYWHEEL_STATE_DIR="$STATE_DIR" "$SCRIPT" --classify "$SESSION" "$PANE")"
  actual_truth="$(jq -r '.truth_state' <<<"$out")"
  actual_source="$(jq -r '.truth_source // "missing"' <<<"$out")"
  actual_reason="$(jq -r '.truth_reason // ""' <<<"$out")"

  if [[ "$actual_truth" == "$expected_truth" ]]; then
    check "fixture $fname truth_state=$expected_truth" "ok"
  else
    check "fixture $fname truth_state=$expected_truth" "fail"
  fi

  if [[ "$actual_source" == "$expected_source" ]]; then
    check "fixture $fname truth_source=$expected_source" "ok"
  else
    check "fixture $fname truth_source=$expected_source" "fail"
  fi

  if [[ "$fname" == "05-stale-sample.txt" ]]; then
    if [[ "$actual_reason" == *"no_usable_sample"* ]]; then
      check "stale fixture names stale reason" "ok"
    else
      check "stale fixture names stale reason" "fail"
    fi
  fi

  if [[ "$fname" == "02-codex-tail3-miss.txt" ]]; then
    if jq -r '.foreground_working_evidence // empty' <<<"$out" | grep -q "Working"; then
      check "tail3 miss fixture retains foreground evidence" "ok"
    else
      check "tail3 miss fixture retains foreground evidence" "fail"
    fi
  fi
done

printf '\nSummary: %d pass, %d fail\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
