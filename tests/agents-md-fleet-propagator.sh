#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agents-md-fleet-propagator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agents-md-fleet-propagator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
edge_count=0

pass() {
  pass_count=$((pass_count + 1))
}

edge() {
  edge_count=$((edge_count + 1))
}

fail() {
  printf 'FAIL agents-md-fleet-propagator: %s\n' "$1" >&2
  exit 1
}

write_append_lib() {
  local lib="$1"
  cat >"$lib" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c '.' <<<"$row" >>"$path"
}
SH
}

make_repo() {
  local path="$1" body="$2"
  mkdir -p "$path/.flywheel"
  printf '%s\n' "$body" >"$path/AGENTS.md"
  printf '%s\n' "$body" >"$path/.flywheel/AGENTS-CANONICAL.md"
  cat >"$path/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "flywheel",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "flywheel"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "flywheel"}
  ]
}
JSON
}

write_sync() {
  local sync="$1" source="$2" fail_repo="${3:-}"
  cat >"$sync" <<SH
#!/usr/bin/env bash
set -euo pipefail
target=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    --target) target="\${2:?}"; shift 2 ;;
    --target=*) target="\${1#*=}"; shift ;;
    --apply-three-surface|--json) shift ;;
    *) shift ;;
  esac
done
if [[ "\$target" == "$fail_repo" ]]; then
  printf '{"status":"failed","post_drift_count":1,"reason":"fixture_sync_failure"}\n'
  exit 9
fi
cp "$source" "\$target/AGENTS.md"
mkdir -p "\$target/.flywheel"
cp "$source" "\$target/.flywheel/AGENTS-CANONICAL.md"
printf '{"status":"pass","applied":true,"post_drift_count":0,"target":"%s"}\n' "\$target"
SH
  chmod +x "$sync"
}

SOURCE="$TMP/source/AGENTS.md"
mkdir -p "$TMP/source"
cat >"$SOURCE" <<'EOF'
# Canonical

## L1
alpha

## L2
beta
EOF

in_sync="$TMP/repos/in-sync"
missing_l="$TMP/repos/missing-l"
divergent="$TMP/repos/divergent"
missing_agents="$TMP/repos/missing-agents"
sync_fail="$TMP/repos/sync-fail"
no_manifest="$TMP/repos/no-manifest"
make_repo "$in_sync" "$(cat "$SOURCE")"
make_repo "$missing_l" "# Canonical

## L1
alpha"
make_repo "$divergent" "# Divergent

## L9
other"
mkdir -p "$missing_agents"
make_repo "$sync_fail" "# Old

## L1
old"
make_repo "$no_manifest" "# Old

## L1
old"
rm -f "$no_manifest/.flywheel/ownership.json"

append_lib="$TMP/jsonl-append.sh"
write_append_lib "$append_lib"
sync="$TMP/sync.sh"
write_sync "$sync" "$SOURCE"
ledger="$TMP/ledger.jsonl"
fuckup="$TMP/fuckup.jsonl"
contract="$TMP/contract.jsonl"

env_base=(
  "FLYWHEEL_JSONL_APPEND_LIB=$append_lib"
  "AGENTS_MD_FLEET_SOURCE_AGENTS=$SOURCE"
  "AGENTS_MD_FLEET_SYNC=$sync"
  "AGENTS_MD_FLEET_LEDGER=$ledger"
  "AGENTS_MD_FLEET_FUCKUP_LOG=$fuckup"
  "AGENTS_MD_FLEET_CONTRACT_LEDGER=$contract"
  "AGENTS_MD_FLEET_NOW=2026-05-05T00:00:00Z"
)

repos="$in_sync,$missing_l,$divergent"
dry="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$repos" "$SCRIPT" --json)"
jq -e '.dry_run == true and .fleet_doctrine_drift_count == 2 and (.fleet_doctrine_drift_repos | length) == 2' <<<"$dry" >/dev/null || fail "dry-run did not detect two drifted repos"
pass

[[ ! -e "$ledger" ]] || fail "dry-run wrote ledger"
pass

targeted="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$repos" "$SCRIPT" --target "$missing_l" --json)"
missing_l_abs="$(cd "$missing_l" && pwd -P)"
jq -e --arg repo "$missing_l_abs" '.repos_checked == 1 and .fleet_doctrine_drift_count == 1 and .fleet_doctrine_drift_repos[0] == $repo' <<<"$targeted" >/dev/null || fail "target scoping did not isolate repo"
pass

apply="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$repos" "$SCRIPT" --apply --json)"
jq -e '.success_count == 2 and .failure_count == 0 and .fleet_doctrine_drift_count_after == 0' <<<"$apply" >/dev/null || fail "apply did not converge two repos"
jq -s -e 'length == 2 and all(.[]; .success == true)' "$ledger" >/dev/null || fail "apply ledger did not contain two success rows"
pass

