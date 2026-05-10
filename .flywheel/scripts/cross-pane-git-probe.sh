#!/usr/bin/env bash
# cross-pane-git-probe.sh — orchestrator per-tick probe trio for the
# cross-pane-git-discipline doctrine (.flywheel/doctrine/cross-pane-git-discipline.md,
# ratified 2026-05-10T21:35Z bilateral cross-orch). Implements three orchestrator
# responsibilities verbatim:
#
#   1. Active worktree census  — git worktree list --porcelain → count + paths.
#                                 Threshold N>=3 notable, N>=5 bead-class.
#   2. Stale worktree garbage  — git worktree prune --dry-run → count of stale
#                                 worktrees (deleted branch refs, missing paths).
#   3. Concurrent commit window — scan git reflog for HEAD movements <5s apart on
#                                 the same ref → class A or B candidate.
#
# This is a READ-ONLY probe. It does not call `git worktree prune` or any
# mutation; it only reports. Repair is a separate canonical-cli surface (see
# `repair --scope worktree_prune` below — wraps the actual prune behind
# --apply --idempotency-key per the canonical-cli mutation contract).
#
# Bead: flywheel-iro0k (cross-pane-git-discipline wire-in)
# Doctrine: .flywheel/doctrine/cross-pane-git-discipline.md
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-iro0k) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: filled-in (bead flywheel-iro0k)

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="cross-pane-git-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cross-pane-git-probe-runs.jsonl}"
SCAFFOLD_TARGET_REPO="${CROSS_PANE_GIT_PROBE_REPO:-$_SCAFFOLD_REPO_ROOT}"
SCAFFOLD_NOTABLE_THRESHOLD="${CROSS_PANE_GIT_PROBE_NOTABLE_N:-3}"
SCAFFOLD_BEADCLASS_THRESHOLD="${CROSS_PANE_GIT_PROBE_BEADCLASS_N:-5}"
SCAFFOLD_RACE_WINDOW_SEC="${CROSS_PANE_GIT_PROBE_RACE_WINDOW_SEC:-5}"

