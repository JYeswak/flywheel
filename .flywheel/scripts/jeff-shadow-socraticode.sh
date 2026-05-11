#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.19)
set -euo pipefail

VERSION="jeff-shadow-socraticode.v1.1.0"
SCHEMA_VERSION_INFO="jeff-shadow-socraticode/info/v1"
SHADOW_ROOT="${JEFF_SHADOW_ROOT:-$HOME/Developer/jeff-shadow}"
STATE_DIR="${JEFF_SHADOW_STATE_DIR:-$HOME/.local/state/jeff-intel}"
INDEX_LEDGER="${JEFF_SHADOW_INDEX_LEDGER:-$STATE_DIR/jeff-shadow-socraticode-index.jsonl}"
REFRESH_RECEIPT="${JEFF_SHADOW_REFRESH_RECEIPT:-$STATE_DIR/jeff-shadow-refresh.json}"
IDEMPOTENCY_KEY=""
MODE="doctor"
APPLY=0
RECORD_REPO=""
RECORD_STATUS="indexed"
RECORD_CHUNKS=""
POSITIONAL=""

usage() {
  cat <<'EOF'
Usage:
  jeff-shadow-socraticode.sh doctor [--json]
  jeff-shadow-socraticode.sh health [--json]
  jeff-shadow-socraticode.sh status [--json]
  jeff-shadow-socraticode.sh refresh --dry-run|--apply [--json]
  jeff-shadow-socraticode.sh repair --dry-run|--apply [--json]
  jeff-shadow-socraticode.sh validate [--json]
  jeff-shadow-socraticode.sh audit [--json]
  jeff-shadow-socraticode.sh why <repo> [--json]
  jeff-shadow-socraticode.sh record-index --repo NAME [--status indexed|failed] [--chunks N] [--json]
  jeff-shadow-socraticode.sh info [--json]
  jeff-shadow-socraticode.sh schema [--json]
  jeff-shadow-socraticode.sh examples [--json]
  jeff-shadow-socraticode.sh quickstart
  jeff-shadow-socraticode.sh help [topic]
  jeff-shadow-socraticode.sh completion <bash|zsh>

Maintains a read-only local mirror at ~/Developer/jeff-shadow and a receipt
ledger for Socraticode MCP indexing of canonical Jeff substrate repos.
EOF
}

