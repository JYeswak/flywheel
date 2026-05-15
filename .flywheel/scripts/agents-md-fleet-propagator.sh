#!/usr/bin/env bash
# shellcheck disable=SC2016
# canonical-cli-scoping-allow-large: c1zgt keeps fleet scan, apply, doctor, repair, schema, and test-facing fixture knobs in one portable CLI.
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.2)
set -euo pipefail

VERSION="agents-md-fleet-propagator.v1.0.0"
SCHEMA_VERSION="agents-md-fleet-propagation/v1"

# flywheel-94nzk: jq arglist-too-long mitigation. When ledger grows past
# ARG_MAX (~1MB on macOS), `--argjson rows "$rows"` crashes jq with
# "Argument list too long". Helper reads rows from stdin into a tmpfile,
# invokes jq with `--slurpfile rows <path>`, then deletes the tmpfile.
# In the jq filter, unwrap with `($rows[0]) as $rows` (slurpfile wraps the
# file's JSON value in an outer array).
#
# Reproduced empirically with a 5000-row synthetic ledger (~1.9MB serialized)
# against doctor / audit / why surfaces — all crashed pre-fix.
#
# The wrapper-style (rather than caller-managed-tmpfile) avoids the subshell-
# scope problem: each callsite is itself invoked via $(...) command
# substitution, so an outer EXIT trap registered in the parent shell never
# fires for the subshell's tmpfile. Inline cleanup inside this wrapper
# keeps the tmpfile lifecycle local to the same shell that created it.
#
# Usage:
#   ledger_rows_json | fw_jq_with_rows <jq-args>... '<filter>'
fw_jq_with_rows() {
  local rows_file
  rows_file="$(mktemp -t fleet-prop-rows.XXXXXX)"
  cat >"$rows_file"
  jq -nc --slurpfile rows "$rows_file" "$@"
  local rc=$?
  rm -f "$rows_file"
  return $rc
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${AGENTS_MD_FLEET_REPO:-$REPO_ROOT_DEFAULT}"
SOURCE_AGENTS="${AGENTS_MD_FLEET_SOURCE_AGENTS:-$REPO_ROOT/AGENTS.md}"
SYNC_SH="${AGENTS_MD_FLEET_SYNC:-$HOME/.flywheel/canonical-meta-rules/sync.sh}"
LEDGER="${AGENTS_MD_FLEET_LEDGER:-$HOME/.local/state/flywheel/agents-md-fleet-propagation.jsonl}"
FUCKUP_LOG="${AGENTS_MD_FLEET_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
CONTRACT_LEDGER="${AGENTS_MD_FLEET_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
FLEET_ROSTER="${AGENTS_MD_FLEET_ROSTER:-$HOME/.local/state/flywheel/fleet-roster.json}"
LOOPS_DIR="${AGENTS_MD_FLEET_LOOPS_DIR:-$HOME/.flywheel/loops}"
OWNERSHIP_GATE="${AGENTS_MD_FLEET_OWNERSHIP_GATE:-1}"
SOURCE_OWNER_CLASS="${AGENTS_MD_FLEET_SOURCE_OWNER_CLASS:-flywheel}"
OWNERSHIP_MANIFEST_REL="${AGENTS_MD_FLEET_OWNERSHIP_MANIFEST:-.flywheel/ownership.json}"
TARGET_REPO=""
MODE="scan"
JSON_OUT=0
APPLY=0
DRY_RUN=1
RECORD_SCAN=0
WATCH=0
WATCH_INTERVAL=60
REPAIR_SCOPE="ledger"
VALIDATE_TARGET="ledger"
WHY_ID=""
SCHEMA_TOPIC="propagation"
HELP_TOPIC="scan"
COMPLETION_SHELL=""
EXPLAIN=0
IDEMPOTENCY_KEY=""

usage() {
  cat <<'EOF'
usage:
  agents-md-fleet-propagator.sh [--target REPO] [--dry-run|--apply] [--record-scan] [--json]
  agents-md-fleet-propagator.sh --doctor [--json]
  agents-md-fleet-propagator.sh health [--watch] [--interval N] [--json]
  agents-md-fleet-propagator.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  agents-md-fleet-propagator.sh validate ledger [--json]
  agents-md-fleet-propagator.sh audit [--json]
  agents-md-fleet-propagator.sh why ID [--json]
  agents-md-fleet-propagator.sh schema propagation|doctor|ledger|contract [--json]
  agents-md-fleet-propagator.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

now_iso() {
  printf '%s\n' "${AGENTS_MD_FLEET_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

append_validated() {
  local path="$1" row="$2"
  if [[ ! -r "$JSONL_APPEND_LIB" ]]; then
    echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2
    return 3
  fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

canonical_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  else
    printf '%s\n' "$path"
  fi
}

sha256_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    printf ''
  fi
}

relpath_for_repo() {
  local repo="$1" target="$2"
  case "$target" in
    "$repo"/*) printf '%s\n' "${target#"$repo"/}" ;;
    *) printf '%s\n' "$target" ;;
  esac
}

target_owner_class() {
  local repo="$1" target="$2" manifest rel
  manifest="$repo/$OWNERSHIP_MANIFEST_REL"
  [[ -f "$manifest" ]] || return 1
  rel="$(relpath_for_repo "$repo" "$target")"
  jq -r --arg rel "$rel" '
    def norm_path:
      if type == "string" then .
      else (.path // .prefix // .glob // "")
      end;
    def norm_class:
      if type == "string" then empty
      else (.owner_class // .class // .canonical_owner_class // "")
      end;
    (.owned_canonical_paths // []) as $paths
    | (
        [
          $paths[]
          | select((norm_path) as $p | $p != "" and ($rel == $p or ($rel | startswith($p + "/"))))
          | norm_class
          | select(. != "")
        ][0]
      )
      // (.canonical_owner_class // .owner_class // .repo_class // empty)
  ' "$manifest" 2>/dev/null | awk 'NF {print; exit}'
}

ownership_gate_allows() {
  local repo="$1" target="$2" owner_class
  [[ "$OWNERSHIP_GATE" == "1" ]] || return 0
  if [[ "$repo" == "$(canonical_path "$REPO_ROOT")" ]]; then
    return 0
  fi
  owner_class="$(target_owner_class "$repo" "$target" || true)"
  [[ -n "$owner_class" && "$owner_class" == "$SOURCE_OWNER_CLASS" ]]
}

l_rule_count() {
  local path="$1"
  if [[ -f "$path" ]]; then
    rg -c '^## L[0-9]+' "$path" 2>/dev/null || printf '0\n'
  else
    printf '0\n'
  fi
}

repo_candidates_from_roster() {
  local roster="$1"
  [[ -s "$roster" ]] || return 0
  if jq -e . "$roster" >/dev/null 2>&1; then
    jq -r '
      if type == "array" then .
      else (.members // .repos // .projects // .sessions // [])
      end
      | .[]?
      | if type == "string" then .
        else (.repo_realpath // .repo // .path // .project_key // .repo_path // empty)
        end
    ' "$roster" 2>/dev/null
  else
    sed -n 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d; p' "$roster"
  fi
}

repo_candidates_from_loops() {
  [[ -d "$LOOPS_DIR" ]] || return 0
  local f
  for f in "$LOOPS_DIR"/*.json; do
    [[ -e "$f" ]] || continue
    jq -r '.repo_realpath // .repo // .path // empty' "$f" 2>/dev/null || true
  done
  return 0
}

default_repo_candidates() {
  cat <<EOF
$HOME/Developer/skillos
$HOME/Developer/alpsinsurance
$HOME/Developer/mobile-eats
$HOME/Developer/vrtx
$HOME/Developer/polymarket-pico-z
EOF
}

repo_list() {
  local raw candidate repo_abs source_abs
  source_abs="$(canonical_path "$REPO_ROOT")"
  if [[ -n "$TARGET_REPO" ]]; then
    canonical_path "$TARGET_REPO"
    return 0
  fi
  if [[ -n "${AGENTS_MD_FLEET_REPOS:-}" ]]; then
    tr ',:' '\n' <<<"$AGENTS_MD_FLEET_REPOS" | while IFS= read -r raw; do
      candidate="${raw/#\~/$HOME}"
      [[ -n "$candidate" ]] || continue
      canonical_path "$candidate"
    done | awk '!seen[$0]++'
    return 0
  fi
  {
    repo_candidates_from_roster "$FLEET_ROSTER"
    repo_candidates_from_loops
    default_repo_candidates
  } | while IFS= read -r raw; do
    candidate="${raw/#\~/$HOME}"
    [[ -n "$candidate" ]] || continue
    repo_abs="$(canonical_path "$candidate")"
    [[ -n "$repo_abs" ]] || continue
    if [[ "$repo_abs" == "$source_abs" ]]; then
      continue
    fi
    printf '%s\n' "$repo_abs"
  done | awk '!seen[$0]++'
}

repo_scan_json() {
  local repo="$1" source_hash="$2" repo_abs agents target_hash drift reason l_count
  repo_abs="$(canonical_path "$repo")"
  agents="$repo_abs/AGENTS.md"
  target_hash=""
  drift=false
  reason="in_sync"
  l_count=0
  if [[ ! -d "$repo_abs" ]]; then
    reason="repo_missing"
    drift=false
  elif [[ ! -f "$agents" ]]; then
    reason="target_no_agents_md"
    drift=true
  else
    target_hash="$(sha256_file "$agents")"
    l_count="$(l_rule_count "$agents" | tr -d ' ')"
    if [[ "$target_hash" != "$source_hash" ]]; then
      drift=true
      reason="hash_mismatch"
    fi
  fi
  jq -nc \
    --arg repo "$repo_abs" \
    --arg agents "$agents" \
    --arg source_hash "$source_hash" \
    --arg target_hash "$target_hash" \
    --arg reason "$reason" \
    --argjson drift "$drift" \
    --argjson l_rule_count "$l_count" \
    '{repo:$repo,agents_md:$agents,source_hash:$source_hash,target_hash:$target_hash,l_rules_count:$l_rule_count,drift:$drift,reason:$reason}'
}

scan_rows_json() {
  local source_hash rows=() repo
  source_hash="$(sha256_file "$SOURCE_AGENTS")"
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    rows+=("$(repo_scan_json "$repo" "$source_hash")")
  done < <(repo_list)
  if [[ "${#rows[@]}" -eq 0 ]]; then
    printf '[]\n'
  else
    printf '%s\n' "${rows[@]}" | jq -s -c '.'
  fi
}

scan_payload_json() {
  local rows source_hash ts
  rows="$(scan_rows_json)"
  source_hash="$(sha256_file "$SOURCE_AGENTS")"
  ts="$(now_iso)"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg repo "$REPO_ROOT" \
    --arg source_agents "$SOURCE_AGENTS" \
    --arg source_hash "$source_hash" \
    --arg sync "$SYNC_SH" \
    --arg ledger "$LEDGER" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson repos "$rows" '
      ($repos | map(select(.drift == true))) as $drift
      | ($drift | map(.repo)) as $drift_repos
      | {
          schema_version:$schema_version,
          version:$version,
          ts:$ts,
          mode:"scan",
          action:"scan",
          repo:$repo,
          source_agents_md:$source_agents,
          source_hash:$source_hash,
          sync_path:$sync,
          ledger_path:$ledger,
          dry_run:$dry_run,
          apply:$apply,
          fleet_doctrine_drift_count:($drift | length),
          fleet_doctrine_drift_repos:$drift_repos,
          repos_checked:($repos | length),
          repos:$repos,
          planned_actions:($drift | map({action:"sync_apply_three_surface",target:.repo,reason:.reason})),
          status:(if ($drift | length) > 3 then "error" elif ($drift | length) > 0 then "warn" else "pass" end)
        }'
}

ledger_rows_json() {
  if [[ -s "$LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

last_apply_json() {
  # flywheel-94nzk: rows passed via fw_jq_with_rows (slurpfile + tmpfile cleanup).
  ledger_rows_json | fw_jq_with_rows '
    ($rows[0]) as $rows
    | $rows
    | map(select((.schema_version // "") | startswith("agents-md-fleet-propagation")))
    | map(select((.action // "") == "propagate"))
    | last // null
  '
}

failure_fuckup_row_json() {
  local repo="$1" reason="$2" sync_exit="$3" sync_output="$4"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg repo "$repo" \
    --arg reason "$reason" \
    --arg sync_exit "$sync_exit" \
    --arg sync_output "$sync_output" \
    '{ts:$ts,trauma_class:"fleet-propagation-failed",class:"fleet-propagation-failed",severity:"medium",repo:$repo,reason:$reason,sync_exit_code:($sync_exit | tonumber? // null),sync_output:$sync_output,what_happened:"agents-md fleet propagation could not converge target AGENTS.md via canonical sync.sh",should_become:"bead",bead_id:"flywheel-c1zgt"}'
}

apply_result_row_json() {
  local pre="$1" post="$2" sync_rc="$3" sync_output="$4" success="$5" reason="$6"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.ledger" \
    --arg ts "$(now_iso)" \
    --arg source_agents "$SOURCE_AGENTS" \
    --arg sync_output "$sync_output" \
    --arg sync_exit "$sync_rc" \
    --arg reason "$reason" \
    --argjson success "$success" \
    --argjson pre "$pre" \
    --argjson post "$post" \
    '{schema_version:$schema_version,ts:$ts,action:"propagate",repo:$pre.repo,source_agents_md:$source_agents,source_hash:$pre.source_hash,target_hash_pre:$pre.target_hash,target_hash_post:$post.target_hash,l_rules_count_pre:$pre.l_rules_count,l_rules_count_post:$post.l_rules_count,reason_pre:$pre.reason,reason_post:$post.reason,sync_exit_code:($sync_exit | tonumber? // null),sync_output:$sync_output,success:$success,status:(if $success then "succeeded" else "failed" end),failure_reason:(if $success then null else $reason end)}'
}

apply_one_repo() {
  local pre="$1" repo reason source_hash post sync_output sync_rc success=false result post_drift sync_post_count
  repo="$(jq -r '.repo' <<<"$pre")"
  reason="$(jq -r '.reason' <<<"$pre")"
  source_hash="$(jq -r '.source_hash' <<<"$pre")"
  if [[ "$reason" == "target_no_agents_md" || "$reason" == "repo_missing" ]]; then
    post="$pre"
    result="$(apply_result_row_json "$pre" "$post" "0" "" false "$reason")"
    append_validated "$LEDGER" "$result"
    append_validated "$FUCKUP_LOG" "$(failure_fuckup_row_json "$repo" "$reason" "0" "")"
    printf '%s\n' "$result"
    return 0
  fi
  if ! ownership_gate_allows "$repo" "$repo/AGENTS.md"; then
    post="$pre"
    sync_output="canonical ownership gate refused AGENTS.md propagation; target repo must declare owner_class=$SOURCE_OWNER_CLASS for AGENTS.md in $OWNERSHIP_MANIFEST_REL"
    result="$(apply_result_row_json "$pre" "$post" "2" "$sync_output" false "canonical_ownership_gate_blocked")"
    append_validated "$LEDGER" "$result"
    append_validated "$FUCKUP_LOG" "$(failure_fuckup_row_json "$repo" "canonical_ownership_gate_blocked" "2" "$sync_output")"
    printf '%s\n' "$result"
    return 0
  fi
  set +e
  sync_output="$("$SYNC_SH" --apply-three-surface --target "$repo" --json 2>&1)"
  sync_rc=$?
  set -e
  post="$(repo_scan_json "$repo" "$source_hash")"
  post_drift="$(jq -r '.drift' <<<"$post")"
  sync_post_count="$(jq -r '.post_drift_count // .drift_count // empty' <<<"$sync_output" 2>/dev/null || true)"
  if [[ "$sync_rc" -eq 0 && ( "$post_drift" == "false" || "$sync_post_count" == "0" ) ]]; then
    success=true
    reason="none"
  elif [[ "$sync_rc" -ne 0 ]]; then
    reason="sync_nonzero"
  else
    reason="post_sync_drift"
  fi
  result="$(apply_result_row_json "$pre" "$post" "$sync_rc" "$sync_output" "$success" "$reason")"
  append_validated "$LEDGER" "$result"
  if [[ "$success" != "true" ]]; then
    append_validated "$FUCKUP_LOG" "$(failure_fuckup_row_json "$repo" "$reason" "$sync_rc" "$sync_output")"
  fi
  printf '%s\n' "$result"
}

run_apply() {
  local scan pre tmp results after fail_count success_count payload rc=0
  scan="$(scan_payload_json)"
  tmp="$(mktemp "${TMPDIR:-/tmp}/agents-md-fleet-apply.XXXXXX")"
  while IFS= read -r pre; do
    [[ -n "$pre" ]] || continue
    apply_one_repo "$pre" >>"$tmp"
  done < <(jq -c '.repos[] | select(.drift == true)' <<<"$scan")
  results="$(jq -s -c 'map(select(type == "object"))' "$tmp")"
  rm -f "$tmp"
  after="$(scan_payload_json)"
  fail_count="$(jq -r '[.[] | select(.success != true)] | length' <<<"$results")"
  success_count="$(jq -r '[.[] | select(.success == true)] | length' <<<"$results")"
  if [[ "$fail_count" -gt 0 ]]; then rc=1; fi
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION.apply" \
    --arg ts "$(now_iso)" \
    --arg ledger "$LEDGER" \
    --arg fuckup_log "$FUCKUP_LOG" \
    --argjson before "$scan" \
    --argjson after "$after" \
    --argjson results "$results" \
    --argjson success_count "$success_count" \
    --argjson fail_count "$fail_count" \
    '{schema_version:$schema_version,ts:$ts,mode:"apply",dry_run:false,apply:true,ledger_path:$ledger,fuckup_log_path:$fuckup_log,fleet_doctrine_drift_count_before:$before.fleet_doctrine_drift_count,fleet_doctrine_drift_repos_before:$before.fleet_doctrine_drift_repos,fleet_doctrine_drift_count_after:$after.fleet_doctrine_drift_count,fleet_doctrine_drift_repos_after:$after.fleet_doctrine_drift_repos,propagation_results:$results,success_count:$success_count,failure_count:$fail_count,status:(if $fail_count > 0 then "error" elif $after.fleet_doctrine_drift_count > 0 then "warn" else "pass" end)}')"
  emit "$payload" "status=$(jq -r '.status' <<<"$payload") success_count=$success_count failure_count=$fail_count" "$rc"
}

run_scan() {
  local payload
  if [[ "$APPLY" -eq 1 ]]; then
    run_apply
    return $?
  fi
  payload="$(scan_payload_json)"
  if [[ "$RECORD_SCAN" -eq 1 ]]; then
    append_validated "$LEDGER" "$payload"
    payload="$(jq -c '. + {ledger_append_status:"appended"}' <<<"$payload")"
  fi
  emit "$payload" "status=$(jq -r '.status' <<<"$payload") fleet_doctrine_drift_count=$(jq -r '.fleet_doctrine_drift_count' <<<"$payload") dry_run=true" 0
}

doctor_json() {
  # flywheel-94nzk: rows passed via fw_jq_with_rows (slurpfile + tmpfile cleanup).
  # scan + last are bounded (repos ≤ 50, last is a single row) so stay on --argjson.
  local scan last
  scan="$(scan_payload_json)"
  last="$(last_apply_json)"
  ledger_rows_json | fw_jq_with_rows --arg schema_version "$SCHEMA_VERSION.doctor" --argjson scan "$scan" --argjson last "$last" '
    ($rows[0]) as $rows
    |
    ($last == null or ($last.success // false) == true) as $last_ok
    | ($last.ts // null) as $last_ts
    | ($rows | map(select(((.ts // "") | tostring | length) > 0)) | sort_by(.ts) | last | .ts // null) as $last_fired
    | ($scan.fleet_doctrine_drift_count // 0) as $drift
    | (if (($last_ok | not) or $drift > 3) then "error"
       elif ($last_fired == null) then "warn"
       elif $drift > 0 then "warn"
       else "pass" end) as $status
    | {schema_version:$schema_version,status:$status,fleet_doctrine_drift_count:$drift,fleet_doctrine_drift_repos:($scan.fleet_doctrine_drift_repos // []),agents_md_fleet_propagator_last_fired_ts:$last_fired,agents_md_fleet_propagation_last_apply_ts:$last_ts,agents_md_fleet_propagation_last_apply_succeeded:$last_ok,thresholds:{drift_count:{warn:1,error:4},last_apply_failed:"error",last_fired_missing:"warn"},ledger_path:$scan.ledger_path,source_agents_md:$scan.source_agents_md,sync_path:$scan.sync_path,repos_checked:$scan.repos_checked}'
}

run_doctor() {
  local payload rc=0
  payload="$(doctor_json)"
  if [[ "$(jq -r '.status' <<<"$payload")" == "error" ]]; then rc=1; fi
  emit "$payload" "status=$(jq -r '.status' <<<"$payload") fleet_doctrine_drift_count=$(jq -r '.fleet_doctrine_drift_count' <<<"$payload") last_apply_succeeded=$(jq -r '.agents_md_fleet_propagation_last_apply_succeeded' <<<"$payload")" "$rc"
}

health_json() {
  local doctor
  doctor="$(doctor_json)"
  jq -c --arg schema_version "$SCHEMA_VERSION.health" '{schema_version:$schema_version,status:(if .status == "error" then "critical" elif .status == "warn" then "degraded" else "green" end),fleet_doctrine_drift_count,fleet_doctrine_drift_repos,agents_md_fleet_propagator_last_fired_ts,agents_md_fleet_propagation_last_apply_ts,agents_md_fleet_propagation_last_apply_succeeded,ledger_path}' <<<"$doctor"
}

run_health() {
  local payload rc
  while :; do
    payload="$(health_json)"
    rc=0
    case "$(jq -r '.status' <<<"$payload")" in
      degraded) rc=1 ;;
      critical) rc=3 ;;
    esac
    emit "$payload" "status=$(jq -r '.status' <<<"$payload") fleet_doctrine_drift_count=$(jq -r '.fleet_doctrine_drift_count' <<<"$payload")" "$rc" || true
    [[ "$WATCH" -eq 1 ]] || return "$rc"
    sleep "$WATCH_INTERVAL"
  done
  return 0
}

contract_self_row_json() {
  jq -nc --arg ts "$(now_iso)" '{primitive_name:"agents-md-fleet-propagator",declares_loop:"yes",self_repair_action:"propagator --apply",measurement_field:"fleet_doctrine_drift_count",escalation_path:"doctor scope error -> fuckup-log:class=fleet-propagation-failed",schema_version:"substrate-loop-contract.v1",bootstrap_seed_v1:"c1zgt wires AGENTS.md fleet propagation drift into doctor and tick-close advisory scan",ts:$ts}'
}

contract_self_row_present() {
  [[ -s "$CONTRACT_LEDGER" ]] || return 1
  jq -s -e '[ .[]? | select(type == "object" and .primitive_name == "agents-md-fleet-propagator") ] | last | type == "object" and .declares_loop == "yes" and (.self_repair_action // "") == "propagator --apply" and (.measurement_field // "") == "fleet_doctrine_drift_count" and (.escalation_path // "") != "" and .schema_version == "substrate-loop-contract.v1" and ((.bootstrap_seed_v1 // "") != "")' "$CONTRACT_LEDGER" >/dev/null 2>&1
}

ensure_contract_self_row() {
  if contract_self_row_present; then
    printf 'present\n'
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$(contract_self_row_json)"
  printf 'appended\n'
}

run_repair() {
  local contract_action="not_requested" actual planned payload
  case "$REPAIR_SCOPE" in
    ledger|substrate-contract|all) ;;
    *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;;
  esac
  planned="$(jq -nc --arg scope "$REPAIR_SCOPE" --arg ledger "$LEDGER" --arg contract "$CONTRACT_LEDGER" --argjson explain "$(json_bool "$EXPLAIN")" --arg idempotency_key "$IDEMPOTENCY_KEY" '{scope:$scope,would_write:[($ledger|split("/")[:-1]|join("/")),$contract],would_delete:[],would_call_external:[],blocked_by:[],explain:$explain,idempotency_key:(if $idempotency_key == "" then null else $idempotency_key end)}')"
  actual='[]'
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")"
    actual="$(jq -nc --arg ledger_dir "$(dirname "$LEDGER")" --arg contract_dir "$(dirname "$CONTRACT_LEDGER")" '[{action:"ensure_dir",path:$ledger_dir,status:"applied"},{action:"ensure_dir",path:$contract_dir,status:"applied"}]')"
    if [[ "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "all" ]]; then
      contract_action="$(ensure_contract_self_row)"
    fi
  fi
  payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION.repair" --arg scope "$REPAIR_SCOPE" --argjson dry_run "$(json_bool "$DRY_RUN")" --argjson apply "$(json_bool "$APPLY")" --argjson planned "$planned" --argjson actual "$actual" --arg contract_action "$contract_action" '{schema_version:$schema_version,scope:$scope,status:"pass",dry_run:$dry_run,apply:$apply,planned_actions:[$planned],actual_actions:$actual,contract_self_row_action:$contract_action}')"
  emit "$payload" "repair scope=$REPAIR_SCOPE apply=$APPLY contract_self_row_action=$contract_action" 0
}

validate_ledger_json() {
  # flywheel-94nzk: rows passed via fw_jq_with_rows (slurpfile + tmpfile cleanup).
  ledger_rows_json | fw_jq_with_rows --arg schema_version "$SCHEMA_VERSION.validate" --arg target "$VALIDATE_TARGET" '
    ($rows[0]) as $rows
    | ($rows | map(select(((.schema_version // "") | startswith("agents-md-fleet-propagation") | not) or ((.action // "") | IN("propagate","scan") | not) or ((.repo // "") == "") or (((.action // "") == "propagate") and (((.success | type) != "boolean") or ((.status // "") | IN("succeeded","failed") | not)))))) as $bad
    | {schema_version:$schema_version,target:$target,status:(if ($bad | length) == 0 then "pass" else "fail" end),rows_checked:($rows | length),invalid_rows:($bad | length)}'
}

run_validate() {
  local payload rc=0
  [[ "$VALIDATE_TARGET" == "ledger" ]] || { echo "ERR: unsupported validate target: $VALIDATE_TARGET" >&2; return 2; }
  payload="$(validate_ledger_json)"
  [[ "$(jq -r '.status' <<<"$payload")" == "pass" ]] || rc=1
  emit "$payload" "validate target=$VALIDATE_TARGET status=$(jq -r '.status' <<<"$payload") rows_checked=$(jq -r '.rows_checked' <<<"$payload")" "$rc"
}

run_audit() {
  # flywheel-94nzk: rows passed via fw_jq_with_rows (slurpfile + tmpfile cleanup).
  # doctor envelope is bounded (no inlined rows) so stays on --argjson.
  local doctor contract_present
  doctor="$(doctor_json)"
  if contract_self_row_present; then contract_present=true; else contract_present=false; fi
  ledger_rows_json | fw_jq_with_rows --arg schema_version "$SCHEMA_VERSION.audit" --argjson doctor "$doctor" --argjson contract_present "$contract_present" '
    ($rows[0]) as $rows
    | {schema_version:$schema_version,ledger_rows_total:($rows|length),recent_rows:($rows[-10:]),doctor:$doctor,contract_self_row_present:$contract_present}' |
    while IFS= read -r payload; do
      emit "$payload" "audit rows_total=$(jq -r '.ledger_rows_total' <<<"$payload") contract_self_row_present=$(jq -r '.contract_self_row_present' <<<"$payload")" 0
    done
  return 0
}

run_why() {
  [[ -n "$WHY_ID" ]] || { echo "ERR: why requires ID" >&2; return 2; }
  # flywheel-94nzk: rows passed via fw_jq_with_rows (slurpfile + tmpfile cleanup).
  # scan envelope is bounded by fleet repo count, stays on --argjson.
  local scan
  scan="$(scan_payload_json)"
  ledger_rows_json | fw_jq_with_rows --arg schema_version "$SCHEMA_VERSION.why" --arg id "$WHY_ID" --argjson scan "$scan" '
    ($rows[0]) as $rows
    | {schema_version:$schema_version,id:$id,ledger_match:($rows | map(select((.repo // "") == $id or (.ts // "") == $id)) | last // null),scan_match:($scan.repos | map(select((.repo // "") == $id or (.reason // "") == $id)) | .[0] // null)}' |
    while IFS= read -r payload; do
      emit "$payload" "why id=$WHY_ID ledger_match=$(jq -r '.ledger_match != null' <<<"$payload") scan_match=$(jq -r '.scan_match != null' <<<"$payload")" 0
    done
  return 0
}

run_schema() {
  case "$SCHEMA_TOPIC" in
    propagation) jq -nc --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,required:["fleet_doctrine_drift_count","fleet_doctrine_drift_repos","repos","planned_actions"]}' ;;
    doctor) jq -nc --arg schema_version "$SCHEMA_VERSION.doctor" '{schema_version:$schema_version,required:["agents_md_fleet_propagator_last_fired_ts","fleet_doctrine_drift_count","fleet_doctrine_drift_repos","agents_md_fleet_propagation_last_apply_ts","agents_md_fleet_propagation_last_apply_succeeded"]}' ;;
    ledger) jq -nc --arg schema_version "$SCHEMA_VERSION.ledger" '{schema_version:$schema_version,append:"fw_jsonl_append_validated",path_env:"AGENTS_MD_FLEET_LEDGER"}' ;;
    contract) contract_self_row_json ;;
    *) echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2; return 2 ;;
  esac
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO_ROOT" --arg source "$SOURCE_AGENTS" --arg sync "$SYNC_SH" --arg ledger "$LEDGER" --arg fuckup "$FUCKUP_LOG" --arg contract "$CONTRACT_LEDGER" --arg jsonl_append_lib "$JSONL_APPEND_LIB" '{name:"agents-md-fleet-propagator.sh",version:$version,schema_version:$schema_version,repo:$repo,source_agents_md:$source,sync_path:$sync,ledger_path:$ledger,fuckup_log_path:$fuckup,contract_ledger_path:$contract,jsonl_append_lib:$jsonl_append_lib,exit_codes:{"0":"pass or dry-run scan emitted","1":"doctor/apply/validation failure","2":"usage error","3":"append primitive missing or failed"}}'
}

examples_json() {
  jq -nc '{examples:["agents-md-fleet-propagator.sh --json","agents-md-fleet-propagator.sh --target /Users/josh/Developer/mobile-eats --json","agents-md-fleet-propagator.sh --target /Users/josh/Developer/mobile-eats --apply --json","agents-md-fleet-propagator.sh --doctor --json","agents-md-fleet-propagator.sh repair --scope substrate-contract --apply --json"]}'
}

quickstart_json() {
  jq -nc '{steps:["Run --json to inspect fleet AGENTS.md drift. This is dry-run by default.","Use --target REPO to scope to one installed repo.","Add --apply only when an explicit propagation tick is authorized.","Run flywheel-loop doctor --scope agents-md-fleet-propagation --json for thresholds."]}'
}

help_topic() {
  case "$HELP_TOPIC" in
    scan) printf 'scan: compares flywheel-origin AGENTS.md hash to installed repo AGENTS.md hashes; no writes by default.\n' ;;
    apply) printf 'apply: requires --apply; calls canonical sync.sh --apply-three-surface --target REPO and writes JSONL ledger rows.\n' ;;
    doctor) printf 'doctor: reports fleet_doctrine_drift_count, drift repos, and last propagation apply health.\n' ;;
    repair) printf 'repair: default dry-run; --apply can ensure ledger dirs and emit substrate-loop-contract self-row.\n' ;;
    *) printf 'unknown topic: %s\n' "$HELP_TOPIC"; return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_agents_md_fleet_propagator_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--target --dry-run --apply --record-scan --json --doctor health repair validate audit why schema --info --examples quickstart help completion --scope --watch --interval --ledger --source-agents --sync" -- "$cur") )
}
complete -F _agents_md_fleet_propagator_completion agents-md-fleet-propagator.sh
EOF
      ;;
    zsh) printf 'compadd -- --target --dry-run --apply --record-scan --json --doctor health repair validate audit why schema --info --examples quickstart help completion --scope --watch --interval --ledger --source-agents --sync\n' ;;
    *) echo "ERR: completion shell must be bash or zsh" >&2; return 2 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_REPO="${2:?}"; shift 2 ;;
    --target=*) TARGET_REPO="${1#*=}"; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    health) MODE="health"; shift ;;
    repair|--repair) MODE="repair"; shift ;;
    validate) MODE="validate"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then VALIDATE_TARGET="$1"; shift; fi ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then WHY_ID="$1"; shift; fi ;;
    schema) MODE="schema"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then SCHEMA_TOPIC="$1"; shift; fi ;;
    # NEW (flywheel-1hshd.2): --schema dash-flag form for parity with the existing
    # `schema` no-dash subcommand. Without this, --schema --json was rejected as
    # "unknown argument" — the only canonical-CLI gap the inventory flagged for
    # this surface (has_schema:false).
    --schema) MODE="schema"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then SCHEMA_TOPIC="$1"; shift; fi ;;
    --schema=*) MODE="schema"; SCHEMA_TOPIC="${1#*=}"; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --record-scan) RECORD_SCAN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --watch) WATCH=1; shift ;;
    --interval) WATCH_INTERVAL="${2:?}"; shift 2 ;;
    --interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    --scope) REPAIR_SCOPE="${2:?}"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
    --repo) REPO_ROOT="${2:?}"; SOURCE_AGENTS="$REPO_ROOT/AGENTS.md"; shift 2 ;;
    --repo=*) REPO_ROOT="${1#*=}"; SOURCE_AGENTS="$REPO_ROOT/AGENTS.md"; shift ;;
    --source-agents) SOURCE_AGENTS="${2:?}"; shift 2 ;;
    --source-agents=*) SOURCE_AGENTS="${1#*=}"; shift ;;
    --sync) SYNC_SH="${2:?}"; shift 2 ;;
    --sync=*) SYNC_SH="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --contract-ledger) CONTRACT_LEDGER="${2:?}"; shift 2 ;;
    --contract-ledger=*) CONTRACT_LEDGER="${1#*=}"; shift ;;
    --fuckup-log) FUCKUP_LOG="${2:?}"; shift 2 ;;
    --fuckup-log=*) FUCKUP_LOG="${1#*=}"; shift ;;
    --roster) FLEET_ROSTER="${2:?}"; shift 2 ;;
    --roster=*) FLEET_ROSTER="${1#*=}"; shift ;;
    --no-color|--no-emoji|--width|--width=*) shift ;;
    --explain) EXPLAIN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="help"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then HELP_TOPIC="$1"; shift; fi ;;
    completion) MODE="completion"; shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then COMPLETION_SHELL="$1"; shift; fi ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  scan) run_scan ;;
  doctor) run_doctor ;;
  health) run_health ;;
  repair) run_repair ;;
  validate) run_validate ;;
  audit) run_audit ;;
  why) run_why ;;
  schema) run_schema ;;
  info) emit "$(info_json)" "agents-md-fleet-propagator $VERSION" 0 ;;
  examples) emit "$(examples_json)" "examples emitted" 0 ;;
  quickstart) emit "$(quickstart_json)" "quickstart emitted" 0 ;;
  help) help_topic ;;
  completion) completion ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
esac