scaffold_usage() {
  cat <<'USG'
usage: cross-pane-git-probe.sh [SUBCOMMAND] [OPTIONS]

Default invocation: run all 3 doctrine probes against $SCAFFOLD_TARGET_REPO and
emit a single composite envelope.

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status from $SCAFFOLD_AUDIT_LOG
  repair --scope <s>       repair misconfigured state
                            valid scopes: audit_log_dir | audit_log_truncate | worktree_prune
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] subjects: worktree-count | reflog-window | audit-row
  audit [--json] [N]       tail $SCAFFOLD_AUDIT_LOG (default 20 rows)
  why <id>                 provenance: id is row index (numeric, neg=tail) or substring match
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate | audit | why)
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "cross-pane-git-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "cross-pane-git-probe.sh" \
    "v1.0.0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,SCAFFOLD_TARGET_REPO,SCAFFOLD_NOTABLE_THRESHOLD,SCAFFOLD_BEADCLASS_THRESHOLD,SCAFFOLD_RACE_WINDOW_SEC" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"cross-pane-git-probe.sh --json",purpose:"all 3 probes (worktree census + stale garbage + concurrent commit window)"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"cross-pane-git-probe.sh doctor --json",purpose:"probe substrate health"}'
)"$'\n'"$(jq -nc '{name:"validate worktree-count",invocation:"cross-pane-git-probe.sh validate worktree-count",purpose:"emit worktree count + threshold verdict"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"cross-pane-git-probe.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair,validate"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"doctor\"",status:"\"pass\"|\"warn\"|\"fail\"",
          checks:"[{name,status,detail}]",ts:"string(iso8601)"}}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"health\"",status:"\"pass\"|\"warn\"|\"empty\"",
          total_runs:"int",last_run_ts:"string|null",last_status:"string|null",
          pass_rate:"float|null",window:"int"}}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"repair\"",status:"\"dry_run\"|\"applied\"|\"refused\"",
          mode:"\"dry_run\"|\"apply\"",scope:"\"audit_log_dir\"|\"audit_log_truncate\"|\"worktree_prune\"",
          idempotency_key:"string|null",planned_actions:"[obj]",applied_actions:"[obj]"}}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"validate\"",subject:"\"worktree-count\"|\"reflog-window\"|\"audit-row\"",
          status:"\"pass\"|\"warn\"|\"fail\"|\"refused\"",detail:"object"}}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"audit\"",status:"\"pass\"|\"empty\"|\"missing\"",
          row_count:"int",recent:"[obj]"}}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"why\"",id:"string",match_count:"int",
          matches:"[obj]"}}' ;;
    run|default)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:{
          schema_version:"string",command:"\"run\"",status:"\"pass\"|\"warn\"|\"fail\"",
          repo:"string",
          worktree_census:"{count:int,paths:[string],verdict:string}",
          stale_worktree:"{count:int,verdict:string}",
          concurrent_commit_window:"{violation_count:int,window_sec:int,violations:[{ref,delta_sec,old_sha,new_sha}],verdict:string}"}}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          known_surfaces:["run","doctor","health","repair","validate","audit","why"]}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — runs the 3 doctrine probes (worktree census + stale-worktree garbage + concurrent-commit-window) on $SCAFFOLD_TARGET_REPO. Emits composite envelope with per-probe verdicts.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate (git binary, target repo present, .git present, jq/awk/grep deps, audit log dir, repo root, helper-lib). Pass = probe ready; warn = recoverable; fail = blocked.\n' ;;
    health)   printf 'topic: health — summarizes last 50 probe runs from $SCAFFOLD_AUDIT_LOG. Reports total_runs, last_run_ts, last_status, pass_rate. status=empty when log absent.\n' ;;
    repair)   printf 'topic: repair — scopes: audit_log_dir (mkdir -p the parent), audit_log_truncate (keep last 1000 rows), worktree_prune (run git worktree prune on $SCAFFOLD_TARGET_REPO). Default --dry-run; --apply requires --idempotency-key KEY.\n' ;;
    validate) printf 'topic: validate — subjects: worktree-count (emit count + threshold verdict); reflog-window (emit concurrent-commit window violations); audit-row JSONL (verify ts/status fields).\n' ;;
    audit)    printf 'topic: audit — tails $SCAFFOLD_AUDIT_LOG (default 20 rows, override with audit N). Each row: ts, action, status, sha256, repo, probe_summary fields.\n' ;;
    why)      printf 'topic: why — given <id>, look up audit-log rows. id = numeric row index (negative indexes from tail) OR substring matched against status / repo / verdict fields.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "cross-pane-git-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "cross-pane-git-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli surface ----------