doctor="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$repos" "$SCRIPT" --doctor --json)"
jq -e '.schema_version | startswith("agents-md-fleet-propagation")' <<<"$doctor" >/dev/null || fail "doctor schema invalid"
jq -e '.fleet_doctrine_drift_count == 0 and .agents_md_fleet_propagation_last_apply_succeeded == true' <<<"$doctor" >/dev/null || fail "doctor fields invalid after apply"
pass

missing_ledger="$TMP/missing-ledger.jsonl"
missing_fuckup="$TMP/missing-fuckup.jsonl"
missing_out="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$missing_agents" AGENTS_MD_FLEET_LEDGER="$missing_ledger" AGENTS_MD_FLEET_FUCKUP_LOG="$missing_fuckup" "$SCRIPT" --apply --json || true)"
jq -e '.failure_count == 1 and .propagation_results[0].failure_reason == "target_no_agents_md"' <<<"$missing_out" >/dev/null || fail "missing AGENTS edge did not fail with target_no_agents_md"
jq -s -e '[.[] | select(.trauma_class == "fleet-propagation-failed" and .reason == "target_no_agents_md")] | length == 1' "$missing_fuckup" >/dev/null || fail "missing AGENTS edge did not write fuckup"
edge

sync_fail_ledger="$TMP/sync-fail-ledger.jsonl"
sync_fail_fuckup="$TMP/sync-fail-fuckup.jsonl"
fail_sync="$TMP/fail-sync.sh"
sync_fail_abs="$(cd "$sync_fail" && pwd -P)"
write_sync "$fail_sync" "$SOURCE" "$sync_fail_abs"
sync_fail_out="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$sync_fail" AGENTS_MD_FLEET_SYNC="$fail_sync" AGENTS_MD_FLEET_LEDGER="$sync_fail_ledger" AGENTS_MD_FLEET_FUCKUP_LOG="$sync_fail_fuckup" "$SCRIPT" --apply --json || true)"
jq -e '.failure_count == 1 and .propagation_results[0].failure_reason == "sync_nonzero"' <<<"$sync_fail_out" >/dev/null || fail "sync nonzero edge did not fail with sync_nonzero"
jq -s -e '[.[] | select(.trauma_class == "fleet-propagation-failed" and .reason == "sync_nonzero")] | length == 1' "$sync_fail_fuckup" >/dev/null || fail "sync nonzero edge did not write fuckup"
edge

blocked="$TMP/repos/blocked-owner"
make_repo "$blocked" "# Blocked

## L1
old"
cat >"$blocked/.flywheel/ownership.json" <<'JSON'
{
  "schema_version": "flywheel.canonical_ownership.v1",
  "canonical_owner_class": "skillos",
  "owned_canonical_paths": [
    {"path": "AGENTS.md", "owner_class": "skillos"},
    {"path": ".flywheel/AGENTS-CANONICAL.md", "owner_class": "skillos"}
  ]
}
JSON
blocked_ledger="$TMP/blocked-ledger.jsonl"
blocked_fuckup="$TMP/blocked-fuckup.jsonl"
blocked_out="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$blocked" AGENTS_MD_FLEET_LEDGER="$blocked_ledger" AGENTS_MD_FLEET_FUCKUP_LOG="$blocked_fuckup" "$SCRIPT" --apply --json || true)"
jq -e '.failure_count == 1 and .propagation_results[0].failure_reason == "canonical_ownership_gate_blocked"' <<<"$blocked_out" >/dev/null || fail "ownership gate edge did not fail with canonical_ownership_gate_blocked"
! rg -q '^## L2$' "$blocked/AGENTS.md" || fail "ownership gate edge mutated blocked AGENTS.md"
jq -s -e '[.[] | select(.trauma_class == "fleet-propagation-failed" and .reason == "canonical_ownership_gate_blocked")] | length == 1' "$blocked_fuckup" >/dev/null || fail "ownership gate edge did not write fuckup"
edge

no_manifest_ledger="$TMP/no-manifest-ledger.jsonl"
no_manifest_fuckup="$TMP/no-manifest-fuckup.jsonl"
no_manifest_out="$(env "${env_base[@]}" AGENTS_MD_FLEET_REPOS="$no_manifest" AGENTS_MD_FLEET_LEDGER="$no_manifest_ledger" AGENTS_MD_FLEET_FUCKUP_LOG="$no_manifest_fuckup" "$SCRIPT" --apply --json)"
jq -e '.success_count == 1 and .failure_count == 0 and .fleet_doctrine_drift_count_after == 0' <<<"$no_manifest_out" >/dev/null || fail "source-owned fallback did not propagate into repo without target manifest"
rg -q '^## L2$' "$no_manifest/AGENTS.md" || fail "source-owned fallback did not update no-manifest AGENTS.md"
edge

printf 'OK agents-md-fleet-propagator tests pass=%s/5 edges=%s/4\n' "$pass_count" "$edge_count"