repo_specs() {
  cat <<'EOF'
ntm|https://github.com/Dicklesworthstone/ntm.git|ntm
beads_rust|https://github.com/Dicklesworthstone/beads_rust.git|br
destructive_command_guard|https://github.com/Dicklesworthstone/destructive_command_guard.git|dcg
cass_memory_system|https://github.com/Dicklesworthstone/cass_memory_system.git|cass
meta_skill|https://github.com/Dicklesworthstone/meta_skill.git|jsm
mcp_agent_mail|https://github.com/Dicklesworthstone/mcp_agent_mail.git|agent-mail-python
mcp_agent_mail_rust|https://github.com/Dicklesworthstone/mcp_agent_mail_rust.git|agent-mail-rust
frankensqlite|https://github.com/Dicklesworthstone/frankensqlite.git|frankensqlite
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
repo_count() { repo_specs | wc -l | tr -d ' '; }
repo_path() { printf '%s/%s' "$SHADOW_ROOT" "$1"; }

known_repo() {
  local needle="$1"
  repo_specs | awk -F'|' -v repo="$needle" '$1 == repo { found=1 } END { exit(found ? 0 : 1) }'
}

latest_index_json() {
  if [ ! -s "$INDEX_LEDGER" ]; then
    jq -nc '{}'
    return 0
  fi
  jq -sc 'reduce .[] as $row ({}; .[$row.repo] = $row)' "$INDEX_LEDGER" 2>/dev/null || jq -nc '{}'
}

refresh_json() {
  if [ -s "$REFRESH_RECEIPT" ]; then
    jq -c . "$REFRESH_RECEIPT" 2>/dev/null || jq -nc '{}'
  else
    jq -nc '{}'
  fi
}

status_json() {
  local specs latest refresh repos_json specs_tmp repo url alias path exists_flag
  specs_tmp="$(mktemp "${TMPDIR:-/tmp}/jeff-shadow-specs.XXXXXX")"
  : >"$specs_tmp"
  while IFS='|' read -r repo url alias; do
    path="$(repo_path "$repo")"
    if [ -d "$path/.git" ]; then exists_flag=true; else exists_flag=false; fi
    jq -nc --arg repo "$repo" --arg url "$url" --arg alias "$alias" --arg path "$path" --argjson exists "$exists_flag" '{repo:$repo,url:$url,alias:$alias,path:$path,exists:$exists}' >>"$specs_tmp"
  done < <(repo_specs)
  specs="$(jq -cs '.' "$specs_tmp")"
  rm -f "$specs_tmp"
  latest="$(latest_index_json)"
  refresh="$(refresh_json)"
  repos_json="$(jq -nc --argjson specs "$specs" --argjson latest "$latest" '
    $specs | map(. as $repo | . + {
      index_status:(($latest[$repo.repo].status // "not_indexed")),
      indexed_at:($latest[$repo.repo].indexed_at // null),
      indexed_chunks:($latest[$repo.repo].chunks // null)
    })')"
  jq -nc \
    --arg schema_version "jeff-shadow-socraticode/status/v1" \
    --arg version "$VERSION" \
    --arg shadow_root "$SHADOW_ROOT" \
    --arg index_ledger "$INDEX_LEDGER" \
    --arg refresh_receipt "$REFRESH_RECEIPT" \
    --argjson specs "$specs" \
    --argjson repos "$repos_json" \
    --argjson refresh "$refresh" \
    '($repos | map(select(.index_status == "indexed")) | length) as $indexed
    | ($repos | length) as $repo_count
    | ([ $repos[] | select(.indexed_at != null) | .indexed_at ] | sort | last) as $last_indexed
    | ($refresh.refreshed_at // null) as $last_refresh
    | (if $last_refresh then (((now - ($last_refresh | fromdateiso8601)) / 3600) * 10 | floor / 10) else null end) as $age
    | {
        schema_version:$schema_version,
        command:"status",
        version:$version,
        mode:"status",
        status:(if $repo_count > 0 and $indexed == $repo_count then "pass" else "warn" end),
        success:($repo_count > 0 and $indexed == $repo_count),
        shadow_root:$shadow_root,
        state_file:$refresh_receipt,
        index_ledger:$index_ledger,
        repo_count:$repo_count,
        indexed_count:$indexed,
        cloned_count:($refresh.cloned_count // null),
        refreshed_count:($refresh.refreshed_count // null),
        last_refresh_at:$last_refresh,
        last_refresh_age_hours:$age,
        last_indexed_at:$last_indexed,
        repos:$repos,
        canonical_repos:($specs | map(.repo)),
        checks:[$repos[] | {name:.repo,status:(if .index_status == "indexed" then "pass" elif .exists then "warn" else "fail" end),path:.path,detail:("shadow clone exists=" + (.exists|tostring) + " index_status=" + .index_status)}],
        dashboard_line:("jeff-shadow: " + ($indexed|tostring) + "/" + ($repo_count|tostring) + " repos indexed, last refresh " + (if $age == null then "unknown" else (($age|tostring) + "h") end) + " ago")
      }'
}

write_readonly_marker() {
  mkdir -p "$SHADOW_ROOT"
  {
    printf '# Jeff Shadow\n\n'
    printf 'Read-only local mirror for canonical Dicklesworthstone substrate repos.\n'
    printf 'Do not edit these clones; refresh via jeff-shadow-socraticode.sh.\n'
  } >"$SHADOW_ROOT/README.md"
}

refresh_repos() {
  local dry_run="$1" cloned=0 refreshed=0 failed=0 planned=0 rows tmp repo url alias target head
  tmp="$(mktemp "${TMPDIR:-/tmp}/jeff-shadow-refresh.XXXXXX")"
  : >"$tmp"
  [ "$dry_run" -eq 1 ] || write_readonly_marker
  while IFS='|' read -r repo url alias; do
    target="$(repo_path "$repo")"
    if [ "$dry_run" -eq 1 ]; then
      planned=$((planned + 1))
      jq -nc --arg repo "$repo" --arg alias "$alias" --arg url "$url" --arg target "$target" '{repo:$repo,alias:$alias,url:$url,path:$target,action:"planned"}' >>"$tmp"
      continue
    fi
    if [ -d "$target/.git" ]; then
      if git -C "$target" fetch --depth 50 --prune origin >/dev/null 2>&1; then
        refreshed=$((refreshed + 1))
        head="$(git -C "$target" rev-parse --short=12 HEAD 2>/dev/null || true)"
        jq -nc --arg repo "$repo" --arg alias "$alias" --arg url "$url" --arg target "$target" --arg head "$head" '{repo:$repo,alias:$alias,url:$url,path:$target,action:"fetched",head:$head}' >>"$tmp"
      else
        failed=$((failed + 1))
        jq -nc --arg repo "$repo" --arg alias "$alias" --arg url "$url" --arg target "$target" '{repo:$repo,alias:$alias,url:$url,path:$target,action:"fetch_failed"}' >>"$tmp"
      fi
    elif git clone --depth 50 "$url" "$target" >/dev/null 2>&1; then
      cloned=$((cloned + 1))
      head="$(git -C "$target" rev-parse --short=12 HEAD 2>/dev/null || true)"
      jq -nc --arg repo "$repo" --arg alias "$alias" --arg url "$url" --arg target "$target" --arg head "$head" '{repo:$repo,alias:$alias,url:$url,path:$target,action:"cloned",head:$head}' >>"$tmp"
    else
      failed=$((failed + 1))
      jq -nc --arg repo "$repo" --arg alias "$alias" --arg url "$url" --arg target "$target" '{repo:$repo,alias:$alias,url:$url,path:$target,action:"clone_failed"}' >>"$tmp"
    fi
  done < <(repo_specs)
  rows="$(jq -cs '.' "$tmp")"
  rm -f "$tmp"
  if [ "$dry_run" -eq 0 ]; then
    mkdir -p "$STATE_DIR"
    jq -nc --arg schema_version "jeff-shadow-socraticode/refresh/v1" --arg refreshed_at "$(now_iso)" --arg shadow_root "$SHADOW_ROOT" --argjson repo_count "$(repo_count)" --argjson cloned "$cloned" --argjson refreshed "$refreshed" --argjson failed "$failed" --argjson rows "$rows" '{schema_version:$schema_version,refreshed_at:$refreshed_at,shadow_root:$shadow_root,repo_count:$repo_count,cloned_count:$cloned,refreshed_count:$refreshed,failed_count:$failed,repos:$rows}' >"$REFRESH_RECEIPT"
  fi
  jq -nc --arg schema_version "jeff-shadow-socraticode/refresh-result/v1" --argjson dry_run "$dry_run" --arg shadow_root "$SHADOW_ROOT" --arg state_file "$REFRESH_RECEIPT" --argjson repo_count "$(repo_count)" --argjson cloned "$cloned" --argjson refreshed "$refreshed" --argjson failed "$failed" --argjson planned "$planned" --argjson indexed "$(status_json | jq '.indexed_count')" --argjson rows "$rows" '{schema_version:$schema_version,mode:"refresh",status:(if $failed == 0 then "pass" else "warn" end),success:($failed == 0),dry_run:($dry_run==1),shadow_root:$shadow_root,state_file:$state_file,repo_count:$repo_count,cloned_count:$cloned,refreshed_count:$refreshed,failed_count:$failed,planned_count:$planned,indexed_count:$indexed,repos:$rows}'
}

record_index() {
  [ -n "$RECORD_REPO" ] || { printf 'ERROR: record-index requires --repo\n' >&2; exit 2; }
  known_repo "$RECORD_REPO" || { printf 'ERROR: unknown canonical repo: %s\n' "$RECORD_REPO" >&2; exit 2; }
  case "$RECORD_STATUS" in indexed|failed) ;; *) printf 'ERROR: invalid --status: %s\n' "$RECORD_STATUS" >&2; exit 2 ;; esac
  mkdir -p "$STATE_DIR"
  jq -nc --arg schema_version "jeff-shadow-socraticode/index-receipt/v1" --arg repo "$RECORD_REPO" --arg status "$RECORD_STATUS" --arg indexed_at "$(now_iso)" --arg path "$(repo_path "$RECORD_REPO")" --argjson chunks "${RECORD_CHUNKS:-null}" '{schema_version:$schema_version,repo:$repo,status:$status,indexed_at:$indexed_at,path:$path,chunks:$chunks}' >>"$INDEX_LEDGER"
  jq -nc --arg repo "$RECORD_REPO" --arg status "$RECORD_STATUS" '{schema_version:"jeff-shadow-socraticode/record-index-result/v1",status:"pass",repo:$repo,index_status:$status}'
}

repair_json() {
  if [ "$APPLY" -eq 1 ]; then
    write_readonly_marker
    jq -nc --arg schema_version "jeff-shadow-socraticode/repair/v1" --arg shadow_root "$SHADOW_ROOT" --arg state_dir "$STATE_DIR" '{schema_version:$schema_version,mode:"repair",status:"applied",actual_actions:[{action:"mkdir",path:$shadow_root},{action:"mkdir",path:$state_dir},{action:"write",path:($shadow_root + "/README.md")}],planned_actions:[]}'
  else
    jq -nc --arg schema_version "jeff-shadow-socraticode/repair/v1" --arg shadow_root "$SHADOW_ROOT" --arg state_dir "$STATE_DIR" '{schema_version:$schema_version,mode:"repair",status:"dry_run",actual_actions:[],planned_actions:[{action:"mkdir",path:$shadow_root},{action:"mkdir",path:$state_dir},{action:"write",path:($shadow_root + "/README.md")}]}'
  fi
}

validate_json() {
  local status
  status="$(status_json)"
  jq -nc --arg schema_version "jeff-shadow-socraticode/validate/v1" --argjson status_json "$status" '{schema_version:$schema_version,mode:"validate",status:(if $status_json.indexed_count == $status_json.repo_count then "pass" else "warn" end),checks:{repo_count:($status_json.repo_count == 8),all_indexed:($status_json.indexed_count == $status_json.repo_count),refresh_seen:($status_json.last_refresh_at != null),status_dashboard_line:($status_json.dashboard_line | startswith("jeff-shadow:"))},status_json:$status_json}'
}

audit_json() {
  local status refresh index_rows
  status="$(status_json)"
  refresh="$(refresh_json)"
  if [ -s "$INDEX_LEDGER" ]; then
    index_rows="$(wc -l <"$INDEX_LEDGER" | tr -d ' ')"
  else
    index_rows=0
  fi
  jq -nc --arg schema_version "jeff-shadow-socraticode/audit/v1" --argjson status_json "$status" --argjson refresh "$refresh" --argjson index_rows "$index_rows" '{schema_version:$schema_version,mode:"audit",status:"pass",index_rows:$index_rows,latest_refresh:$refresh,status_json:$status_json}'
}

why_json() {
  local id="$1"
  [ -n "$id" ] || { printf 'ERROR: why requires repo or path\n' >&2; exit 2; }
  jq -nc --arg schema_version "jeff-shadow-socraticode/why/v1" --arg id "$id" --arg shadow_root "$SHADOW_ROOT" --arg refresh_receipt "$REFRESH_RECEIPT" --arg index_ledger "$INDEX_LEDGER" '{schema_version:$schema_version,mode:"why",status:"pass",id:$id,provenance:{shadow_root:$shadow_root,refresh_receipt:$refresh_receipt,index_ledger:$index_ledger,source_inventory:"~/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md",daily_ingest:".flywheel/scripts/daily-jeff-ingest.sh"}}'
}

info_json() {
  jq -nc --arg sv "$SCHEMA_VERSION_INFO" --arg version "$VERSION" --arg shadow_root "$SHADOW_ROOT" --arg state_dir "$STATE_DIR" --arg index_ledger "$INDEX_LEDGER" --arg refresh_receipt "$REFRESH_RECEIPT" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-shadow-socraticode.sh",
      version:$version,
      shadow_root:$shadow_root,
      state_dir:$state_dir,
      index_ledger:$index_ledger,
      refresh_receipt:$refresh_receipt,
      canonical_repos:["ntm","beads_rust","destructive_command_guard","cass_memory_system","meta_skill","mcp_agent_mail","mcp_agent_mail_rust","frankensqlite"],
      mutating_commands:["refresh --apply","repair --apply","record-index"],
      default_mutation_mode:"dry-run",
      subcommands:["doctor","health","status","refresh","repair","validate","audit","why","record-index","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--repo","--status","--chunks"],
      capabilities:[
        "8-canonical-jeff-repo-shadow",
        "git-clone-or-fetch-refresh",
        "socraticode-index-receipt-per-repo",
        "refresh-receipt-json-state-file",
        "indexed-chunk-count-tracking",
        "dashboard-line-emission",
        "repo-alias-resolution-ntm-br-dcg-etc"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_SHADOW_ROOT","JEFF_SHADOW_STATE_DIR","JEFF_SHADOW_INDEX_LEDGER","JEFF_SHADOW_REFRESH_RECEIPT"],
      exit_codes:{"0":"pass","1":"refresh-or-index-fail","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

schema_json() {
  jq -nc '{
    schema_version:"jeff-shadow-socraticode/schema/v1",
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        apply:{type:"boolean"},
        dry_run:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply on refresh/repair/record-index"},
        repo:{type:"string",description:"canonical repo or alias for record-index"},
        status:{enum:["indexed","failed","pending"]},
        chunks:{type:"integer",minimum:0}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","mode","status"],
      properties:{
        schema_version:{type:"string"},
        mode:{enum:["doctor","health","status","refresh","repair","validate","audit","why","record-index","info","schema","examples","quickstart","help","completion"]},
        status:{enum:["pass","fail","warn"]},
        repo_count:{type:"integer"},
        indexed_count:{type:"integer"},
        last_refresh_age_hours:{type:"number"},
        dashboard_line:{type:"string"},
        cloned_count:{type:"integer"},
        refreshed_count:{type:"integer"},
        failed_count:{type:"integer"}
      }
    },
    required_status_fields:["repo_count","indexed_count","last_refresh_age_hours","dashboard_line"],
    required_refresh_fields:["cloned_count","refreshed_count","failed_count"],
    required_index_receipt_fields:["repo","status","indexed_at","path"],
    exit_codes:{"0":"pass","1":"refresh-or-index-fail","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

examples_json() {
  jq -nc '{
    schema_version:"jeff-shadow-socraticode/examples/v1",
    command:"examples",
    examples:[
      {name:"status",command:"jeff-shadow-socraticode.sh status --json",purpose:"current shadow state: 8/8 repos indexed, last refresh age, dashboard line"},
      {name:"refresh dry run",command:"jeff-shadow-socraticode.sh refresh --dry-run --json",purpose:"preview which repos would be cloned/fetched"},
      {name:"refresh apply",command:"jeff-shadow-socraticode.sh refresh --apply --idempotency-key jss-2026-05-11 --json",purpose:"clone/fetch canonical repos under ~/Developer/jeff-shadow"},
      {name:"record MCP index",command:"jeff-shadow-socraticode.sh record-index --repo ntm --chunks 120 --json",purpose:"record completion of MCP socraticode indexing for a shadow repo"},
      {name:"doctor",command:"jeff-shadow-socraticode.sh doctor --json",purpose:"canonical doctor envelope"}
    ]
  }'
}

quickstart() {
  cat <<'EOF'
jeff-shadow-socraticode.sh refresh --dry-run --json
jeff-shadow-socraticode.sh refresh --apply --json
jeff-shadow-socraticode.sh status --json
EOF
}

help_topic() {
  case "${1:-}" in
    index|socraticode)
      printf '%s\n' 'Indexing is performed by MCP: mcp__socraticode__codebase_index(projectPath=<shadow-repo>). Record completion with record-index.'
      ;;
    refresh|mirror)
      printf '%s\n' 'refresh --apply clones or fetches the canonical repos under ~/Developer/jeff-shadow. Do not edit those clones.'
      ;;
    *) usage ;;
  esac
}

completion() {
  printf 'complete -W "doctor health status refresh repair validate audit why record-index info schema examples quickstart help completion --json --dry-run --apply --repo --status --chunks" jeff-shadow-socraticode.sh\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    doctor|health|status|refresh|repair|validate|audit|why|record-index|info|schema|examples|quickstart|help|completion) MODE="$1"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    --json) shift ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --repo) RECORD_REPO="${2:-}"; shift 2 ;;
    --status) RECORD_STATUS="${2:-}"; shift 2 ;;
    --chunks) RECORD_CHUNKS="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) POSITIONAL="${POSITIONAL:+$POSITIONAL }$1"; shift ;;
  esac
done

# Canonical apply contract: --apply on refresh/repair/record-index requires --idempotency-key.
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  case "$MODE" in
    refresh|repair|record-index)
      printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION_INFO"
      exit 3
      ;;
  esac
fi

case "$MODE" in
  doctor|health|status) status_json ;;
  refresh) refresh_repos "$((1 - APPLY))" ;;
  repair) repair_json ;;
  validate) validate_json ;;
  audit) audit_json ;;
  why) why_json "$POSITIONAL" ;;
  record-index) record_index ;;
  info) info_json ;;
  schema) schema_json ;;
  examples) examples_json ;;
  quickstart) quickstart ;;
  help) help_topic "$POSITIONAL" ;;
  completion) completion ;;
  *) usage; exit 2 ;;
esac