scaffold_cmd_doctor() {
  local checks_tmp; checks_tmp="$(mktemp "${TMPDIR:-/tmp}/cpgp-doctor.XXXXXX")"
  trap 'rm -f "$checks_tmp"' RETURN
  local status="pass"
  add_check() {
    local name="$1" stat="$2" detail="$3"
    jq -nc --arg n "$name" --arg s "$stat" --arg d "$detail" \
      '{name:$n,status:$s,detail:$d}' >>"$checks_tmp"
    if [[ "$stat" == "fail" ]]; then status="fail"
    elif [[ "$stat" == "warn" && "$status" != "fail" ]]; then status="warn"
    fi
    return 0
  }

  if command -v git >/dev/null 2>&1; then
    add_check git_available pass "$(command -v git)"
  else
    add_check git_available fail "git not on PATH (load-bearing for all 3 probes)"
  fi

  if [[ -d "$SCAFFOLD_TARGET_REPO" ]]; then
    if [[ -d "$SCAFFOLD_TARGET_REPO/.git" ]] || git -C "$SCAFFOLD_TARGET_REPO" rev-parse --git-dir >/dev/null 2>&1; then
      add_check target_repo_is_git pass "$SCAFFOLD_TARGET_REPO"
    else
      add_check target_repo_is_git fail "$SCAFFOLD_TARGET_REPO is not a git repo"
    fi
  else
    add_check target_repo_is_git fail "target repo dir absent: $SCAFFOLD_TARGET_REPO"
  fi

  for tool in jq awk grep mktemp; do
    if command -v "$tool" >/dev/null 2>&1; then
      add_check "${tool}_available" pass "$(command -v "$tool")"
    else
      add_check "${tool}_available" fail "not on PATH"
    fi
  done

  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -d "$audit_dir" && -w "$audit_dir" ]]; then
    add_check audit_log_dir_writable pass "$audit_dir"
  elif [[ -d "$audit_dir" ]]; then
    add_check audit_log_dir_writable warn "exists but not writable: $audit_dir"
  else
    add_check audit_log_dir_writable warn "missing dir; repair --scope audit_log_dir will create"
  fi

  if [[ "$SCAFFOLD_NOTABLE_THRESHOLD" =~ ^[0-9]+$ ]] \
     && [[ "$SCAFFOLD_BEADCLASS_THRESHOLD" =~ ^[0-9]+$ ]] \
     && [[ "$SCAFFOLD_RACE_WINDOW_SEC" =~ ^[0-9]+$ ]]; then
    add_check thresholds_sane pass "notable=$SCAFFOLD_NOTABLE_THRESHOLD beadclass=$SCAFFOLD_BEADCLASS_THRESHOLD race_window=${SCAFFOLD_RACE_WINDOW_SEC}s"
  else
    add_check thresholds_sane fail "non-integer threshold: notable=$SCAFFOLD_NOTABLE_THRESHOLD beadclass=$SCAFFOLD_BEADCLASS_THRESHOLD race_window=$SCAFFOLD_RACE_WINDOW_SEC"
  fi

  if [[ -d "$_SCAFFOLD_REPO_ROOT" ]]; then
    add_check repo_root_resolved pass "$_SCAFFOLD_REPO_ROOT"
  else
    add_check repo_root_resolved fail "did not resolve: $_SCAFFOLD_REPO_ROOT"
  fi

  if command -v cli_emit_info >/dev/null 2>&1; then
    add_check helper_lib_loaded pass "$_SCAFFOLD_HELPER_LIB"
  else
    add_check helper_lib_loaded warn "helper lib symbols absent — fallback paths active"
  fi

  jq -cs \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$status" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",status:$status,ts:$ts,checks:.}' \
    "$checks_tmp"

  [[ "$status" != "fail" ]]
}

