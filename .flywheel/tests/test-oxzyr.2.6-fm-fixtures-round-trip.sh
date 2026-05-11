#!/usr/bin/env bash
# .flywheel/tests/test-oxzyr.2.6-fm-fixtures-round-trip.sh
# Real fixture data + round-trip tests for 10 FMs (flywheel-oxzyr.2.6).
#
# Fixture suite at .flywheel/fixtures/doctor-mode/fm{1..10}/.
# Each FM dir has: corrupt-*, expected-*, undo-original.bak, README.md.
#
# Test mode per FM:
#   FM-5, FM-8, FM-10 : audit-only-retraction round-trip (no undo)
#   FM-6, FM-9        : byte-exact-undo round-trip (apply + undo + sha-equality)
#   FM-1..4, FM-7     : SKIPPED-fixture-ready (no flywheel-loop doctor function;
#                       fixture exists for upstream consumers)
#
# AGs:
#   AG1  fixture-suite well-formedness: 10 dirs × 4 files each = 40 mandatory files
#   AG2  FM-5  round-trip: retraction written; ledger row matches expected shape
#   AG3  FM-6  round-trip: detected=true + apply rewrites + undo restores byte-exact
#   AG4  FM-8  round-trip: 3 ledgers written (retraction + quarantine + fuckup-log)
#   AG5  FM-9  round-trip: 3 literal classes detected + apply rewrites + undo restores byte-exact
#   AG6  FM-10 round-trip: retraction written with demote_to=monitoring-only
#   AG7  5 SKIPPED FMs report explicit reason (no silent skip)
#   AG8  fixtures untouched by round-trip (sha-256 of canonical fixture stable post-test)
#   AG9  test runner has canonical-CLI surface (--help, --json)
#   AG10 bash -n syntax clean

set -uo pipefail

# ---------- canonical-CLI surface ----------
case "${1:-}" in
  --help|-h)
    cat <<'USG'
usage: test-oxzyr.2.6-fm-fixtures-round-trip.sh [--json]

Real fixture data + round-trip tests for 10 FMs (flywheel-oxzyr.2.6).

Options:
  --json   emit machine-readable summary (counts per FM)
  --help   show this help

Exit codes:
  0  all RUN tests PASS (SKIPPED tests are not failures)
  1  one or more RUN tests FAIL
  2  fixture-suite well-formedness failure (mandatory files missing)
USG
    exit 0 ;;
esac
JSON_OUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUT=1

# ---------- setup ----------
FW=/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop
FIX_ROOT=/Users/josh/Developer/flywheel/.flywheel/fixtures/doctor-mode
WORK=$(mktemp -d -t oxzyr.2.6.XXXXXX) || { echo "ERR: mktemp failed" >&2; exit 1; }
trap 'find "$WORK" -mindepth 1 -delete 2>/dev/null; rmdir "$WORK" 2>/dev/null || true' EXIT

# Sandbox state-dir paths so we don't pollute prod ledgers.
export FLYWHEEL_DOCTOR_UNDO_DIR="$WORK/undo"
export FLYWHEEL_FM5_RETRACTIONS="$WORK/state/fm5-retractions.jsonl"
export FLYWHEEL_FM8_RETRACTIONS="$WORK/state/fm8-retractions.jsonl"
export FLYWHEEL_FM8_QUARANTINE="$WORK/state/fm8-quarantine.jsonl"
export FLYWHEEL_FM8_FUCKUP_LOG="$WORK/state/fm8-fuckup-log.jsonl"
export FLYWHEEL_FM10_RETRACTIONS="$WORK/state/fm10-retractions.jsonl"
mkdir -p "$WORK/state"

pass=0
fail=0
skip=0
declare -a results
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1" >&2; results+=("PASS:$1"); }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; results+=("FAIL:$1"); }
s() { skip=$((skip+1)); printf 'SKIP %s\n' "$1" >&2; results+=("SKIP:$1"); }

