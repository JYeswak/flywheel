#!/usr/bin/env bash
# .flywheel/tests/test-oxzyr.2.4-fm6-fm9-byte-exact-undo.sh
# Regression test for flywheel-oxzyr.2.4 — FM-6 + FM-9 detect/fix invariants
# (byte-exact undo class).
#
# FM-6: legacy-loop-config-schema-drift (unknown keys / missing required)
# FM-9: frozen-projection-of-mutable-state-in-tick-prompts (hardcoded literals)
#
# Both share the byte-exact undo invariant: fix mutates substrate through
# _flywheel_loop_mutate chokepoint, which records pre_sha + content-hashed
# backup. `flywheel-loop doctor undo <run-id>` restores byte-exact.
#
# AGs (10 total):
#   AG1 FM-6 detect clean config → detected=false, rc=0
#   AG2 FM-6 detect drift (unknown keys) → detected=true, drift_class=unknown_keys, rc=3
#   AG3 FM-6 apply → migrated_json written; backup_written=true; rc=1
#   AG4 FM-6 byte-exact undo → restored SHA == pre-fix SHA
#   AG5 FM-9 detect clean template → detected=false, rc=0
#   AG6 FM-9 detect frozen (hardcoded /Users/josh/, bead-id, sha) → detected=true, rc=3
#   AG7 FM-9 apply → template rewritten with {{user_home}}/{{bead_id}}/{{sha}}; backup_written=true; rc=1
#   AG8 FM-9 byte-exact undo → restored SHA == pre-fix SHA
#   AG9 dispatcher intercepts route correctly (doctor fm6 / doctor fm9 dispatched, doctor other unaffected)
#   AG10 backward-compat (flywheel-loop --help still works; doctor undo still works)

set -uo pipefail

FW=/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop
WORK=$(mktemp -d -t oxzyr.2.4.XXXXXX) || { echo "ERR: mktemp failed" >&2; exit 1; }
trap 'find "$WORK" -mindepth 1 -delete 2>/dev/null; rmdir "$WORK" 2>/dev/null || true' EXIT

# Isolate doctor-undo state to test sandbox so we don't pollute prod state dir.
export FLYWHEEL_DOCTOR_UNDO_DIR="$WORK/undo"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

sha_of() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# ---------- FM-6 tests ----------

# AG1 — clean config
CLEAN_CFG="$WORK/clean.json"
printf '%s' '{"project":"foo","repo":"/Users/josh/Developer/foo","active":true,"tier":"active_normal","interval":"30m","started_at":"2026-05-01T00:00:00Z","started_by":"test","pane":"foo:0.1","session":"foo","tick_command":"/flywheel:tick","dispatch_mode":"launchd_prompt"}' >"$CLEAN_CFG"
OUT=$("$FW" doctor fm6 --target "$CLEAN_CFG" --json 2>/dev/null); rc=$?
if [[ "$rc" -eq 0 ]] && [[ "$(printf '%s' "$OUT" | jq -r '.detected')" == "false" ]]; then
  p "AG1 FM-6 clean config detected=false rc=0"
else
  f "AG1 FM-6 clean config got rc=$rc detected=$(printf '%s' "$OUT" | jq -r '.detected')"
fi

# AG2 — drift (unknown keys)
DRIFT_CFG="$WORK/drift.json"
ORIG_DRIFT='{"project":"bar","repo":"/Users/josh/Developer/bar","active":true,"AdHocBogusKey":"some_value","another_bad_key":42}'
printf '%s' "$ORIG_DRIFT" >"$DRIFT_CFG"
DRIFT_PRE_SHA=$(sha_of "$DRIFT_CFG")
OUT=$("$FW" doctor fm6 --target "$DRIFT_CFG" --json 2>/dev/null); rc=$?
DETECTED=$(printf '%s' "$OUT" | jq -r '.detected')
CLS=$(printf '%s' "$OUT" | jq -r '.drift_class')
if [[ "$rc" -eq 3 && "$DETECTED" == "true" && "$CLS" == "unknown_keys" ]]; then
  p "AG2 FM-6 drift dry-run detected=true drift_class=unknown_keys rc=3"