scaffold_cmd_health() {
  local window=50 total_runs=0 last_run_ts="" last_status="" pass_count=0 status="pass"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w,note:"audit log absent — no probe runs recorded yet"}'
    return 0
  fi
  total_runs="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$total_runs" ]] && total_runs=0
  if [[ "$total_runs" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson w "$window" \
      '{schema_version:$sv,command:"health",status:"empty",ts:$ts,total_runs:0,last_run_ts:null,last_status:null,pass_rate:null,window:$w}'
    return 0
  fi
  last_run_ts="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.ts // ""' 2>/dev/null)"
  last_status="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" | jq -r '.status // "unknown"' 2>/dev/null)"
  pass_count="$(tail -n "$window" "$SCAFFOLD_AUDIT_LOG" | jq -s '[.[] | select(.status == "pass")] | length' 2>/dev/null)"
  [[ -z "$pass_count" ]] && pass_count=0
  local sample
  if [[ "$total_runs" -lt "$window" ]]; then sample="$total_runs"; else sample="$window"; fi
  local pass_rate="null"
  if [[ "$sample" -gt 0 ]]; then
    pass_rate="$(awk -v p="$pass_count" -v s="$sample" 'BEGIN{printf "%.4f", p/s}')"
  fi
  if [[ "$last_status" == "fail" ]]; then status="warn"; fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$status" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson total "$total_runs" \
    --arg last_ts "$last_run_ts" \
    --arg last_s "$last_status" \
    --argjson rate "$pass_rate" \
    --argjson w "$sample" \
    '{schema_version:$sv,command:"health",status:$status,ts:$ts,total_runs:$total,last_run_ts:(if $last_ts=="" then null else $last_ts end),last_status:(if $last_s=="" then null else $last_s end),pass_rate:$rate,window:$w}'
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
  case "$scope" in
    audit_log_dir|audit_log_truncate|worktree_prune) ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:null,reason:"--scope required",valid_scopes:["audit_log_dir","audit_log_truncate","worktree_prune"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit_log_dir","audit_log_truncate","worktree_prune"]}'
      return 0 ;;
  esac

  local planned_tmp applied_tmp
  planned_tmp="$(mktemp "${TMPDIR:-/tmp}/cpgp-repair-planned.XXXXXX")"
  applied_tmp="$(mktemp "${TMPDIR:-/tmp}/cpgp-repair-applied.XXXXXX")"
  trap 'rm -f "$planned_tmp" "$applied_tmp"' RETURN
  : >"$planned_tmp"; : >"$applied_tmp"

  case "$scope" in
    audit_log_dir)
      local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      if [[ ! -d "$audit_dir" ]]; then
        jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          mkdir -p "$audit_dir"
          jq -nc --arg dir "$audit_dir" '{action:"mkdir_audit_dir",target:$dir,result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
    audit_log_truncate)
      local keep=1000 row_count=0
      if [[ -f "$SCAFFOLD_AUDIT_LOG" ]]; then
        row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
      fi
      [[ -z "$row_count" ]] && row_count=0
      if [[ "$row_count" -gt "$keep" ]]; then
        local trim=$((row_count - keep))
        jq -nc --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" --argjson keep "$keep" --argjson trim "$trim" \
          '{action:"truncate_audit_log",target:$log,row_count:$rc,keep:$keep,rows_to_drop:$trim}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          local tmp; tmp="$(mktemp "${SCAFFOLD_AUDIT_LOG}.trunc.XXXXXX")"
          tail -n "$keep" "$SCAFFOLD_AUDIT_LOG" >"$tmp" && mv "$tmp" "$SCAFFOLD_AUDIT_LOG"
          jq -nc --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rc "$row_count" --argjson keep "$keep" \
            '{action:"truncate_audit_log",target:$log,kept:$keep,dropped:($rc - $keep),result:"ok"}' >>"$applied_tmp"
        fi
      fi
      ;;
    worktree_prune)
      # Stale-worktree garbage repair (doctrine layer-5 recovery primitive).
      local prune_dry; prune_dry="$(git -C "$SCAFFOLD_TARGET_REPO" worktree prune --dry-run 2>&1 || printf 'PRUNE_FAILED\n')"
      local stale_count; stale_count="$(printf '%s\n' "$prune_dry" | grep -c '^Removing ' || true)"
      [[ -z "$stale_count" ]] && stale_count=0
      if [[ "$stale_count" -gt 0 ]]; then
        jq -nc --arg repo "$SCAFFOLD_TARGET_REPO" --argjson n "$stale_count" --arg detail "$prune_dry" \
          '{action:"worktree_prune",target:$repo,stale_count:$n,dry_run_output:$detail}' >>"$planned_tmp"
        if [[ "$mode" == "apply" ]]; then
          local prune_apply; prune_apply="$(git -C "$SCAFFOLD_TARGET_REPO" worktree prune 2>&1 || printf 'PRUNE_FAILED\n')"
          jq -nc --arg repo "$SCAFFOLD_TARGET_REPO" --argjson n "$stale_count" --arg detail "$prune_apply" \
            '{action:"worktree_prune",target:$repo,stale_count:$n,result:"ok",apply_output:$detail}' >>"$applied_tmp"
        fi
      fi
      ;;
  esac

  local final_status
  if [[ "$mode" == "apply" ]]; then
    final_status="applied"
    if command -v cli_audit_append >/dev/null 2>&1; then
      cli_audit_append "$SCAFFOLD_AUDIT_LOG" "repair" "applied" \
        "$(jq -nc --arg s "$scope" --arg k "$idem_key" '{scope:$s,idempotency_key:$k}')"
    fi
  else
    final_status="dry_run"
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg status "$final_status" \
    --arg mode "$mode" \
    --arg scope "$scope" \
    --arg key "$idem_key" \
    --slurpfile planned "$planned_tmp" \
    --slurpfile applied "$applied_tmp" \
    '{schema_version:$sv,command:"repair",status:$status,mode:$mode,scope:$scope,idempotency_key:(if $key=="" then null else $key end),planned_actions:$planned,applied_actions:$applied}'
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  case "$subject" in
    worktree-count)
      local count paths_json
      paths_json="$(git -C "$SCAFFOLD_TARGET_REPO" worktree list --porcelain 2>/dev/null \
        | awk '/^worktree / {print $2}' | jq -R . | jq -cs '.')"
      count="$(printf '%s' "$paths_json" | jq 'length')"
      [[ -z "$count" ]] && count=0
      local verdict="pass"
      if [[ "$count" -ge "$SCAFFOLD_BEADCLASS_THRESHOLD" ]]; then verdict="fail"
      elif [[ "$count" -ge "$SCAFFOLD_NOTABLE_THRESHOLD" ]]; then verdict="warn"
      fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg repo "$SCAFFOLD_TARGET_REPO" \
        --arg verdict "$verdict" \
        --argjson count "$count" \
        --argjson notable "$SCAFFOLD_NOTABLE_THRESHOLD" \
        --argjson bead "$SCAFFOLD_BEADCLASS_THRESHOLD" \
        --argjson paths "$paths_json" \
        '{schema_version:$sv,command:"validate",subject:"worktree-count",status:$verdict,repo:$repo,worktree_count:$count,notable_threshold:$notable,beadclass_threshold:$bead,paths:$paths}'
      # Always rc=0 — envelope is the contract; warn/fail is informative not process failure
      return 0
      ;;
    reflog-window)
      local violations_json window="$SCAFFOLD_RACE_WINDOW_SEC"
      violations_json="$(_cpgp_reflog_window "$SCAFFOLD_TARGET_REPO" "$window")"
      local count; count="$(printf '%s' "$violations_json" | jq 'length')"
      [[ -z "$count" ]] && count=0
      local verdict="pass"
      if [[ "$count" -gt 0 ]]; then verdict="warn"; fi
      jq -nc \
        --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg repo "$SCAFFOLD_TARGET_REPO" \
        --arg verdict "$verdict" \
        --argjson window "$window" \
        --argjson count "$count" \
        --argjson violations "$violations_json" \
        '{schema_version:$sv,command:"validate",subject:"reflog-window",status:$verdict,repo:$repo,window_sec:$window,violation_count:$count,violations:$violations}'
      # Always rc=0 — envelope is the contract; warn is informative not a process failure
      return 0
      ;;
    audit-row)
      local row="${1:-}"
      if [[ -z "$row" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"refused",reason:"jsonl row required"}'
        return 64
      fi
      if ! jq -e . >/dev/null 2>&1 <<<"$row"; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"row is not valid JSON"}'
        return 1
      fi
      local missing=()
      for f in ts status; do
        jq -e --arg f "$f" 'has($f)' >/dev/null 2>&1 <<<"$row" || missing+=("$f")
      done
      if (( ${#missing[@]} == 0 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"pass",row:$row}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson row "$row" \
          --argjson missing "$(printf '%s\n' "${missing[@]}" | jq -R . | jq -cs .)" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",status:"fail",reason:"missing required fields",missing:$missing,row:$row}'
        return 1
      fi
      ;;
    ""|--json|--help|-h)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"subject required",valid_subjects:["worktree-count","reflog-window","audit-row"]}'
      return 0 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"unknown subject",subject:$s,valid_subjects:["worktree-count","reflog-window","audit-row"]}'
      return 0 ;;
  esac
}

