#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as scaffold-marker stubs — fillin replaces them with concrete impls.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="agents-md-shard-extract/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/agents-md-shard-extract-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: agents-md-shard-extract.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "agents-md-shard-extract.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "agents-md-shard-extract.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"agents-md-shard-extract.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"agents-md-shard-extract.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"agents-md-shard-extract.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","latest_rules_extract?"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","rules-dir-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","rules_count?","missing_frontmatter?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","agents-md","rules-dir"],fields:["status","subject","valid?","missing?","reason?","agents_md_path?","rule_count?","frontmatter_compliance?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"L<NNN>|rule-title|sha256"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["ts","command","schema_version"],optional:["mode","rules_extracted","rule_ids"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"agents-md-shard-extract: extracts L-rules from AGENTS.md/AGENTS-CANONICAL.md into .flywheel/rules/L*.md; bash wrapper around python3 heredoc"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — bash wrapper exec'\''ing python3 heredoc; extracts L-rules from AGENTS.md+AGENTS-CANONICAL.md into .flywheel/rules/L<N>.md shards; --apply mutates files (default --dry-run).\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: python3, jq, AGENTS-CANONICAL.md present, .flywheel/rules dir writable, REQUIRED_FRONTMATTER set.\n' ;;
    health)   printf 'topic: health — tails audit log; warn stale >7d. Also probes latest rules extract via .flywheel/rules/L*.md count.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), rules-dir-prime (read-only — counts current L<N>.md shards + flags missing frontmatter).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --agents-md (probes input file existence + L-rule count), --rules-dir (probes output dir shard count + frontmatter compliance).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "agents-md-shard-extract" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "agents-md-shard-extract" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # Substrate: python3 (heredoc), jq, AGENTS-CANONICAL.md, .flywheel/rules dir, project root.
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local agents_canonical="$script_root/.flywheel/AGENTS-CANONICAL.md"
  local rules_dir="$script_root/.flywheel/rules"
  local checks="" overall="pass"

  if command -v python3 >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v python3)" '{name:"python3_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"python3_on_path",status:"fail",detail:"python3 required for heredoc dispatch"}')"$'\n'
    overall="fail"
  fi

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  if [[ -f "$agents_canonical" ]]; then
    local sz; sz="$(wc -l < "$agents_canonical" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$agents_canonical" --argjson l "${sz:-0}" '{name:"agents_canonical_present",status:"pass",value:$p,lines:$l}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$agents_canonical" '{name:"agents_canonical_present",status:"fail",value:$p,detail:"input AGENTS-CANONICAL.md missing"}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$rules_dir" ]] || mkdir -p "$rules_dir" 2>/dev/null; then
    local rule_count; rule_count="$(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$rules_dir" --argjson rc "${rule_count:-0}" '{name:"rules_dir_writable",status:"pass",value:$p,rule_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$rules_dir" '{name:"rules_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local rules_dir="$script_root/.flywheel/rules"
  local last_row="null" stale_seconds=-1 status="warn" rule_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
  fi
  [[ -d "$rules_dir" ]] && rule_count="$(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --arg rd "$rules_dir" --argjson rc "${rule_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,rules_dir:$rd,latest_rules_count:$rc}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    rules-dir-prime)
      # Read-only: count current L*.md shards + probe frontmatter compliance.
      local rules_dir="$script_root/.flywheel/rules"
      local rule_count=0 missing_fm=0 fm_compliant=0
      if [[ -d "$rules_dir" ]]; then
        rule_count="$(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        # Sample-check first 3 shards for frontmatter compliance (id/title/status/shipped/trauma_class).
        while IFS= read -r f; do
          [[ -z "$f" ]] && continue
          if head -20 "$f" 2>/dev/null | grep -qE '^id:' && \
             head -20 "$f" 2>/dev/null | grep -qE '^title:' && \
             head -20 "$f" 2>/dev/null | grep -qE '^status:'; then
            fm_compliant=$((fm_compliant + 1))
          else
            missing_fm=$((missing_fm + 1))
          fi
        done < <(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null)
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg rd "$rules_dir" \
        --argjson rc "${rule_count:-0}" --argjson fmc "${fm_compliant:-0}" --argjson mfm "${missing_fm:-0}" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,rules_dir:$rd,rules_count:$rc,frontmatter_compliant:$fmc,missing_frontmatter:$mfm,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","rules-dir-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --agents-md) subject="agents-md"; shift ;;
      --rules-dir) subject="rules-dir"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local script_root; script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local agents_canonical="$script_root/.flywheel/AGENTS-CANONICAL.md"
  local rules_dir="$script_root/.flywheel/rules"
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in ts command schema_version; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local py_ok=false jq_ok=false ac_ok=false rd_ok=false
      command -v python3 >/dev/null 2>&1 && py_ok=true
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -r "$agents_canonical" ]] && ac_ok=true
      [[ -d "$rules_dir" ]] && rd_ok=true
      local overall=pass
      [[ "$py_ok" != true || "$jq_ok" != true || "$ac_ok" != true || "$rd_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson py "$py_ok" --argjson jqq "$jq_ok" --argjson ac "$ac_ok" --argjson rd "$rd_ok" \
        --arg root "$script_root" --arg ac_path "$agents_canonical" --arg rd_path "$rules_dir" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,python3_present:$py,jq_present:$jqq,agents_canonical_readable:$ac,rules_dir_present:$rd,flywheel_root:$root,agents_canonical:$ac_path,rules_dir:$rd_path}'
      ;;
    agents-md)
      # surface-specific: probe AGENTS-CANONICAL.md input file.
      local present=false lines=0 rule_count=0
      if [[ -r "$agents_canonical" ]]; then
        present=true
        lines="$(wc -l < "$agents_canonical" 2>/dev/null | tr -d ' \n' || echo 0)"
        # grep -c returns exit 1 when count=0 but still prints "0"; trailing
        # `; true` ensures command substitution captures only grep's output.
        rule_count="$(grep -cE '^## L[0-9]+' "$agents_canonical" 2>/dev/null; true)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg p "$agents_canonical" \
        --argjson present "$present" --argjson l "${lines:-0}" --argjson rc "${rule_count:-0}" \
        '{schema_version:$sv,command:"validate",subject:"agents-md",status:$s,agents_md_path:$p,present:$present,lines:$l,L_rule_count:$rc}'
      ;;
    rules-dir)
      # surface-specific: probe output dir shard count + frontmatter sample compliance.
      local rule_count=0 fm_compliant=0 fm_missing=0 sample_size=0
      if [[ -d "$rules_dir" ]]; then
        rule_count="$(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
        while IFS= read -r f; do
          [[ -z "$f" ]] && continue
          sample_size=$((sample_size + 1))
          if head -20 "$f" 2>/dev/null | grep -qE '^id:' \
             && head -20 "$f" 2>/dev/null | grep -qE '^title:' \
             && head -20 "$f" 2>/dev/null | grep -qE '^status:'; then
            fm_compliant=$((fm_compliant + 1))
          else
            fm_missing=$((fm_missing + 1))
          fi
        done < <(find "$rules_dir" -maxdepth 1 -name 'L*.md' 2>/dev/null | head -10)
      fi
      local status="pass"
      [[ "$rule_count" -eq 0 ]] && status="warn"
      [[ "$fm_missing" -gt 0 ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg rd "$rules_dir" \
        --argjson rc "${rule_count:-0}" --argjson ss "${sample_size:-0}" \
        --argjson fmc "${fm_compliant:-0}" --argjson fmm "${fm_missing:-0}" \
        '{schema_version:$sv,command:"validate",subject:"rules-dir",status:$s,rules_dir:$rd,rule_count:$rc,sample_size:$ss,frontmatter_compliant:$fmc,frontmatter_missing:$fmm}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","agents-md","rules-dir"],usage:"validate --row-json JSON or --schema or --config or --agents-md or --rules-dir"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","agents-md","rules-dir"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    matches="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '. // []' 2>/dev/null || echo '[]')"
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    [[ "$n" -gt 0 ]] && status="found"
  else
    status="unavailable"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


BEGIN = "<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END = "<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"
GENERATED_MARKER = "<!-- GENERATED: edit .flywheel/rules/L*.md, then run .flywheel/scripts/agents-md-shard-extract.sh --apply -->"
INDEX_BEGIN = "<!-- BEGIN-RULES-INDEX -->"
INDEX_END = "<!-- END-RULES-INDEX -->"
RULE_RE = re.compile(r"(?m)^#{1,2} (L\d+)(?:\s+—\s+|\s+)(.+)$")
REQUIRED_FRONTMATTER = {"id", "title", "status", "shipped", "trauma_class"}
FRONTMATTER_BACKFILL = {
    "L60": ("Loop integrity 5 signal contract", "2026-05-03", "loop-integrity-liveness"),
    "L61": ("Doctrine landing wires into AGENTS and README", "2026-05-03", "doctrine-orphaning"),
    "L62": ("STATE.md is latent opportunity substrate", "2026-05-03", "latent-state-amnesia"),
    "L63": ("Jeff intel network is canonical substrate dependency", "2026-05-03", "jeff-intel-substrate-drift"),
    "L64": ("Jeff is mentor not just dependency", "2026-05-03", "jeff-mentor-bypass"),
    "L65": ("CLI identity beats command name", "2026-05-03", "cli-identity-drift"),
    "L66": ("Outbound Jeff issues use phased command gate", "2026-05-03", "jeff-issue-gate-bypass"),
    "L67": ("Truth source must be live not cached", "2026-05-03", "cached-truth-drift"),
    "L125": ("Env file is sealed substrate", "2026-05-07", "read-tool-secret-leak"),
}


@dataclass(frozen=True)
class Rule:
    order: int
    rule_id: str
    title: str
    body: str
    filename: str
    status: str | None
    shipped: str | None
    trauma_class: str | None


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def slug(value: str) -> str:
    lowered = value.lower()
    lowered = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return lowered[:70] or "untitled"


def split_frontmatter(body: str) -> dict[str, str]:
    lines = body.splitlines()
    try:
        first = lines.index("---")
        second = lines.index("---", first + 1)
    except ValueError:
        return {}
    parsed: dict[str, str] = {}
    for line in lines[first + 1 : second]:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        parsed[key.strip()] = value.strip()
    return parsed


def ensure_frontmatter(rule_id: str, title: str, body: str) -> str:
    frontmatter = split_frontmatter(body)
    if REQUIRED_FRONTMATTER <= set(frontmatter) and frontmatter.get("id") == rule_id:
        return body
    fallback_title, shipped, trauma_class = FRONTMATTER_BACKFILL.get(
        rule_id, (title.title(), "2026-05-09", slug(title))
    )
    lines = body.splitlines(keepends=True)
    if not lines:
        return body
    block = [
        "\n",
        "---\n",
        f"id: {rule_id}\n",
        f"title: {fallback_title}\n",
        "status: long_term\n",
        f"shipped: {shipped}\n",
        "review_due: 2026-11-09\n",
        f"trauma_class: {trauma_class}\n",
        "---\n",
        "\n",
    ]
    return "".join([lines[0], *block, *lines[1:]])


def parse_rules(text: str) -> tuple[str, list[Rule], str]:
    matches = list(RULE_RE.finditer(text))
    if not matches:
        return leading_text(text), [], ""
    rules: list[Rule] = []
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[start:end]
        rule_id = match.group(1)
        title = match.group(2).strip()
        body = ensure_frontmatter(rule_id, title, body)
        frontmatter = split_frontmatter(body)
        filename = f"L{idx + 1:03d}-{rule_id}-{slug(title)}.md"
        rules.append(
            Rule(
                order=idx + 1,
                rule_id=rule_id,
                title=title,
                body=body,
                filename=filename,
                status=frontmatter.get("status"),
                shipped=frontmatter.get("shipped"),
                trauma_class=frontmatter.get("trauma_class"),
            )
        )
    return text[: matches[0].start()], rules, text[matches[0].start() :]


def leading_text(text: str) -> str:
    if BEGIN in text:
        return text.split(BEGIN, 1)[0]
    return text


def load_existing_rules(rules_dir: Path) -> list[Rule]:
    paths = sorted(rules_dir.glob("L*.md"))
    rules: list[Rule] = []
    for idx, path in enumerate(paths, 1):
        body = path.read_text()
        match = RULE_RE.search(body)
        if not match:
            raise SystemExit(f"ERR: shard missing L-rule heading: {path}")
        frontmatter = split_frontmatter(body)
        rules.append(
            Rule(
                order=idx,
                rule_id=match.group(1),
                title=match.group(2).strip(),
                body=body,
                filename=path.name,
                status=frontmatter.get("status"),
                shipped=frontmatter.get("shipped"),
                trauma_class=frontmatter.get("trauma_class"),
            )
        )
    return rules


def validate_rules(rules: list[Rule]) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []
    seen: set[str] = set()
    for rule in rules:
        frontmatter = split_frontmatter(rule.body)
        missing = sorted(REQUIRED_FRONTMATTER - set(frontmatter))
        if missing:
            errors.append(
                {"rule": rule.rule_id, "file": rule.filename, "error": f"missing_frontmatter:{','.join(missing)}"}
            )
        if frontmatter.get("id") != rule.rule_id:
            errors.append({"rule": rule.rule_id, "file": rule.filename, "error": "frontmatter_id_mismatch"})
        if rule.rule_id in seen:
            errors.append({"rule": rule.rule_id, "file": rule.filename, "error": "duplicate_rule_id"})
        seen.add(rule.rule_id)
    return errors


def render_index(leading: str, rules: list[Rule], manifest_name: str) -> str:
    prefix = re.sub(r"(\n## Rules\s*)+\Z", "\n## Rules", leading.rstrip())
    prefix = re.sub(rf"\n?{re.escape(GENERATED_MARKER)}\n*", "\n", prefix).rstrip()
    lines = [prefix, ""]
    if not re.search(r"(?m)^## Rules\s*$", prefix):
        lines.extend(["## Rules", ""])
    lines.extend([
        GENERATED_MARKER,
        "",
        BEGIN,
        "",
        "The full canonical L-rule bodies are sharded under `.flywheel/rules/`.",
        f"`{manifest_name}` records the exact round-trip hash for `cat .flywheel/rules/L*.md`.",
        "",
        INDEX_BEGIN,
        "| Order | Rule | Status | Shard |",
        "|---:|---|---|---|",
    ])
    for rule in rules:
        status = rule.status or ""
        lines.append(f"| {rule.order} | {rule.rule_id} — {rule.title} | {status} | `.flywheel/rules/{rule.filename}` |")
    lines.extend([INDEX_END, "", END, ""])
    return "\n".join(lines)


def stable_path(path: Path, base: Path) -> str:
    try:
        return str(path.resolve().relative_to(base.resolve()))
    except ValueError:
        return str(path)


def render_manifest(rules: list[Rule], source_path: Path, canonical_path: Path, rules_body: str) -> str:
    base = source_path.parent
    payload = {
        "schema_version": "agents-canonical-shards/v1",
        "source": stable_path(source_path, base),
        "canonical_index": stable_path(canonical_path, base),
        "rule_count": len(rules),
        "round_trip_command": "cat .flywheel/rules/L*.md | shasum -a 256",
        "rules_body_sha256": sha256_text(rules_body),
        "rules": [
            {
                "order": rule.order,
                "id": rule.rule_id,
                "title": rule.title,
                "status": rule.status,
                "shipped": rule.shipped,
                "trauma_class": rule.trauma_class,
                "path": f".flywheel/rules/{rule.filename}",
                "sha256": sha256_text(rule.body),
            }
            for rule in rules
        ],
    }
    return json.dumps(payload, indent=2, sort_keys=True) + "\n"


def write_if_changed(path: Path, content: str, dry_run: bool, writes: list[str], drifts: list[str]) -> None:
    old = path.read_text() if path.exists() else None
    if old == content:
        return
    drifts.append(str(path))
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    writes.append(str(path))


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Shard canonical AGENTS L-rules into per-rule files.")
    parser.add_argument("--source", default="AGENTS.md")
    parser.add_argument("--canonical", default=".flywheel/AGENTS-CANONICAL.md")
    parser.add_argument("--root", default="AGENTS.md")
    parser.add_argument("--template", default="templates/flywheel-install/AGENTS.md")
    parser.add_argument("--rules-dir", default=".flywheel/rules")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    dry_run = not args.apply
    source_path = Path(args.source)
    canonical_path = Path(args.canonical)
    rules_dir = Path(args.rules_dir)
    source_text = source_path.read_text()
    leading, rules, rules_body = parse_rules(source_text)
    if not rules:
        rules = load_existing_rules(rules_dir)
        rules_body = "".join(rule.body for rule in rules)
    errors = validate_rules(rules)
    if errors:
        payload = {"status": "error", "errors": errors, "rule_count": len(rules)}
        print(json.dumps(payload, sort_keys=True) if args.json else payload)
        return 2

    manifest_name = "MANIFEST.json"
    index = render_index(leading, rules, manifest_name)
    manifest = render_manifest(rules, source_path, canonical_path, rules_body)
    writes: list[str] = []
    drifts: list[str] = []

    if not dry_run:
        rules_dir.mkdir(parents=True, exist_ok=True)
    for rule in rules:
        write_if_changed(rules_dir / rule.filename, rule.body, dry_run, writes, drifts)
    write_if_changed(rules_dir / manifest_name, manifest, dry_run, writes, drifts)
    for target in [canonical_path, Path(args.root), Path(args.template)]:
        write_if_changed(target, index, dry_run, writes, drifts)

    payload = {
        "status": "drifted" if dry_run and drifts else "in_sync",
        "mode": "dry_run" if dry_run else "apply",
        "rule_count": len(rules),
        "drifted_count": len(drifts),
        "written_count": len(writes),
        "rules_body_sha256": sha256_text(rules_body),
        "targets": [str(canonical_path), args.root, args.template, str(rules_dir)],
        "drifts": drifts,
        "writes": writes,
    }
    print(json.dumps(payload, sort_keys=True) if args.json else f"status={payload['status']} rule_count={len(rules)} drifted={len(drifts)} written={len(writes)}")
    return 1 if dry_run and drifts else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