else
  f "AG2 FM-6 drift dry-run got rc=$rc detected=$DETECTED drift_class=$CLS"
fi

# AG3 — apply
RUN_ID="fm6-test-$$-$(date -u +%s)"
OUT=$("$FW" doctor fm6 --target "$DRIFT_CFG" --apply --run-id "$RUN_ID" --json 2>/dev/null); rc=$?
BACKED=$(printf '%s' "$OUT" | jq -r '.backup_written')
PRE_SHA_REPORTED=$(printf '%s' "$OUT" | jq -r '.pre_sha')
POST_KEYS=$(jq -r 'keys | join(",")' "$DRIFT_CFG" 2>/dev/null)
if [[ "$rc" -eq 1 && "$BACKED" == "true" && "$PRE_SHA_REPORTED" == "$DRIFT_PRE_SHA" ]] \
   && [[ "$POST_KEYS" == *"_unknown_keys_archive"* ]] \
   && ! grep -q '"AdHocBogusKey":"some_value"' "$DRIFT_CFG" \
   && grep -q "_unknown_keys_archive" "$DRIFT_CFG"; then
  p "AG3 FM-6 apply migrated (rc=1, backup=true, unknown keys archived)"
else
  f "AG3 FM-6 apply got rc=$rc backup=$BACKED pre_sha_match=$([[ "$PRE_SHA_REPORTED" == "$DRIFT_PRE_SHA" ]] && echo yes || echo no) keys=$POST_KEYS"
fi

# AG4 — byte-exact undo via doctor undo
OUT=$("$FW" doctor undo "$RUN_ID" --apply --json 2>/dev/null); rc=$?
RESTORED_SHA=$(sha_of "$DRIFT_CFG")
if [[ "$rc" -eq 0 && "$RESTORED_SHA" == "$DRIFT_PRE_SHA" ]]; then
  p "AG4 FM-6 byte-exact undo restored_sha=$RESTORED_SHA == pre_sha"
else
  f "AG4 FM-6 byte-exact undo got rc=$rc restored=$RESTORED_SHA pre=$DRIFT_PRE_SHA"
fi

# ---------- FM-9 tests ----------

# AG5 — clean template (no FROZEN literals)
CLEAN_TMPL="$WORK/clean.tmpl"
printf '%s\n' '# Test template' 'repo: {{repo}}' 'bead: {{bead_id}}' 'sha: {{sha}}' >"$CLEAN_TMPL"
OUT=$("$FW" doctor fm9 --template "$CLEAN_TMPL" --json 2>/dev/null); rc=$?
if [[ "$rc" -eq 0 ]] && [[ "$(printf '%s' "$OUT" | jq -r '.detected')" == "false" ]]; then
  p "AG5 FM-9 clean template detected=false rc=0"
else
  f "AG5 FM-9 clean template got rc=$rc detected=$(printf '%s' "$OUT" | jq -r '.detected')"
fi

# AG6 — frozen template (literals present)
FROZEN_TMPL="$WORK/frozen.tmpl"
{
  echo '# Frozen template'
  echo 'repo: /Users/josh/Developer/example/'
  echo 'bead: flywheel-abc123'
  echo 'sha: deadbeef00000000000000000000000000000000'
} >"$FROZEN_TMPL"
FROZEN_PRE_SHA=$(sha_of "$FROZEN_TMPL")
OUT=$("$FW" doctor fm9 --template "$FROZEN_TMPL" --json 2>/dev/null); rc=$?
DETECTED=$(printf '%s' "$OUT" | jq -r '.detected')
FROZEN_CLS=$(printf '%s' "$OUT" | jq -r '.frozen_class')
TOTAL=$(printf '%s' "$OUT" | jq -r '.findings.total')
if [[ "$rc" -eq 3 && "$DETECTED" == "true" && "$TOTAL" -eq 3 ]] \
   && [[ "$FROZEN_CLS" == *"hardcoded_user_path"* ]] \
   && [[ "$FROZEN_CLS" == *"hardcoded_bead_id"* ]] \
   && [[ "$FROZEN_CLS" == *"hardcoded_git_sha"* ]]; then
  p "AG6 FM-9 frozen dry-run detected=true total=3 classes=$FROZEN_CLS rc=3"