scaffold_cmd_audit() {
  local limit="${1:-20}"
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    case "$limit" in --json) limit="${2:-20}" ;; *) limit=20 ;; esac
  fi
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",status:"missing",audit_log:$log,row_count:0,recent:[]}'
    return 0
  fi
  local row_count; row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  if [[ "$row_count" -eq 0 ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
      '{schema_version:$sv,command:"audit",status:"empty",row_count:0,recent:[]}'
    return 0
  fi
  local recent
  recent="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null)"
  [[ -z "$recent" ]] && recent='[]'
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --argjson rc "$row_count" \
    --argjson rows "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",row_count:$rc,recent:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument (numeric row index or substring)\n' >&2; return 64
  fi
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"missing",match_count:0,matches:[],reason:"audit log absent"}'
    return 0
  fi
  local matches="[]"
  if [[ "$id" =~ ^-?[0-9]+$ ]]; then
    local row_count; row_count="$(wc -l <"$SCAFFOLD_AUDIT_LOG" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    local idx="$id"
    if [[ "$idx" -lt 0 ]]; then idx=$((row_count + idx + 1)); fi
    if [[ "$idx" -ge 1 && "$idx" -le "$row_count" ]]; then
      matches="$(sed -n "${idx}p" "$SCAFFOLD_AUDIT_LOG" | jq -cs '.' 2>/dev/null)"
    fi
  else
    matches="$(jq -cs --arg id "$id" '[.[] | select(((.status // "") | contains($id)) or ((.repo // "") | contains($id)) or ((.verdict // "") | contains($id)))]' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null)"
  fi
  [[ -z "$matches" ]] && matches='[]'
  local count; count="$(jq 'length' <<<"$matches" 2>/dev/null)"
  [[ -z "$count" ]] && count=0
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg id "$id" \
    --argjson matches "$matches" \
    --argjson c "$count" \
    '{schema_version:$sv,command:"why",id:$id,status:(if $c>0 then "pass" else "miss" end),match_count:$c,matches:$matches}'
  return 0
}

