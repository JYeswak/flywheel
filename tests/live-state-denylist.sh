#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/depersonalize.py"
DENYLIST="$ROOT/state/live-state-denylist.yaml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-denylist.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if python3 -m py_compile "$SCRIPT" && python3 "$SCRIPT" --help >/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

if [[ -s "$DENYLIST" ]] && rg -q '^schema_version: flywheel\.live_state_denylist\.v0$' "$DENYLIST"; then
  pass "denylist present"
else
  fail "denylist present"
fi

mkdir -p "$TMP/ntm/.ntm"
printf '{}\n' >"$TMP/ntm/.ntm/rate_limits.json"
run_capture "$TMP/ntm.out" "$TMP/ntm.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/ntm" --json
ntm_rc=$?
if [[ "$ntm_rc" -eq 30 ]] && jq -e '.status == "fail" and .exit_code == 30 and (.findings[] | select(.id == "repo-ntm-runtime" and .reason_code == "private_pane_runtime"))' "$TMP/ntm.out" >/dev/null; then
  pass "ntm runtime blocked"
else
  fail "ntm runtime blocked rc=${ntm_rc}"
fi

mkdir -p "$TMP/sqlite/.claude/skills/.flywheel"
printf 'fixture sqlite bytes\n' >"$TMP/sqlite/.claude/skills/.flywheel/state.db-wal"
run_capture "$TMP/sqlite.out" "$TMP/sqlite.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/sqlite" --json
sqlite_rc=$?
if [[ "$sqlite_rc" -eq 30 ]] && jq -e '.status == "fail" and (.findings[] | select(.id == "repo-flywheel-sqlite-state" and .reason_code == "private_sqlite_state"))' "$TMP/sqlite.out" >/dev/null; then
  pass "sqlite runtime state blocked"
else
  fail "sqlite runtime state blocked rc=${sqlite_rc}"
fi

mkdir -p "$TMP/beads/.beads"
printf '{}\n' >"$TMP/beads/.beads/issues.jsonl"
run_capture "$TMP/beads.out" "$TMP/beads.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/beads" --json
beads_rc=$?
if [[ "$beads_rc" -eq 30 ]] && jq -e '.status == "fail" and (.findings[] | select(.id == "repo-beads-issues-ledger" and .reason_code == "private_beads_ledger"))' "$TMP/beads.out" >/dev/null; then
  pass "beads issue ledger blocked"
else
  fail "beads issue ledger blocked rc=${beads_rc}"
fi

mkdir -p "$TMP/closed-bead/AGENTS/README/memory"
printf '%s\n' "$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory/example.md" >"$TMP/closed-bead/AGENTS/README/memory/skill"
run_capture "$TMP/closed-bead.out" "$TMP/closed-bead.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/closed-bead" --json
closed_bead_rc=$?
if [[ "$closed_bead_rc" -eq 30 ]] && jq -e '.status == "fail" and (.findings[] | select(.id == "closed-bead-compat-artifacts" and .reason_code == "private_memory_path"))' "$TMP/closed-bead.out" >/dev/null; then
  pass "closed bead compatibility artifacts blocked"
else
  fail "closed bead compatibility artifacts blocked rc=${closed_bead_rc}"
fi

mkdir -p "$TMP/client-paths/.flywheel/scripts" "$TMP/client-paths/templates/flywheel-install/polish-gate/fixtures/scope-allowlist"
: >"$TMP/client-paths/.flywheel/scripts/recovery-install-plist-alpsinsurance.sh"
: >"$TMP/client-paths/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/alps.json"
run_capture "$TMP/client-paths.out" "$TMP/client-paths.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/client-paths" --json
client_paths_rc=$?
if [[ "$client_paths_rc" -eq 30 ]] && jq -e '
  .status == "fail"
  and ([.findings[].id] | contains(["client-specific-insurance-paths"]))
  and ([.findings[].path] | contains([
    ".flywheel/scripts/recovery-install-plist-alpsinsurance.sh",
    "templates/flywheel-install/polish-gate/fixtures/scope-allowlist/alps.json"
  ]))
' "$TMP/client-paths.out" >/dev/null; then
  pass "client-specific path artifacts blocked"
else
  fail "client-specific path artifacts blocked rc=${client_paths_rc}"
fi

mkdir -p "$TMP/manual/.flywheel/handoffs"
printf 'synthetic handoff\n' >"$TMP/manual/.flywheel/handoffs/example.md"
run_capture "$TMP/manual.out" "$TMP/manual.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/manual" --json
manual_rc=$?
if [[ "$manual_rc" -eq 31 ]] && jq -e '.status == "manual_review_required" and (.findings[] | select(.id == "repo-handoffs"))' "$TMP/manual.out" >/dev/null; then
  pass "manual review surfaced"
else
  fail "manual review surfaced rc=${manual_rc}"
fi

mkdir -p "$TMP/overlay/.flywheel/PLANS/live" "$TMP/overlay/.flywheel/audit/live" "$TMP/overlay/.flywheel/evidence/live" "$TMP/overlay/.flywheel/receipts"
printf 'fixture plan\n' >"$TMP/overlay/.flywheel/PLANS/live/00-PLAN.md"
printf 'fixture audit\n' >"$TMP/overlay/.flywheel/audit/live/evidence.md"
printf 'fixture evidence\n' >"$TMP/overlay/.flywheel/evidence/live/proof.md"
printf '{}\n' >"$TMP/overlay/.flywheel/receipts/example.json"
run_capture "$TMP/overlay.out" "$TMP/overlay.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/overlay" --json
overlay_rc=$?
if [[ "$overlay_rc" -eq 31 ]] && jq -e '
  .status == "manual_review_required"
  and ([.findings[].id] | contains(["repo-flywheel-plans","repo-flywheel-audit","repo-flywheel-evidence","repo-flywheel-receipts"]))