sha_of() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# ---------- AG1: fixture-suite well-formedness ----------
mandatory_total=0
mandatory_missing=()
for fm in 1 2 3 4 5 6 7 8 9 10; do
  dir="$FIX_ROOT/fm$fm"
  for required in README.md undo-original.bak; do
    mandatory_total=$((mandatory_total+1))
    [[ -f "$dir/$required" ]] || mandatory_missing+=("fm$fm/$required")
  done
  # Each FM dir must have at least one corrupt-* + one expected-*.
  mandatory_total=$((mandatory_total+2))
  ls "$dir"/corrupt-* >/dev/null 2>&1 || mandatory_missing+=("fm$fm/corrupt-*")
  ls "$dir"/expected-* >/dev/null 2>&1 || mandatory_missing+=("fm$fm/expected-*")
done
if [[ "${#mandatory_missing[@]}" -eq 0 ]]; then
  p "AG1 fixture-suite well-formedness (10 dirs × 4 mandatory files = $mandatory_total / $mandatory_total)"
else
  f "AG1 fixture-suite well-formedness — missing: ${mandatory_missing[*]}"
fi

# Capture canonical fixture SHAs for AG8 post-test verification.
# bash 3.2 doesn't support associative arrays (declare -A), so use a single
# manifest file mapping path → sha.
PRE_SHA_MANIFEST="$WORK/pre-sha-manifest.txt"
: >"$PRE_SHA_MANIFEST"
for fm in 1 2 3 4 5 6 7 8 9 10; do
  dir="$FIX_ROOT/fm$fm"
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    printf '%s\t%s\n' "$(sha_of "$f")" "$f" >>"$PRE_SHA_MANIFEST"
  done < <(find "$dir" -maxdepth 1 -type f \( -name '*.json' -o -name '*.jsonl' -o -name '*.tmpl' -o -name '*.txt' -o -name '*.bak' -o -name 'README.md' \))
done

# ---------- AG2: FM-5 round-trip ----------
if [[ -f "$FIX_ROOT/fm5/corrupt-tick-row.jsonl" && -f "$FIX_ROOT/fm5/corrupt-prior-row.jsonl" ]]; then
  ROW=$(cat "$FIX_ROOT/fm5/corrupt-tick-row.jsonl")
  PRIOR=$(cat "$FIX_ROOT/fm5/corrupt-prior-row.jsonl")
  : >"$FLYWHEEL_FM5_RETRACTIONS"
  OUT=$("$FW" doctor fm5 --row "$ROW" --prior-row "$PRIOR" --apply --json 2>/dev/null); rc=$?
  DETECTED=$(printf '%s' "$OUT" | jq -r '.detected' 2>/dev/null)
  WRITTEN=$(printf '%s' "$OUT" | jq -r '.retraction_written' 2>/dev/null)
  LEDGER_ROWS=$(wc -l <"$FLYWHEEL_FM5_RETRACTIONS" 2>/dev/null | tr -d ' ')
  LEDGER_CLASS=$(jq -r '.retraction_reason' <"$FLYWHEEL_FM5_RETRACTIONS" 2>/dev/null | tail -1)
  if [[ "$rc" -eq 1 && "$DETECTED" == "true" && "$WRITTEN" == "true" && "$LEDGER_ROWS" -eq 1 && "$LEDGER_CLASS" == "stale_prompt_heartbeat" ]]; then
    p "AG2 FM-5 round-trip: detected+retraction (rc=1, ledger rows=1, class=$LEDGER_CLASS)"
  else
    f "AG2 FM-5 round-trip: rc=$rc detected=$DETECTED written=$WRITTEN ledger_rows=$LEDGER_ROWS class=$LEDGER_CLASS"
  fi
else
  f "AG2 FM-5 round-trip: fixture files missing"
fi