# ---------- doctrine probe primitives ----------

# _cpgp_reflog_window REPO WINDOW_SEC
# Scan reflog for HEAD movements within WINDOW_SEC of each other on the same ref.
# Emits a JSON array of violations: [{ref, delta_sec, old_sha, new_sha}].
_cpgp_reflog_window() {
  local repo="$1" window="$2"
  local raw
  raw="$(git -C "$repo" reflog --all --date=unix --format='%gD %gd %H %P %ct' 2>/dev/null || true)"
  if [[ -z "$raw" ]]; then
    printf '[]\n'
    return 0
  fi
  printf '%s\n' "$raw" | awk -v window="$window" '
    {
      # %gD = ref, %H = sha, %ct = unix time
      ref = $1
      gsub(/@\{[0-9]+\}/, "", ref)
      sha = $3
      ts = $NF
      key = ref
      if (key in last_ts) {
        delta = last_ts[key] - ts
        if (delta < 0) delta = -delta
        if (delta <= window) {
          # Report the pair
          printf "%s\t%d\t%s\t%s\n", key, delta, last_sha[key], sha
        }
      }
      last_ts[key] = ts
      last_sha[key] = sha
    }
  ' | jq -R 'split("\t") | {ref:.[0],delta_sec:(.[1]|tonumber),old_sha:.[2],new_sha:.[3]}' | jq -cs '.'
}

# ---------- scaffolded main dispatcher ----------

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    cpgp_run "$@"
    exit $?
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
    --json)       shift; cpgp_run --json "$@"; exit $? ;;
    *)
      printf 'ERR: unknown subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# ---------- run mode (default: all 3 probes composite) ----------

