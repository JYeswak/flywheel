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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="storage-pressure-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/storage-pressure-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: storage-pressure-doctor.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "storage-pressure-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "storage-pressure-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"storage-pressure-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"storage-pressure-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"storage-pressure-doctor.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
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
            && cli_emit_completion_bash "storage-pressure-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "storage-pressure-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\n'
  #   fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
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
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
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
VERSION="storage-pressure-doctor.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
STORAGE_PROBE="$ROOT/.flywheel/scripts/storage-probe.sh"
TMP_PRUNE_LEDGER="${FLYWHEEL_TMP_PRUNE_LEDGER:-$HOME/.local/state/flywheel/tmp-aggressive-prune-cron.jsonl}"
JSON_OUT=0
MODE="doctor"
STORAGE_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE:-}"
TOP_CONSUMERS_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE:-}"
SNAPSHOT_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_SNAPSHOT_FIXTURE:-}"
TMP_LEDGER_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_TMP_LEDGER_FIXTURE:-}"
PRIVATE_TMP_GIB_FIXTURE="${FLYWHEEL_STORAGE_PRESSURE_PRIVATE_TMP_GIB_FIXTURE:-}"
AVAIL_WARN_GB="${FLYWHEEL_STORAGE_PRESSURE_AVAIL_WARN_GB:-20}"

usage() {
  printf '%s\n' \
    "Usage:" \
    "  storage-pressure-doctor.sh --doctor --json" \
    "  storage-pressure-doctor.sh --schema|--info|--examples|--help" \
    "" \
    "Read-only doctor. Aggregates storage-probe, top consumers, APFS snapshot" \
    "signals, and tmp prune ledger state. Recommends action when free space <20Gi."
}

examples() {
  printf '%s\n' \
    ".flywheel/scripts/storage-pressure-doctor.sh --doctor --json" \
    "FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE=tests/fixtures/storage-pressure/low-storage.json \\" \
    "  FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE=tests/fixtures/storage-pressure/top-consumers.txt \\" \
    "  .flywheel/scripts/storage-pressure-doctor.sh --doctor --json"
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"storage-pressure-doctor/v1",
    type:"object",
    required:["schema_version","status","storage","top_consumers","snapshots","private_tmp","recommendations"],
    properties:{
      schema_version:{const:"storage-pressure-doctor/v1"},
      status:{enum:["ok","warn","fail"]},
      storage:{type:"object"},
      top_consumers:{type:"array"},
      snapshots:{type:"object"},
      private_tmp:{type:"object"},
      recommendations:{type:"array"}
    }
  }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

human_to_gib() {
  awk -v raw="$1" '
    BEGIN {
      n = raw
      unit = substr(n, length(n), 1)
      sub(/[KMGTP]$/, "", n)
      val = n + 0
      if (unit == "T") val *= 1024
      else if (unit == "G") val *= 1
      else if (unit == "M") val /= 1024
      else if (unit == "K") val /= 1024 / 1024
      else if (unit == "P") val *= 1024 * 1024
      printf "%.2f", val
    }'
}

storage_json() {
  if [ -n "$STORAGE_FIXTURE" ]; then
    jq -c '.' "$STORAGE_FIXTURE"
    return 0
  fi
  "$STORAGE_PROBE" --json 2>/dev/null || true
}

