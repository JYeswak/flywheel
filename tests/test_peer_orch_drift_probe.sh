#!/usr/bin/env bash
# test_peer_orch_drift_probe.sh — fixture: 2 aligned + 1 drifted session
# canonical-cli-scoping checked via check-cli-scoping.sh on the probe script (shell, not binary)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-drift-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-drift-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$label"
  else
    fail "$label (expected=$expected got=$actual)"
  fi
}

# ---- Build fixture repos ----
# aligned-a: has MISSION.md + dispatches all with mission keywords
mkdir -p "$TMP/aligned-a/.flywheel"
cat >"$TMP/aligned-a/.flywheel/MISSION.md" <<'MD'
# aligned-a Mission
status: locked
Build scalable API features and ship them.
MD
cat >"$TMP/aligned-a/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-06T10:00:00Z","task_id":"t1","task_summary":"fix api endpoint regression test"}
{"ts":"2026-05-06T10:10:00Z","task_id":"t2","task_summary":"deploy skill scaffold to staging"}
{"ts":"2026-05-06T10:20:00Z","task_id":"t3","task_summary":"close bead for integration probe"}
{"ts":"2026-05-06T10:30:00Z","task_id":"t4","task_summary":"refactor auth doctor checks"}
{"ts":"2026-05-06T10:40:00Z","task_id":"t5","task_summary":"ship mission-aligned feature"}
JSONL

# aligned-b: has MISSION.md + dispatches with keywords
mkdir -p "$TMP/aligned-b/.flywheel"
cat >"$TMP/aligned-b/.flywheel/MISSION.md" <<'MD'
# aligned-b Mission
status: locked
Monitor fleet health and escalate incidents.
MD
cat >"$TMP/aligned-b/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-06T09:00:00Z","task_id":"u1","task_summary":"audit agent dispatch callbacks"}
{"ts":"2026-05-06T09:10:00Z","task_id":"u2","task_summary":"monitor watcher coverage probe"}
{"ts":"2026-05-06T09:20:00Z","task_id":"u3","task_summary":"fix doctor health error bead"}
JSONL

# drifted: has MISSION.md but dispatches contain zero mission keywords
mkdir -p "$TMP/drifted/.flywheel"
cat >"$TMP/drifted/.flywheel/MISSION.md" <<'MD'
# drifted Mission
status: locked
Maintain billing accuracy and client SLA compliance.
MD
cat >"$TMP/drifted/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"ts":"2026-05-06T08:00:00Z","task_id":"d1","task_summary":"xyzzy frobnicate quux"}
{"ts":"2026-05-06T08:10:00Z","task_id":"d2","task_summary":"plugh thud foo bar baz"}
{"ts":"2026-05-06T08:20:00Z","task_id":"d3","task_summary":"noop corge grault garply"}
{"ts":"2026-05-06T08:30:00Z","task_id":"d4","task_summary":"waldo fred plugh xyzzy"}
{"ts":"2026-05-06T08:40:00Z","task_id":"d5","task_summary":"thud corge waldo plugh foo"}
JSONL

# ---- Syntax check ----
bash -n "$SCRIPT" && pass "script syntax OK" || fail "script syntax"

# ---- --info surface ----
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "peer-orch-drift-probe"' "info.name"
assert_jq "$TMP/info.json" '.agent_mail_gap | type == "string"' "info.agent_mail_gap documented"

# ---- --schema surface ----
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "peer-orch-drift-probe/v1"' "schema surface"

# ---- --examples surface ----
"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.examples | length >= 3' "examples surface"

# ---- Main fixture run (2 aligned + 1 drifted) ----
EXITCODE=0
"$SCRIPT" \
  --fixture-dir "$TMP" \
  --session aligned-a \
  --session aligned-b \
  --session drifted \
  --alert-log "$TMP/alerts.jsonl" \
  --dry-run \
  --json >"$TMP/out.json" || EXITCODE=$?

assert_jq "$TMP/out.json" '.schema_version == "peer-orch-drift-probe/v1"' "output schema_version"
assert_jq "$TMP/out.json" '.total_session_count == 3' "total_session_count=3"
assert_jq "$TMP/out.json" '.aligned_session_count == 2' "aligned_session_count=2"
assert_jq "$TMP/out.json" '.drift_session_count == 1' "drift_session_count=1"
assert_jq "$TMP/out.json" '.by_session["drifted"].drift_pct > 0' "drifted session has drift_pct>0"
assert_jq "$TMP/out.json" '.by_session["aligned-a"].drift_pct == 0' "aligned-a drift_pct=0"
assert_jq "$TMP/out.json" '.by_session["aligned-b"].drift_pct == 0' "aligned-b drift_pct=0"
assert_jq "$TMP/out.json" '.dashboard_line | test("Peers: 2/3 aligned")' "dashboard_line correct"
assert_jq "$TMP/out.json" '.dry_run == true' "dry_run flag propagated"

# Exit code: drifted session at 100% drift => exit 2
assert_exit 2 "$EXITCODE" "exit_code=2 when any session >=40% drift"

# Dry-run: no alert written to log (file should not exist or be empty)
if [[ -f "$TMP/alerts.jsonl" ]]; then
  COUNT=$(wc -l <"$TMP/alerts.jsonl" | tr -d ' ')
  if [[ "$COUNT" -eq 0 ]]; then
    pass "dry-run: no alerts written to disk"
  else
    fail "dry-run: alerts written when --dry-run set"
  fi
else
  pass "dry-run: alert log not created"
fi

# ---- All-aligned run: exit 0 ----
EXIT2=0
"$SCRIPT" \
  --fixture-dir "$TMP" \
  --session aligned-a \
  --session aligned-b \
  --alert-log "$TMP/alerts2.jsonl" \
  --dry-run \
  --json >"$TMP/out2.json" || EXIT2=$?
assert_exit 0 "$EXIT2" "exit_code=0 when all sessions <20% drift"
assert_jq "$TMP/out2.json" '.drift_session_count == 0' "all-aligned drift_session_count=0"

echo
echo "Summary: $pass_count pass, $fail_count fail"
[[ $fail_count -eq 0 ]] || exit 1