# ---------- AG3: FM-6 round-trip + byte-exact undo ----------
if [[ -f "$FIX_ROOT/fm6/corrupt-v0-config.json" ]]; then
  cp "$FIX_ROOT/fm6/corrupt-v0-config.json" "$WORK/fm6-target.json"
  FM6_PRE_SHA=$(sha_of "$WORK/fm6-target.json")
  RUN_ID="fm6-test-$$-$(date -u +%s)"
  OUT=$("$FW" doctor fm6 --target "$WORK/fm6-target.json" --apply --run-id "$RUN_ID" --json 2>/dev/null); apply_rc=$?
  DETECTED=$(printf '%s' "$OUT" | jq -r '.detected' 2>/dev/null)
  BACKED=$(printf '%s' "$OUT" | jq -r '.backup_written' 2>/dev/null)
  if jq -e 'has("_unknown_keys_archive")' "$WORK/fm6-target.json" >/dev/null 2>&1; then
    POST_HAS_ARCHIVE=true
  else
    POST_HAS_ARCHIVE=false
  fi
  # Now undo
  OUT2=$("$FW" doctor undo "$RUN_ID" --apply --json 2>/dev/null); undo_rc=$?
  RESTORED_SHA=$(sha_of "$WORK/fm6-target.json")
  if [[ "$apply_rc" -eq 1 && "$DETECTED" == "true" && "$BACKED" == "true" && "$POST_HAS_ARCHIVE" == "true" && "$undo_rc" -eq 0 && "$RESTORED_SHA" == "$FM6_PRE_SHA" ]]; then
    p "AG3 FM-6 round-trip + byte-exact undo (apply rc=1 backup=true; undo rc=0 restored_sha matches pre_sha)"
  else
    f "AG3 FM-6 round-trip got apply_rc=$apply_rc detected=$DETECTED backup=$BACKED archive=$POST_HAS_ARCHIVE undo_rc=$undo_rc sha_match=$([[ "$RESTORED_SHA" == "$FM6_PRE_SHA" ]] && echo yes || echo no)"
  fi
else
  f "AG3 FM-6 fixture missing"
fi

# ---------- AG4: FM-8 round-trip (3 ledgers) ----------
if [[ -f "$FIX_ROOT/fm8/corrupt-dispatch.json" && -f "$FIX_ROOT/fm8/corrupt-validation-tail.txt" ]]; then
  DISPATCH=$(cat "$FIX_ROOT/fm8/corrupt-dispatch.json")
  cp "$FIX_ROOT/fm8/corrupt-validation-tail.txt" "$WORK/fm8-tail.txt"
  : >"$FLYWHEEL_FM8_RETRACTIONS"
  : >"$FLYWHEEL_FM8_QUARANTINE"
  : >"$FLYWHEEL_FM8_FUCKUP_LOG"
  OUT=$("$FW" doctor fm8 --dispatch "$DISPATCH" --validation-tail "$WORK/fm8-tail.txt" --apply --json 2>/dev/null); rc=$?
  DETECTED=$(printf '%s' "$OUT" | jq -r '.detected' 2>/dev/null)
  RET_ROWS=$(wc -l <"$FLYWHEEL_FM8_RETRACTIONS" 2>/dev/null | tr -d ' ')
  QUA_ROWS=$(wc -l <"$FLYWHEEL_FM8_QUARANTINE" 2>/dev/null | tr -d ' ')
  FUK_ROWS=$(wc -l <"$FLYWHEEL_FM8_FUCKUP_LOG" 2>/dev/null | tr -d ' ')
  if [[ "$rc" -eq 1 && "$DETECTED" == "true" && "$RET_ROWS" -ge 1 && "$QUA_ROWS" -ge 1 && "$FUK_ROWS" -ge 1 ]]; then
    p "AG4 FM-8 round-trip: 3 ledgers written (ret=$RET_ROWS quarantine=$QUA_ROWS fuckup=$FUK_ROWS)"
  else
    f "AG4 FM-8 round-trip: rc=$rc detected=$DETECTED ret=$RET_ROWS quarantine=$QUA_ROWS fuckup=$FUK_ROWS"
  fi