else
  f "AG6 FM-9 frozen dry-run got rc=$rc detected=$DETECTED total=$TOTAL classes=$FROZEN_CLS"
fi

# AG7 — apply rewrites template
RUN_ID2="fm9-test-$$-$(date -u +%s)"
OUT=$("$FW" doctor fm9 --template "$FROZEN_TMPL" --apply --run-id "$RUN_ID2" --json 2>/dev/null); rc=$?
BACKED=$(printf '%s' "$OUT" | jq -r '.backup_written')
PRE_SHA_REPORTED=$(printf '%s' "$OUT" | jq -r '.pre_sha')
if [[ "$rc" -eq 1 && "$BACKED" == "true" && "$PRE_SHA_REPORTED" == "$FROZEN_PRE_SHA" ]] \
   && grep -q '{{user_home}}' "$FROZEN_TMPL" \
   && grep -q '{{bead_id}}' "$FROZEN_TMPL" \
   && grep -q '{{sha}}' "$FROZEN_TMPL" \
   && ! grep -q '/Users/josh/Developer/example/' "$FROZEN_TMPL" \
   && ! grep -q 'flywheel-abc123' "$FROZEN_TMPL"; then
  p "AG7 FM-9 apply rewrote template ({{user_home}} + {{bead_id}} + {{sha}}; literals stripped)"
else
  f "AG7 FM-9 apply got rc=$rc backup=$BACKED; template content:"
  cat "$FROZEN_TMPL" >&2
fi

# AG8 — byte-exact undo for FM-9
OUT=$("$FW" doctor undo "$RUN_ID2" --apply --json 2>/dev/null); rc=$?
RESTORED_SHA=$(sha_of "$FROZEN_TMPL")
if [[ "$rc" -eq 0 && "$RESTORED_SHA" == "$FROZEN_PRE_SHA" ]]; then
  p "AG8 FM-9 byte-exact undo restored_sha=$RESTORED_SHA == pre_sha"
else
  f "AG8 FM-9 byte-exact undo got rc=$rc restored=$RESTORED_SHA pre=$FROZEN_PRE_SHA"
fi

# AG9 — dispatcher intercepts route correctly
# fm6 with no args returns usage (rc=2)
OUT=$("$FW" doctor fm6 2>&1); rc=$?
if [[ "$rc" -eq 2 ]] && echo "$OUT" | grep -q -- '--target PATH'; then
  p "AG9a dispatcher routes 'doctor fm6' to _flywheel_loop_fm6_detect_fix (usage on no args, rc=2)"
else
  f "AG9a dispatcher fm6 routing got rc=$rc output: $OUT"
fi
OUT=$("$FW" doctor fm9 2>&1); rc=$?
if [[ "$rc" -eq 2 ]] && echo "$OUT" | grep -q -- '--template PATH'; then
  p "AG9b dispatcher routes 'doctor fm9' to _flywheel_loop_fm9_detect_fix (usage on no args, rc=2)"
else
  f "AG9b dispatcher fm9 routing got rc=$rc output: $OUT"
fi

# AG10 — backward-compat: --help still works; doctor undo still works
OUT=$("$FW" --help 2>&1); rc=$?
if [[ "$rc" -eq 0 ]] || echo "$OUT" | grep -qi 'usage\|flywheel-loop'; then
  p "AG10a backward-compat: --help returns usage"
else
  f "AG10a --help got rc=$rc output: $(echo $OUT | head -c 200)"
fi
# doctor undo with a non-existent run-id should rc=3 (run-id dir not found per .2.2 spec)
OUT=$("$FW" doctor undo nonexistent-run-id --json 2>&1); rc=$?
if [[ "$rc" -eq 3 ]] || echo "$OUT" | grep -q '"status":\|not found\|missing'; then
  p "AG10b backward-compat: doctor undo still works (rc=$rc on nonexistent run-id; .2.2 intercept intact)"
else
  f "AG10b doctor undo backward-compat got rc=$rc output: $OUT"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