' "$TMP/overlay.out" >/dev/null; then
  pass "overlay plan/audit/evidence/receipts require review"
else
  fail "overlay plan/audit/evidence/receipts require review rc=${overlay_rc}"
fi

mkdir -p "$TMP/private-receipts/.flywheel/receipts/private"
printf '{}\n' >"$TMP/private-receipts/.flywheel/receipts/private/live.json"
run_capture "$TMP/private-receipts.out" "$TMP/private-receipts.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/private-receipts" --json
private_receipts_rc=$?
if [[ "$private_receipts_rc" -eq 30 ]] && jq -e '.status == "fail" and (.findings[] | select(.id == "repo-local-private-receipts"))' "$TMP/private-receipts.out" >/dev/null; then
  pass "private receipts blocked before broad receipt review"
else
  fail "private receipts blocked before broad receipt review rc=${private_receipts_rc}"
fi

mkdir -p "$TMP/credential"
printf 'FIXTURE_TOKEN=CANARY_TEST_VALUE\n' >"$TMP/credential/.env.local"
run_capture "$TMP/credential.out" "$TMP/credential.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/credential" --json
credential_rc=$?
if [[ "$credential_rc" -eq 32 ]] && jq -e '.status == "fail" and .exit_code == 32 and (.findings[] | select(.id == "env-files"))' "$TMP/credential.out" >/dev/null; then
  pass "credential-shaped path blocked"
else
  fail "credential-shaped path blocked rc=${credential_rc}"
fi

mkdir -p "$TMP/secret-ledger/.claude"
printf '{}\n' >"$TMP/secret-ledger/.claude/secret-leak-ledger.jsonl"
run_capture "$TMP/secret-ledger.out" "$TMP/secret-ledger.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/secret-ledger" --json
secret_ledger_rc=$?
if [[ "$secret_ledger_rc" -eq 32 ]] && jq -e '.status == "fail" and (.findings[] | select(.id == "secret-leak-ledger" and .reason_code == "credential_state_path"))' "$TMP/secret-ledger.out" >/dev/null; then
  pass "secret leak ledger blocked"
else
  fail "secret leak ledger blocked rc=${secret_ledger_rc}"
fi

mkdir -p "$TMP/halted/.flywheel/scripts"
: >"$TMP/halted/.flywheel/scripts/canonical-doctrine-sync.sh"
: >"$TMP/halted/.flywheel/scripts/sync-canonical-doctrine.sh"
: >"$TMP/halted/.flywheel/scripts/agents-md-fleet-propagator.sh"
run_capture "$TMP/halted.out" "$TMP/halted.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/halted" --json
halted_rc=$?
if [[ "$halted_rc" -eq 30 ]] && jq -e '
  .status == "fail"
  and ([.findings[].id] | contains([
    "halted-propagator-canonical-doctrine-sync",
    "halted-propagator-sync-canonical-doctrine",
    "halted-propagator-agents-md-fleet"
  ]))
  and all(.findings[]; .reason_code == "halted_propagator")
' "$TMP/halted.out" >/dev/null; then
  pass "halted propagators blocked"
else
  fail "halted propagators blocked rc=${halted_rc}"
fi

mkdir -p "$TMP/vendor/node_modules/pkg/tokenizer" "$TMP/vendor/node_modules/next/dist/compiled/cookie"
printf 'synthetic package file\n' >"$TMP/vendor/node_modules/pkg/tokenizer/index.js"
printf 'synthetic package file\n' >"$TMP/vendor/node_modules/next/dist/compiled/cookie/index.js"
run_capture "$TMP/vendor.out" "$TMP/vendor.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/vendor" --json
vendor_rc=$?
run_capture "$TMP/vendor-deep.out" "$TMP/vendor-deep.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/vendor" --include-ignored-dirs --json
vendor_deep_rc=$?
if [[ "$vendor_rc" -eq 0 ]] && [[ "$vendor_deep_rc" -eq 32 ]] && jq -e '.status == "pass"' "$TMP/vendor.out" >/dev/null && jq -e '.status == "fail" and (.findings[] | select(.reason_code == "credential_state_path"))' "$TMP/vendor-deep.out" >/dev/null; then
  pass "dependency dirs ignored by default"
else
  fail "dependency dirs ignored by default rc=${vendor_rc} deep_rc=${vendor_deep_rc}"
fi

mkdir -p "$TMP/safe/templates" "$TMP/safe/docs"
printf 'repo={{ repo_path }}\n' >"$TMP/safe/templates/loop.tmpl"
printf '# Public docs\n' >"$TMP/safe/docs/first-run.md"
run_capture "$TMP/safe.out" "$TMP/safe.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/safe" --json
safe_rc=$?
if [[ "$safe_rc" -eq 0 ]] && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/safe.out" >/dev/null; then
  pass "safe template allowed"
else
  fail "safe template allowed rc=${safe_rc}"
fi

if ! rg -n 'FIXTURE_TOKEN|CANARY_TEST_VALUE|synthetic handoff|fixture sqlite bytes|fixture plan|fixture audit|fixture evidence' "$TMP"/*.out >/dev/null; then
  pass "outputs avoid file contents"
else
  fail "outputs avoid file contents"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