else
  f "AG4 FM-8 fixture missing"
fi

# ---------- AG5: FM-9 round-trip + byte-exact undo ----------
if [[ -f "$FIX_ROOT/fm9/corrupt-tmpl-with-literal.tmpl" ]]; then
  cp "$FIX_ROOT/fm9/corrupt-tmpl-with-literal.tmpl" "$WORK/fm9-template.tmpl"
  FM9_PRE_SHA=$(sha_of "$WORK/fm9-template.tmpl")
  RUN_ID="fm9-test-$$-$(date -u +%s)"
  OUT=$("$FW" doctor fm9 --template "$WORK/fm9-template.tmpl" --apply --run-id "$RUN_ID" --json 2>/dev/null); apply_rc=$?
  DETECTED=$(printf '%s' "$OUT" | jq -r '.detected' 2>/dev/null)
  TOTAL=$(printf '%s' "$OUT" | jq -r '.findings.total' 2>/dev/null)
  BACKED=$(printf '%s' "$OUT" | jq -r '.backup_written' 2>/dev/null)
  HAS_HOME=$(grep -c '{{user_home}}' "$WORK/fm9-template.tmpl" 2>/dev/null || echo 0)
  HAS_BEAD=$(grep -c '{{bead_id}}' "$WORK/fm9-template.tmpl" 2>/dev/null || echo 0)
  HAS_SHA=$(grep -c '{{sha}}' "$WORK/fm9-template.tmpl" 2>/dev/null || echo 0)
  # Undo
  OUT2=$("$FW" doctor undo "$RUN_ID" --apply --json 2>/dev/null); undo_rc=$?
  RESTORED_SHA=$(sha_of "$WORK/fm9-template.tmpl")
  if [[ "$apply_rc" -eq 1 && "$DETECTED" == "true" && "$TOTAL" -ge 3 && "$BACKED" == "true" \
        && "$HAS_HOME" -ge 1 && "$HAS_BEAD" -ge 1 && "$HAS_SHA" -ge 1 \
        && "$undo_rc" -eq 0 && "$RESTORED_SHA" == "$FM9_PRE_SHA" ]]; then
    p "AG5 FM-9 round-trip + byte-exact undo (3 classes detected; {{user_home}}+{{bead_id}}+{{sha}} substituted; undo restored)"
  else
    f "AG5 FM-9 round-trip got apply_rc=$apply_rc detected=$DETECTED total=$TOTAL backup=$BACKED home=$HAS_HOME bead=$HAS_BEAD sha=$HAS_SHA undo_rc=$undo_rc sha_match=$([[ "$RESTORED_SHA" == "$FM9_PRE_SHA" ]] && echo yes || echo no)"
  fi
else
  f "AG5 FM-9 fixture missing"
fi

# ---------- AG6: FM-10 round-trip ----------
if [[ -f "$FIX_ROOT/fm10/corrupt-candidate.json" && -f "$FIX_ROOT/fm10/corrupt-validation-tail.txt" ]]; then
  CAND=$(cat "$FIX_ROOT/fm10/corrupt-candidate.json")
  cp "$FIX_ROOT/fm10/corrupt-validation-tail.txt" "$WORK/fm10-tail.txt"
  : >"$FLYWHEEL_FM10_RETRACTIONS"
  OUT=$("$FW" doctor fm10 --candidate "$CAND" --validation-tail "$WORK/fm10-tail.txt" --apply --json 2>/dev/null); rc=$?
  DETECTED=$(printf '%s' "$OUT" | jq -r '.detected' 2>/dev/null)
  SUBMITS=$(printf '%s' "$OUT" | jq -r '.submits_work' 2>/dev/null)
  WRITTEN=$(printf '%s' "$OUT" | jq -r '.retraction_written' 2>/dev/null)
  LEDGER_ROWS=$(wc -l <"$FLYWHEEL_FM10_RETRACTIONS" 2>/dev/null | tr -d ' ')
  DEMOTE=$(jq -r '.demote_to' <"$FLYWHEEL_FM10_RETRACTIONS" 2>/dev/null | tail -1)
  if [[ "$rc" -eq 1 && "$DETECTED" == "true" && "$SUBMITS" == "true" && "$WRITTEN" == "true" && "$LEDGER_ROWS" -eq 1 && "$DEMOTE" == "monitoring-only" ]]; then
    p "AG6 FM-10 round-trip: detected+retraction (demote_to=$DEMOTE)"
  else
    f "AG6 FM-10 round-trip: rc=$rc detected=$DETECTED submits=$SUBMITS written=$WRITTEN rows=$LEDGER_ROWS demote=$DEMOTE"
  fi
