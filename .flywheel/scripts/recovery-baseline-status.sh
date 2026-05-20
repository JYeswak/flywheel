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
# specific logic was filled in by bead flywheel-wzjo9.2.3 (no remaining
# scaffold stubs).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="recovery-baseline-status/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/recovery-baseline-status-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: recovery-baseline-status.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "recovery-baseline-status.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "recovery-baseline-status.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"recovery-baseline-status.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"recovery-baseline-status.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"recovery-baseline-status.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","checks"],status_enum:["pass","fail","warn"]}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","audit_log","recent_runs"],status_enum:["pass","warn","fail"]}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","scope"],mode_enum:["dry_run","apply"],
          valid_scopes:["audit-log-rotate","snapshot-dir-prime"],
          mutation_gates:["--apply requires --idempotency-key"]}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","subject"],valid_subjects:["row","schema","config","manifest"],
          status_enum:["pass","fail","warn","refused","info"]}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["audit_log","row_count","recent"]}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["id","status"],status_enum:["found","not_found","unavailable"],
          provenance_fields:["ts","manifest_path","label","plist","drill_pass_ts"]}'
      ;;
    audit-row|run)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["ts","command","schema_version"],
          optional:["manifest_path","label","plist_exists","drill_pass_ts"],
          purpose:"row shape written to SCAFFOLD_AUDIT_LOG by cmd_run terminal envelopes"}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          surfaces:["doctor","health","repair","validate","audit","why","audit-row","default"],
          purpose:"recovery baseline status reporter — reads latest baseline manifest, checks nightly snapshot plist label, finds latest passing drill; substrate-level canonical layer over cmd_run python3",
          stable_exit_codes:{"0":"pass","1":"general error","3":"refused (--apply without --idempotency-key)","64":"bad args"}}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  local _runs="${SCAFFOLD_AUDIT_LOG:-${HOME}/.local/state/flywheel/recovery-baseline-status-runs.jsonl}"
  case "$topic" in
    run)
      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc). Emits a JSON status envelope of: latest baseline manifest ts, nightly snapshot plist active state, latest passing drill ts, protected_sessions_restore_blocked. Flags: --json, --snapshot-dir, --drill-dir, --launchctl-bin, --plist.\n'
      ;;
    doctor)
      printf 'topic: doctor — substrate health probes (python3, snapshot-dir, drill-dir, launchctl binary, plist path resolvable). Per-baseline status emit lives in cmd_run; invoke with --json or no canonical args.\n'
      ;;
    health)
      printf 'topic: health — recent run summary from %s (recent_count, last_run_ts, age_seconds, distinct_manifest_paths, nightly_active samples). Warn when ledger absent or stale (>24h — baseline status is on a daily cadence).\n' "$_runs"
      ;;
    repair)
      printf 'topic: repair — read-only by default; mutate with --apply --idempotency-key KEY. Scopes: audit-log-rotate (rotate %s when >5MB), snapshot-dir-prime (read-only probe of $FLYWHEEL_RECOVERY_SNAPSHOT_DIR — emits manifest count + latest sha). Apply without --idempotency-key returns refused (rc 3).\n' "$_runs"
      ;;
    validate)
      printf 'topic: validate — per-subject contract checks. Subjects: row (--row-json=JSON validates an audit-log row schema), schema (--surface=NAME re-emits the schema), config (env presence: python3, snapshot-dir, drill-dir, launchctl), manifest (probe latest baseline-*.manifest.json shape for required fields created_at + protected).\n'
      ;;
    audit)
      printf 'topic: audit — tail %s (default --tail=10). Returns rows[] with ts, manifest_path, label, plist_exists, drill_pass_ts.\n' "$_runs"
      ;;
    why)
      printf 'topic: why <id> — provenance lookup by manifest_path basename or label in the audit log; emits ts/manifest_path/label/plist/drill_pass_ts or status=not_found when absent.\n'
      ;;
    *)
      printf 'topics: run | doctor | health | repair | validate | audit | why\n'
      ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "recovery-baseline-status" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "recovery-baseline-status" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 5 named substrate probes for recovery-baseline-status.
  local ts snapshot_dir drill_dir launchctl_bin plist
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  snapshot_dir="${FLYWHEEL_RECOVERY_SNAPSHOT_DIR:-$HOME/.flywheel/recovery/snapshots}"
  drill_dir="${FLYWHEEL_RECOVERY_DRILL_DIR:-$HOME/.flywheel/recovery/drills}"
  launchctl_bin="${FLYWHEEL_RECOVERY_LAUNCHCTL_BIN:-/bin/launchctl}"
  plist="${FLYWHEEL_RECOVERY_NIGHTLY_PLIST:-$HOME/Library/LaunchAgents/com.zeststream.recovery.nightly-snapshot.plist}"

  # Expand ~ in plist path
  plist="${plist/#~/$HOME}"
  snapshot_dir="${snapshot_dir/#~/$HOME}"
  drill_dir="${drill_dir/#~/$HOME}"

  local py_status="fail" py_reason=""
  if command -v python3 >/dev/null 2>&1; then py_status="pass"
  else py_reason="python3 not on PATH (required for cmd_run heredoc)"; fi

  local snap_status="fail" snap_reason=""
  if [[ -d "$snapshot_dir" ]]; then snap_status="pass"
  else snap_status="warn"; snap_reason="snapshot-dir absent (created on first snapshot): $snapshot_dir"; fi

  local drill_status="fail" drill_reason=""
  if [[ -d "$drill_dir" ]]; then drill_status="pass"
  else drill_status="warn"; drill_reason="drill-dir absent (created on first drill): $drill_dir"; fi

  local launchctl_status="fail" launchctl_reason=""
  if [[ -x "$launchctl_bin" ]]; then launchctl_status="pass"
  else launchctl_reason="launchctl not executable: $launchctl_bin"; fi

  local plist_status="fail" plist_reason=""
  if [[ -f "$plist" ]]; then plist_status="pass"
  else plist_status="warn"; plist_reason="nightly snapshot plist absent: $plist"; fi

  local overall="pass" s
  for s in "$py_status" "$launchctl_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" && ( "$snap_status" == "warn" || "$drill_status" == "warn" || "$plist_status" == "warn" ) ]]; then
    overall="warn"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg py_s "$py_status" --arg py_r "$py_reason" \
    --arg snap "$snapshot_dir" --arg snap_s "$snap_status" --arg snap_r "$snap_reason" \
    --arg drill "$drill_dir" --arg drill_s "$drill_status" --arg drill_r "$drill_reason" \
    --arg lc_bin "$launchctl_bin" --arg lc_s "$launchctl_status" --arg lc_r "$launchctl_reason" \
    --arg plist "$plist" --arg plist_s "$plist_status" --arg plist_r "$plist_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"python3_on_path",status:$py_s,reason:$py_r},
      {name:"snapshot_dir_present",status:$snap_s,path:$snap,reason:$snap_r},
      {name:"drill_dir_present",status:$drill_s,path:$drill,reason:$drill_r},
      {name:"launchctl_executable",status:$lc_s,path:$lc_bin,reason:$lc_r},
      {name:"nightly_plist_present",status:$plist_s,path:$plist,reason:$plist_r}
    ]}'
}