cpgp_run() {
  local json_out=0
  for arg in "$@"; do
    [[ "$arg" == "--json" ]] && json_out=1
  done

  local repo="$SCAFFOLD_TARGET_REPO"

  # Probe 1: active worktree census
  local paths_json count census_verdict
  paths_json="$(git -C "$repo" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree / {print $2}' | jq -R . | jq -cs '.')"
  count="$(printf '%s' "$paths_json" | jq 'length')"
  [[ -z "$count" ]] && count=0
  if [[ "$count" -ge "$SCAFFOLD_BEADCLASS_THRESHOLD" ]]; then census_verdict="bead-class"
  elif [[ "$count" -ge "$SCAFFOLD_NOTABLE_THRESHOLD" ]]; then census_verdict="notable"
  else census_verdict="ok"
  fi

  # Probe 2: stale worktree garbage
  local stale_dry stale_count
  stale_dry="$(git -C "$repo" worktree prune --dry-run 2>&1 || true)"
  stale_count="$(printf '%s\n' "$stale_dry" | grep -c '^Removing ' || true)"
  [[ -z "$stale_count" ]] && stale_count=0
  local stale_verdict; stale_verdict=$([[ "$stale_count" -gt 0 ]] && echo "stale-detected" || echo "ok")

  # Probe 3: concurrent commit window
  local violations_json viol_count window_verdict
  violations_json="$(_cpgp_reflog_window "$repo" "$SCAFFOLD_RACE_WINDOW_SEC")"
  viol_count="$(printf '%s' "$violations_json" | jq 'length')"
  [[ -z "$viol_count" ]] && viol_count=0
  window_verdict=$([[ "$viol_count" -gt 0 ]] && echo "race-candidate" || echo "ok")

  # Composite status: warn if any probe non-ok; fail reserved for substrate failure
  local status="pass"
  if [[ "$census_verdict" != "ok" || "$stale_verdict" != "ok" || "$window_verdict" != "ok" ]]; then
    status="warn"
  fi

  local PAYLOAD
  PAYLOAD="$(jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg repo "$repo" \
    --arg status "$status" \
    --argjson count "$count" \
    --arg census_verdict "$census_verdict" \
    --argjson paths "$paths_json" \
    --argjson notable "$SCAFFOLD_NOTABLE_THRESHOLD" \
    --argjson bead "$SCAFFOLD_BEADCLASS_THRESHOLD" \
    --argjson stale_count "$stale_count" \
    --arg stale_verdict "$stale_verdict" \
    --argjson window "$SCAFFOLD_RACE_WINDOW_SEC" \
    --argjson viol_count "$viol_count" \
    --argjson violations "$violations_json" \
    --arg window_verdict "$window_verdict" \
    '{
      schema_version:$sv, command:"run", ts:$ts, repo:$repo, status:$status,
      worktree_census:{count:$count, paths:$paths, notable_threshold:$notable, beadclass_threshold:$bead, verdict:$census_verdict},
      stale_worktree:{count:$stale_count, verdict:$stale_verdict},
      concurrent_commit_window:{window_sec:$window, violation_count:$viol_count, violations:$violations, verdict:$window_verdict}
    }')"

  if [[ "$json_out" -eq 1 ]]; then
    printf '%s\n' "$PAYLOAD"
  else
    jq -r '"cross-pane-git-probe status=\(.status) worktrees=\(.worktree_census.count)(\(.worktree_census.verdict)) stale=\(.stale_worktree.count) race=\(.concurrent_commit_window.violation_count)"' <<<"$PAYLOAD"
  fi

  # Append to audit log
  if command -v cli_audit_append >/dev/null 2>&1; then
    cli_audit_append "$SCAFFOLD_AUDIT_LOG" "probe" "$status" \
      "$(jq -nc --arg r "$repo" --argjson c "$count" --argjson sc "$stale_count" --argjson vc "$viol_count" \
         --arg cv "$census_verdict" --arg sv2 "$stale_verdict" --arg wv "$window_verdict" \
         '{repo:$r,worktree_count:$c,stale_count:$sc,window_violations:$vc,verdict:($cv+","+$sv2+","+$wv)}')" 2>/dev/null || true
  fi

  if [[ "$status" == "fail" ]]; then return 1; fi
  return 0
}

scaffold_main "$@"