top_consumers_json() {
  local source line size path gib count=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-top.XXXXXX")"
  if [ -n "$TOP_CONSUMERS_FIXTURE" ]; then
    cp "$TOP_CONSUMERS_FIXTURE" "$tmp"
  else
    du -sh "$HOME"/Developer/* "$HOME"/.socraticode/* "$HOME"/.knowledge/* "$HOME"/Library/Caches/* /private/tmp/* /private/var/folders/* 2>/dev/null \
      | sort -rh \
      | head -30 >"$tmp" || true
  fi
  {
    printf '['
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      size="$(awk '{print $1}' <<<"$line")"
      path="$(awk '{print $2}' <<<"$line")"
      gib="$(human_to_gib "$size")"
      [ "$count" -eq 0 ] || printf ','
      jq -nc --arg size "$size" --arg path "$path" --argjson gib "$gib" '{size:$size,size_gib:$gib,path:$path}'
      count=$((count + 1))
    done <"$tmp"
    printf ']'
  } | jq -c '.'
  rm -f "$tmp"
}

snapshot_json() {
  if [ -n "$SNAPSHOT_FIXTURE" ]; then
    jq -c '.' "$SNAPSHOT_FIXTURE"
    return 0
  fi
  local tm_file disk_file tm_count disk_count sealed_count
  tm_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-tm.XXXXXX")"
  disk_file="$(mktemp "${TMPDIR:-/tmp}/storage-pressure-diskutil.XXXXXX")"
  tmutil listlocalsnapshots / >"$tm_file" 2>/dev/null || true
  diskutil apfs list >"$disk_file" 2>/dev/null || true
  tm_count="$(grep -c '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null || true)"
  disk_count="$(grep -c 'Snapshot:' "$disk_file" 2>/dev/null || true)"
  sealed_count="$(grep -c 'Snapshot Sealed:[[:space:]]*Yes' "$disk_file" 2>/dev/null || true)"
  jq -nc \
    --argjson tm_count "${tm_count:-0}" \
    --argjson disk_count "${disk_count:-0}" \
    --argjson sealed_count "${sealed_count:-0}" \
    --argjson tm_snapshots "$(grep '^com\\.apple\\.TimeMachine\\.' "$tm_file" 2>/dev/null | jq -R . | jq -s .)" \
    '{
      tm_local_snapshot_count:$tm_count,
      apfs_snapshot_count:$disk_count,
      sealed_system_snapshot_count:$sealed_count,
      tm_local_snapshots:$tm_snapshots,
      evidence:"tmutil listlocalsnapshots /; diskutil apfs list"
    }'
  rm -f "$tm_file" "$disk_file"
}

private_tmp_json() {
  local ledger="$TMP_PRUNE_LEDGER" last="null" ledger_exists=false entry_count=0 total_gib=0 kb=0
  if [ -n "$TMP_LEDGER_FIXTURE" ]; then
    ledger="$TMP_LEDGER_FIXTURE"
  fi
  if [ -s "$ledger" ]; then
    ledger_exists=true
    last="$(tail -n 1 "$ledger" | jq -c '.' 2>/dev/null || printf 'null')"
  fi
  entry_count="$(find /private/tmp -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
  if [ -n "$PRIVATE_TMP_GIB_FIXTURE" ]; then
    total_gib="$PRIVATE_TMP_GIB_FIXTURE"
  else
    kb="$(du -sk /private/tmp 2>/dev/null | awk '{print $1+0}' || printf 0)"
    total_gib="$(awk -v kb="${kb:-0}" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')"
  fi
  jq -nc \
    --arg ledger "$ledger" \
    --argjson exists "$ledger_exists" \
    --argjson last "$last" \
    --argjson total_gib "$total_gib" \
    --argjson entry_count "${entry_count:-0}" \
    '{ledger_path:$ledger,ledger_exists:$exists,last_run:$last,private_tmp_total_gib:$total_gib,private_tmp_entry_count:$entry_count}'
}

recommendations_json() {
  local storage="$1" consumers="$2" snapshots="$3" tmp_json="$4"
  jq -nc \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp "$tmp_json" \
    --argjson warn_gb "$AVAIL_WARN_GB" \
    '
      ($storage.disk_free_gb // 999999) as $free_gb
      | ($storage.disk_free_pct // 100) as $free_pct
      | [
          (if $free_gb < $warn_gb or $free_pct < 5 then {
            code:"storage_pressure_active",
            severity:(if $free_pct < 5 then "fire" elif $free_gb < $warn_gb then "critical" else "warn" end),
            action:"Pause growth-heavy clone/index jobs; run storage-health L1 and re-probe before L2+."
          } else empty end),
          (if ($snapshots.tm_local_snapshot_count // 0) > 0 and ($free_gb < $warn_gb) then {
            code:"tm_snapshots_present_under_pressure",
            severity:"warn",
            action:"Use apfs-snapshot-ops to inspect/thin Time Machine local snapshots; do not delete sealed system snapshots."
          } else empty end),
          (if (($tmp.ledger_exists // false) | not) then {
            code:"tmp_prune_ledger_missing",
            severity:"warn",
            action:"Verify ai.zeststream.tmp-aggressive-prune launchd wiring; ledger is missing."
          } else empty end),
          (if (($tmp.private_tmp_total_gib // 0) > 50) then {
            code:"private_tmp_large",
            severity:(if $free_gb < $warn_gb or $free_pct < 5 then "critical" else "warn" end),
            action:"/private/tmp is large even after the cron wrapper; inspect protected/recent tmp roots before widening prune age or patterns."
          } else empty end),
          (if ($consumers | length) > 0 then {
            code:"top_consumer_review",
            severity:"info",
            action:("Largest visible consumer: " + ($consumers[0].path // "unknown") + " (" + (($consumers[0].size // "unknown")|tostring) + ").")
          } else empty end)
        ]'
}

doctor_json() {
  local storage consumers snapshots tmp_json recs status
  storage="$(storage_json)"
  consumers="$(top_consumers_json)"
  snapshots="$(snapshot_json)"
  tmp_json="$(private_tmp_json)"
  recs="$(recommendations_json "$storage" "$consumers" "$snapshots" "$tmp_json")"
  status="$(jq -nr --argjson storage "$storage" --argjson recs "$recs" '
    if ($storage.status // "ok") == "fail" then "fail"
    elif any($recs[]?; .severity == "critical" or .severity == "fire") then "fail"
    elif (($recs | length) > 0 or ($storage.status // "ok") == "warn") then "warn"
    else "ok" end')"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg status "$status" \
    --argjson storage "$storage" \
    --argjson consumers "$consumers" \
    --argjson snapshots "$snapshots" \
    --argjson tmp_json "$tmp_json" \
    --argjson recs "$recs" \
    '{
      schema_version:"storage-pressure-doctor/v1",
      version:"storage-pressure-doctor.v1",
      ts:$ts,
      status:$status,
      storage:$storage,
      top_consumers:$consumers,
      snapshots:$snapshots,
      private_tmp:$tmp_json,
      recommendations:$recs
    }'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --doctor|doctor) MODE="doctor"; shift ;;
      --json) JSON_OUT=1; shift ;;
      --schema) schema_json; exit 0 ;;
      --info) jq -nc --arg version "$VERSION" --arg probe "$STORAGE_PROBE" '{version:$version,storage_probe:$probe,mutates:[]}'; exit 0 ;;
      --examples) examples; exit 0 ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

main() {
  local out
  parse_args "$@"
  case "$MODE" in
    doctor) out="$(doctor_json)" ;;
    *) printf 'ERROR: unknown mode: %s\n' "$MODE" >&2; exit 2 ;;
  esac
  if [ "$JSON_OUT" -eq 1 ]; then
    printf '%s\n' "$out"
  else
    jq -r '"storage_pressure status=\(.status) free_gb=\(.storage.disk_free_gb // "unknown") recommendations=\(.recommendations | length)"' <<<"$out"
  fi
  [ "$(jq -r '.status' <<<"$out")" != "fail" ]
}

main "$@"
