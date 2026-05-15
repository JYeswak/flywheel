#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bead-blocker-sync.py"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t bead-blocker-sync.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fixture="$TMP/blocked.json"
repo="$TMP/repo"
blockers="$repo/.flywheel/state/blockers"
mkdir -p "$repo/.flywheel/state"

cat >"$fixture" <<'JSON'
{"issues":[
  {"id":"flywheel-release","title":"[public-share] B15 publish v0.2.0","description":"release cutover and Joshua signoff","status":"blocked","priority":1,"issue_type":"task","labels":["public-share"],"dependency_count":2,"dependent_count":0,"source_repo":"flywheel"},
  {"id":"flywheel-skillos","title":"SkillOS JSM package blocked","description":"agent-ergonomics skill package must validate","status":"blocked","priority":1,"issue_type":"bug","labels":[],"dependency_count":0,"dependent_count":1,"source_repo":"flywheel"},
  {"id":"flywheel-parent","title":"decomposed parent umbrella","description":"parent waits on child beads","status":"blocked","priority":2,"issue_type":"task","labels":[],"dependency_count":0,"dependent_count":0,"source_repo":"flywheel"}
],"total":3}
JSON

if python3 -m py_compile "$SCRIPT" 2>/dev/null; then
  pass "python syntax"
else
  fail "python syntax"
fi

out="$(python3 "$SCRIPT" --info 2>/dev/null)"
if printf '%s' "$out" | jq -e '.schema_version == "flywheel.bead_blocker_sync.v1" and .mutation_default == "dry-run"' >/dev/null; then
  pass "--info schema"
else
  fail "--info schema"
fi

out="$(python3 "$SCRIPT" sync --repo "$repo" --blockers-dir "$blockers" --input "$fixture" --dry-run 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "dry_run" and .planned_count == 3 and .applied_count == 0' >/dev/null; then
  pass "dry-run plans all blocked beads"
else
  fail "dry-run output"
fi

if [[ ! -e "$blockers/flywheel-release.json" ]]; then
  pass "dry-run does not write blocker files"
else
  fail "dry-run wrote blocker file"
fi

set +e
python3 "$SCRIPT" sync --repo "$repo" --blockers-dir "$blockers" --input "$fixture" --apply >/tmp/bead-blocker-sync-no-key.json 2>/tmp/bead-blocker-sync-no-key.err
rc=$?
set -e
if [[ "$rc" -eq 2 ]] && grep -q -- "--apply requires --idempotency-key" /tmp/bead-blocker-sync-no-key.err; then
  pass "apply requires idempotency key"
else
  fail "apply idempotency guard rc=$rc"
fi

out="$(python3 "$SCRIPT" sync --repo "$repo" --blockers-dir "$blockers" --input "$fixture" --apply --idempotency-key test-sync 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "applied" and .applied_count == 3' >/dev/null; then
  pass "apply writes all blocker files"
else
  fail "apply output"
fi

if jq -e '.schema_version == "flywheel.bead_blocker.v1" and .blocker_class == "release_cutover" and (.acceptance_condition | contains("br show flywheel-release")) and (.verification_path | contains(".status == \"blocked\""))' "$blockers/flywheel-release.json" >/dev/null; then
  pass "release blocker carries executable AC and verification path"
else
  fail "release blocker payload"
fi

if jq -e '.blocker_class == "skillos_or_jsm_control_plane" and (.next_action | contains("Coordinate with SkillOS"))' "$blockers/flywheel-skillos.json" >/dev/null; then
  pass "SkillOS blocker classified for control-plane remediation"
else
  fail "SkillOS classification"
fi

if jq -e '.blocker_class == "decomposed_parent" and .ac_check_interval_ticks == 4' "$blockers/flywheel-parent.json" >/dev/null; then
  pass "parent blocker gets default AC cadence"
else
  fail "parent classification"
fi

out="$(python3 "$SCRIPT" doctor --repo "$repo" --blockers-dir "$blockers" --input "$fixture" 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "pass" and .missing_count == 0 and .synced_count == 3' >/dev/null; then
  pass "doctor passes once blocked beads are synced"
else
  fail "doctor pass"
fi

rm -f "$blockers/flywheel-parent.json"
set +e
out="$(python3 "$SCRIPT" doctor --repo "$repo" --blockers-dir "$blockers" --input "$fixture" 2>/dev/null)"
rc=$?
set -e
if [[ "$rc" -eq 1 ]] && printf '%s' "$out" | jq -e '.status == "fail" and (.missing_blocker_files | index("flywheel-parent"))' >/dev/null; then
  pass "doctor fails on unsynced blocked bead"
else
  fail "doctor missing-file failure"
fi

out="$(python3 "$SCRIPT" validate --blocker-file "$blockers/flywheel-release.json" 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "pass"' >/dev/null; then
  pass "validate accepts generated blocker file"
else
  fail "validate generated blocker"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