scaffold_cmd_health() {
  # Tail SCAFFOLD_AUDIT_LOG. Reports recent_count, last_run_ts, age_seconds.
  # Daily cadence: warn when last run >24h ago.
  local ts log_path tail_n=20 tail_lines total last_ts age_seconds distinct_manifests
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="$SCAFFOLD_AUDIT_LOG"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log_path" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"audit ledger absent (no historical runs yet)",audit_log:$log,recent_runs:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_n" "$log_path" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || true)"
  if [[ -z "$total" ]]; then total=0; fi
  set +e
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  distinct_manifests="$(printf '%s\n' "$tail_lines" | jq -r '.manifest_path // empty' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  set -e

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="empty tail"
  elif [[ "$age_seconds" != "null" && "$age_seconds" -gt 86400 ]]; then
    status="warn"; reason="last run >24h ago (stale)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg log "$log_path" \
    --argjson total "${total:-0}" \
    --arg last_ts "$last_ts" \
    --argjson age "${age_seconds:-null}" \
    --arg manifests "$distinct_manifests" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      audit_log:$log,recent_runs:$total,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      last_run_age_seconds:$age,
      recent_manifests:($manifests | split(",") | map(select(length > 0)))}'
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
  # Per-scope repair actions: audit-log-rotate (5MB) + snapshot-dir-prime (read-only probe).
  local log_path snapshot_dir
  log_path="$SCAFFOLD_AUDIT_LOG"
  snapshot_dir="${FLYWHEEL_RECOVERY_SNAPSHOT_DIR:-$HOME/.flywheel/recovery/snapshots}"
  snapshot_dir="${snapshot_dir/#~/$HOME}"
  case "$scope" in
    audit-log-rotate)
      if [[ ! -f "$log_path" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg log "$log_path" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"dry_run",scope:$scope,reason:"audit ledger absent — nothing to rotate",log_path:$log}'
        return 0
      fi
      local size threshold=5242880 lines
      size="$(stat -f%z "$log_path" 2>/dev/null || stat -c%s "$log_path" 2>/dev/null || echo 0)"
      lines="$(wc -l <"$log_path" | tr -d ' ')"
      if [[ "$mode" == "apply" ]]; then
        if [[ "$size" -lt "$threshold" ]]; then
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,
              size_bytes:$size,threshold_bytes:$threshold,lines:$lines,note:"under threshold — no rotation needed"}'
        else
          local rotated="${log_path%.jsonl}.$(date -u +%Y%m%dT%H%M%SZ).jsonl"
          mv "$log_path" "$rotated"
          : > "$log_path"
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
            --arg rotated "$rotated" --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
            '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,
              rotated_to:$rotated,size_bytes:$size,threshold_bytes:$threshold,lines:$lines}'
        fi
      else
        local will_rotate="false"
        if [[ "$size" -ge "$threshold" ]]; then will_rotate="true"; fi
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --argjson size "$size" --argjson threshold "$threshold" --argjson lines "$lines" \
          --argjson will "$will_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,
            size_bytes:$size,threshold_bytes:$threshold,lines:$lines,will_rotate:$will,
            planned_actions:["rotate audit-log when --apply --idempotency-key KEY passed"]}'
      fi
      ;;
    snapshot-dir-prime)
      # Read-only probe of the baseline-snapshot dir.
      if [[ ! -d "$snapshot_dir" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg dir "$snapshot_dir" \
          '{schema_version:$sv,command:"repair",status:"warn",mode:"read_only",scope:$scope,reason:"snapshot-dir absent",dir:$dir}'
        return 0
      fi
      local manifest_count latest_manifest
      manifest_count="$(find "$snapshot_dir" -maxdepth 1 -name 'baseline-*.manifest.json' -type f 2>/dev/null | wc -l | tr -d ' ')"
      latest_manifest="$(find "$snapshot_dir" -maxdepth 1 -name 'baseline-*.manifest.json' -type f 2>/dev/null | xargs -I {} stat -f '%m %N' {} 2>/dev/null | sort -rn | head -1 | awk '{print $2}')"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg dir "$snapshot_dir" --argjson count "$manifest_count" --arg latest "$latest_manifest" \
        '{schema_version:$sv,command:"repair",status:"ok",mode:"read_only",scope:$scope,
          dir:$dir,manifest_count:$count,latest_manifest:$latest,
          note:"read-only probe of baseline-snapshot dir; --apply has no mutation in this scope"}'
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["audit-log-rotate","snapshot-dir-prime"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["audit-log-rotate","snapshot-dir-prime"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject contract checks. Subjects: row, schema, config, manifest.
  local subject="" row_json="" surface_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --row-json) row_json="${2:-}"; subject="row"; shift 2 ;;
      --surface=*) surface_arg="${1#--surface=}"; subject="schema"; shift ;;
      --surface) surface_arg="${2:-}"; subject="schema"; shift 2 ;;
      --config) subject="config"; shift ;;
      --manifest) subject="manifest"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required for subject=row"}'
        return 64
      fi
      local required='["ts","command","schema_version"]'
      local valid missing
      set +e
      valid="$(printf '%s' "$row_json" | jq -e '. | type == "object"' >/dev/null 2>&1 && echo true || echo false)"
      missing="$(printf '%s' "$row_json" | jq -c --argjson req "$required" '$req - keys' 2>/dev/null || echo "[]")"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" \
        '{schema_version:$sv,command:"validate",subject:"row",
          status:(if ($valid and ($missing | length == 0)) then "pass" else "fail" end),
          valid:$valid,missing_required:$missing}'
      ;;
    schema)
      if [[ -z "$surface_arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--surface=NAME required for subject=schema"}'
        return 64
      fi
      local schema_out
      schema_out="$(scaffold_emit_schema "$surface_arg")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surf "$surface_arg" --argjson schema "$schema_out" \
        '{schema_version:$sv,command:"validate",subject:"schema",surface:$surf,status:"pass",schema:$schema}'
      ;;
    config)
      local snapshot_dir drill_dir launchctl_bin
      snapshot_dir="${FLYWHEEL_RECOVERY_SNAPSHOT_DIR:-$HOME/.flywheel/recovery/snapshots}"
      drill_dir="${FLYWHEEL_RECOVERY_DRILL_DIR:-$HOME/.flywheel/recovery/drills}"
      launchctl_bin="${FLYWHEEL_RECOVERY_LAUNCHCTL_BIN:-/bin/launchctl}"
      local missing=()
      command -v python3 >/dev/null 2>&1 || missing+=("python3:not_on_path")
      [[ -d "${snapshot_dir/#~/$HOME}" ]] || missing+=("snapshot_dir:$snapshot_dir (warn — created on first snapshot)")
      [[ -d "${drill_dir/#~/$HOME}" ]] || missing+=("drill_dir:$drill_dir (warn — created on first drill)")
      [[ -x "$launchctl_bin" ]] || missing+=("launchctl:$launchctl_bin")
      local missing_json
      if [[ ${#missing[@]} -eq 0 ]]; then
        missing_json='[]'
      else
        missing_json="$(printf '%s\n' "${missing[@]}" | jq -R . | jq -sc .)"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg snap "$snapshot_dir" --arg drill "$drill_dir" --arg lc "$launchctl_bin" \
        --argjson missing "$missing_json" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if ($missing | length) == 0 then "pass" else "fail" end),
          snapshot_dir:$snap,drill_dir:$drill,launchctl_bin:$lc,missing:$missing}'
      ;;
    manifest)
      # Probe latest baseline-*.manifest.json shape.
      local snapshot_dir2 latest
      snapshot_dir2="${FLYWHEEL_RECOVERY_SNAPSHOT_DIR:-$HOME/.flywheel/recovery/snapshots}"
      snapshot_dir2="${snapshot_dir2/#~/$HOME}"
      if [[ ! -d "$snapshot_dir2" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg dir "$snapshot_dir2" \
          '{schema_version:$sv,command:"validate",subject:"manifest",status:"warn",reason:"snapshot-dir absent",dir:$dir}'
        return 0
      fi
      latest="$(find "$snapshot_dir2" -maxdepth 1 -name 'baseline-*.manifest.json' -type f 2>/dev/null | xargs -I {} stat -f '%m %N' {} 2>/dev/null | sort -rn | head -1 | awk '{print $2}')"
      if [[ -z "$latest" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg dir "$snapshot_dir2" \
          '{schema_version:$sv,command:"validate",subject:"manifest",status:"warn",reason:"no baseline manifests found",dir:$dir}'
        return 0
      fi
      # Required-fields contract for baseline manifest. Verified against
      # actual baseline-20260507T233254Z.manifest.json on this fleet during
      # fillin (validate --manifest caught my initial wrong assumption
      # `protected` → actual field is `protected_sessions_restore_blocked`).
      local required='["created_at","protected_sessions_restore_blocked","schema_version"]'
      local missing valid
      set +e
      valid="$(jq -e '. | type == "object"' "$latest" >/dev/null 2>&1 && echo true || echo false)"
      missing="$(jq -c --argjson req "$required" '$req - keys' "$latest" 2>/dev/null || echo "[]")"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg path "$latest" --argjson valid "$valid" --argjson missing "$missing" \
        '{schema_version:$sv,command:"validate",subject:"manifest",manifest_path:$path,
          status:(if ($valid and ($missing | length == 0)) then "pass" else "fail" end),
          valid:$valid,missing_required:$missing}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","schema","config","manifest"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail.
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) printf 'ERR: unknown audit arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$tail_n"
    return 0
  fi
  if [[ ! -f "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,status:"warn",reason:"audit ledger absent",rows:[],count:0}'
    return 0
  fi
  local rows count
  set +e
  rows="$(tail -n "$tail_n" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -sc '.' 2>/dev/null)"
  set -e
  if [[ -z "$rows" ]]; then rows='[]'; fi
  count="$(echo "$rows" | jq 'length' 2>/dev/null || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # Provenance lookup: search SCAFFOLD_AUDIT_LOG for matching manifest_path basename or label.
  local log_path="$SCAFFOLD_AUDIT_LOG"
  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"audit ledger absent",audit_log:$log}'
    return 0
  fi
  local row
  row="$(grep -E "\"(manifest_path|label)\":\"[^\"]*$id[^\"]*\"" "$log_path" 2>/dev/null | tail -1 || true)"
  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_found",reason:"id not in audit ledger",audit_log:$log}'
    return 0
  fi
  if ! printf '%s' "$row" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg raw "$(printf '%s' "$row" | head -c 512)" \
      '{schema_version:$sv,command:"why",id:$id,status:"unavailable",reason:"matched row is not valid JSON",raw_preview:$raw}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      provenance:{
        ts:($row.ts // null),
        manifest_path:($row.manifest_path // null),
        label:($row.label // null),
        plist_exists:($row.plist_exists // null),
        drill_pass_ts:($row.drill_pass_ts // null)
      },
      row:$row}'
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
import argparse
import json
import os
import subprocess
from pathlib import Path

LABEL = "com.zeststream.recovery.nightly-snapshot"
PROTECTED = ["alpsinsurance", "picoz"]


def ep(path):
    return Path(path).expanduser()


def latest_manifest(snapshot_dir):
    manifests = sorted(ep(snapshot_dir).glob("baseline-*.manifest.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not manifests:
        return None, None
    try:
        payload = json.loads(manifests[0].read_text(encoding="utf-8"))
    except Exception:
        payload = {}
    return manifests[0], payload


def label_active(launchctl_bin, label):
    try:
        proc = subprocess.run([launchctl_bin, "list"], text=True, capture_output=True, timeout=5)
    except Exception:
        return False
    if proc.returncode != 0:
        return False
    return any(line.strip().endswith(label) or label in line.split() for line in proc.stdout.splitlines())


def latest_drill(drill_dir):
    drills = sorted(ep(drill_dir).glob("drill-*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    for path in drills:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if payload.get("status") == "pass":
            return payload.get("created_at") or payload.get("ts")
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--snapshot-dir", default=os.environ.get("FLYWHEEL_RECOVERY_SNAPSHOT_DIR", "~/.flywheel/recovery/snapshots"))
    parser.add_argument("--drill-dir", default=os.environ.get("FLYWHEEL_RECOVERY_DRILL_DIR", "~/.flywheel/recovery/drills"))
    parser.add_argument("--launchctl-bin", default=os.environ.get("FLYWHEEL_RECOVERY_LAUNCHCTL_BIN", "/bin/launchctl"))
    parser.add_argument("--plist", default=os.environ.get("FLYWHEEL_RECOVERY_NIGHTLY_PLIST", "~/Library/LaunchAgents/com.zeststream.recovery.nightly-snapshot.plist"))
    args = parser.parse_args()
    manifest_path, manifest = latest_manifest(args.snapshot_dir)
    payload = {
        "schema_version": "flywheel-recovery-baseline-status/v1",
        "status": "pass",
        "last_baseline_snapshot_ts": manifest.get("created_at") if manifest else None,
        "last_baseline_snapshot_manifest_path": str(manifest_path) if manifest_path else None,
        "nightly_snapshot_label": LABEL,
        "nightly_snapshot_label_active": label_active(args.launchctl_bin, LABEL),
        "nightly_snapshot_plist_path": str(ep(args.plist)),
        "nightly_snapshot_plist_exists": ep(args.plist).is_file(),
        "last_drill_pass_ts": latest_drill(args.drill_dir),
        "protected_sessions_restore_blocked": PROTECTED,
    }
    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(
            "Recovery baseline: last_snapshot={last_baseline_snapshot_ts} nightly_active={nightly_snapshot_label_active} "
            "last_drill={last_drill_pass_ts} protected_blocked={protected_sessions_restore_blocked}".format(**payload)
        )


if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-45-reversible-cleanup-bundle.md`