else
  f "AG6 FM-10 fixture missing"
fi

# ---------- AG7: 5 SKIPPED FMs report explicit reason ----------
skipped_with_reason=0
for fm in 1 2 3 4 7; do
  rdme="$FIX_ROOT/fm$fm/README.md"
  if [[ -f "$rdme" ]] && grep -qE 'Test mode:\*\* SKIPPED-fixture-ready' "$rdme"; then
    skipped_with_reason=$((skipped_with_reason+1))
    s "FM-$fm SKIPPED-fixture-ready (no _flywheel_loop_fm${fm}_detect_fix function)"
  else
    f "AG7 sub: FM-$fm missing SKIPPED-fixture-ready marker in README.md"
  fi
done
if [[ "$skipped_with_reason" -eq 5 ]]; then
  p "AG7 all 5 unimplemented FMs (1,2,3,4,7) skipped with explicit reason"
fi

# ---------- AG8: fixtures untouched (post-test SHA equality) ----------
unchanged=0
changed_list=""
while IFS=$'\t' read -r expected_sha path; do
  [[ -n "$path" ]] || continue
  cur_sha=$(sha_of "$path")
  if [[ "$cur_sha" == "$expected_sha" ]]; then
    unchanged=$((unchanged+1))
  else
    changed_list="$changed_list $path"
  fi
done <"$PRE_SHA_MANIFEST"
if [[ -z "$changed_list" && "$unchanged" -gt 0 ]]; then
  p "AG8 fixture files untouched by round-trip ($unchanged files SHA-equal pre/post)"
else
  f "AG8 fixture files mutated by test:$changed_list"
fi

# ---------- AG9: canonical-CLI surface (--help) ----------
HELP_OUT=$(bash "$0" --help 2>&1)
if echo "$HELP_OUT" | grep -q 'usage:' && echo "$HELP_OUT" | grep -q -- '--json'; then
  p "AG9 canonical-CLI surface: --help emits usage with --json flag advertised"
else
  f "AG9 --help missing canonical surface: $(echo "$HELP_OUT" | head -1)"
fi

# ---------- AG10: bash -n syntax check ----------
if bash -n "$0" 2>/dev/null; then
  p "AG10 bash -n self-syntax clean"
else
  f "AG10 bash -n self-syntax failed"
fi

# ---------- summary ----------
total_run=$((pass + fail))
if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc \
    --argjson pass "$pass" --argjson fail "$fail" --argjson skip "$skip" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:"oxzyr.2.6.fixtures.round_trip/v1", ts:$ts,
      pass:$pass, fail:$fail, skip:$skip,
      fms_implemented:["FM-5","FM-6","FM-8","FM-9","FM-10"],
      fms_skipped:["FM-1","FM-2","FM-3","FM-4","FM-7"],
      byte_exact_undo_class:["FM-6","FM-9"]}'
else
  printf '\n%d passed, %d failed, %d skipped (SKIPPED FMs have fixtures but no detect/fix function)\n' \
    "$pass" "$fail" "$skip"
fi
exit "$fail"
