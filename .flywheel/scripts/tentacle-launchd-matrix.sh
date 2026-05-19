#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VERSION="tentacle-launchd-matrix.v1"
COMMAND="audit"
JSON_OUT=0
DRY_RUN=0
REGISTRY="${TENTACLE_LAUNCHD_REGISTRY:-$ROOT/.flywheel/launchd/tentacle-daemon-registry.json}"
LAUNCHCTL="${TENTACLE_LAUNCHCTL:-/bin/launchctl}"
LAUNCHCTL_LIST_FILE="${TENTACLE_LAUNCHCTL_LIST_FILE:-}"

usage() {
  cat <<'EOF'
usage: tentacle-launchd-matrix.sh [audit|doctor|health|validate|matrix|repair|why|quickstart|help|completion] [--json]
       tentacle-launchd-matrix.sh [--registry FILE] [--launchctl-list FILE] [--schema|--info|--examples]

Reconciles the tentacle daemon launchd registry against launchctl list output.
Audit mode is read-only: it never unloads, reloads, bootouts, bootstraps, or
kickstarts services.

Options:
  --registry FILE       Registry JSON, default .flywheel/launchd/tentacle-daemon-registry.json
  --launchctl-list FILE Fixture or captured launchctl list output
  --json                Emit JSON
  --dry-run             Required for repair; repair is read-only
EOF
}

schema() {
  jq -nc '{
    schema_version:"tentacle-launchd-matrix.schema/v1",
    required:["schema_version","status","registry_path","total","rows","restart_matrix"],
    registry_row_required:["plist_label","expected_uptime_seconds","binary_path","restart_policy"],
    row_required:["plist_label","launchctl_present","status","reason"],
    exit_codes:{"0":"audit completed or validation passed","1":"validation failed","2":"usage error"}
  }'
}

info() {
  jq -nc --arg version "$VERSION" --arg registry "$REGISTRY" --arg launchctl "$LAUNCHCTL" \
    '{schema_version:"tentacle-launchd-matrix.info/v1",version:$version,registry:$registry,launchctl:$launchctl,mutation:"none"}'
}

examples() {
  jq -nc '{schema_version:"tentacle-launchd-matrix.examples/v1",examples:[
    ".flywheel/scripts/tentacle-launchd-matrix.sh --json",
    ".flywheel/scripts/tentacle-launchd-matrix.sh validate --json",
    ".flywheel/scripts/tentacle-launchd-matrix.sh matrix --json",
    ".flywheel/scripts/tentacle-launchd-matrix.sh --launchctl-list fixtures/launchctl-list.txt --json",
    ".flywheel/scripts/tentacle-launchd-matrix.sh repair --dry-run --json"
  ]}'
}

quickstart() {
  cat <<'EOF'
1. Edit .flywheel/launchd/tentacle-daemon-registry.json for expected daemon state.
2. Run .flywheel/scripts/tentacle-launchd-matrix.sh --json.
3. Inspect rows with status=warn.
4. Use matrix --json to see operator restart commands; audit mode does not run them.
EOF
}

topic_help() {
  local topic="${1:-overview}"
  case "$topic" in
    exit-codes)
      cat <<'EOF'
exit codes:
  0  audit completed or validation passed
  1  registry validation failed
  2  usage error
EOF
      ;;
    routing|overview)
      cat <<'EOF'
routing:
  expected_state=running + missing launchctl row  -> warn missing_launchd_label
  expected_state=running + uptime below threshold -> warn uptime_below_expected
  expected_state=disabled + loaded row            -> warn disabled_but_loaded
  audit mode never unloads/reloads services
EOF
      ;;
    *)
      printf 'unknown help topic: %s\n' "$topic" >&2
      return 2
      ;;
  esac
}

completion() {
  local shell="${1:-bash}"
  case "$shell" in
    bash|zsh)
      cat <<'EOF'
complete -W "audit doctor health validate matrix repair why quickstart help completion exit-codes routing --json --registry --launchctl-list --schema --info --examples --dry-run --help" tentacle-launchd-matrix.sh
EOF
      ;;
    *)
      printf 'completion unavailable for %s\n' "$shell" >&2
      return 2
      ;;
  esac
}

launchctl_list() {
  if [ -n "$LAUNCHCTL_LIST_FILE" ]; then
    cat "$LAUNCHCTL_LIST_FILE"
  else
    "$LAUNCHCTL" list 2>/dev/null || true
  fi
}

pid_uptime_seconds() {
  local pid="$1"
  case "$pid" in
    ''|'-'|*[!0-9]*) printf 'null\n' ;;
    *)
      ps -p "$pid" -o etime= 2>/dev/null | awk '
        NF {
          elapsed=$1
          days=0
          if (index(elapsed, "-") > 0) {
            split(elapsed, day_parts, "-")
            days=day_parts[1]
            elapsed=day_parts[2]
          }
          n=split(elapsed, parts, ":")
          if (n == 2) {
            print (days * 86400) + (parts[1] * 60) + parts[2]
          } else if (n == 3) {
            print (days * 86400) + (parts[1] * 3600) + (parts[2] * 60) + parts[3]
          } else {
            print "null"
          }
          found=1
        }
        END {if (!found) print "null"}
      '
      ;;
  esac
}

state_json() {
  local tmp
  tmp="$(mktemp -d -t tentacle-launchd.XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN
  launchctl_list >"$tmp/launchctl.txt"
  : >"$tmp/state.jsonl"
  awk 'NF >= 3 {print $1 "\t" $2 "\t" $3}' "$tmp/launchctl.txt" | while IFS=$'\t' read -r pid exit_status label; do
    uptime="$(pid_uptime_seconds "$pid")"
    jq -nc --arg label "$label" --arg pid "$pid" --arg exit_status "$exit_status" --argjson uptime "$uptime" \
      '{plist_label:$label,pid:$pid,launchctl_exit_status:$exit_status,process_uptime_seconds:$uptime}' >>"$tmp/state.jsonl"
  done
  jq -s '.' "$tmp/state.jsonl"
}

row_json() {
  local daemon="$1" state="$2" label expected plist binary uptime_threshold loaded_row loaded pid uptime plist_present binary_present status reason restart_action
  label="$(jq -r '.plist_label' <<<"$daemon")"
  expected="$(jq -r '.expected_state // "running"' <<<"$daemon")"
  plist="$(jq -r '.plist_path // ""' <<<"$daemon")"
  binary="$(jq -r '.binary_path // ""' <<<"$daemon")"
  uptime_threshold="$(jq -r '.expected_uptime_seconds // 0' <<<"$daemon")"
  loaded_row="$(jq -c --arg label "$label" 'map(select(.plist_label == $label)) | last // null' <<<"$state")"
  if [ "$loaded_row" = "null" ]; then
    loaded=false
    pid=""
    uptime=null
  else
    loaded=true
    pid="$(jq -r '.pid // ""' <<<"$loaded_row")"
    uptime="$(jq -r '.process_uptime_seconds // "null"' <<<"$loaded_row")"
  fi
  [ -n "$plist" ] && [ -e "$plist" ] && plist_present=true || plist_present=false
  [ -n "$binary" ] && [ -e "$binary" ] && binary_present=true || binary_present=false

  status=pass
  reason=ok
  if [ "$expected" = "disabled" ]; then
    if [ "$loaded" = true ]; then
      status=warn
      reason=disabled_but_loaded
    else
      reason=disabled_expected
    fi
  elif [ "$plist_present" = false ]; then
    status=warn
    reason=missing_plist
  elif [ "$binary_present" = false ]; then
    status=warn
    reason=missing_binary
  elif [ "$loaded" = false ]; then
    status=warn
    reason=missing_launchd_label
  elif [ -z "$pid" ] || [ "$pid" = "-" ]; then
    status=warn
    reason=loaded_without_pid
  elif [ "$uptime" != "null" ] && [ "$uptime_threshold" -gt 0 ] && [ "$uptime" -lt "$uptime_threshold" ]; then
    status=warn
    reason=uptime_below_expected
  fi

  if [ "$status" = "warn" ] && [ "$expected" != "disabled" ]; then
    restart_action="$(jq -r '.restart_command // empty' <<<"$daemon")"
  else
    restart_action=""
  fi

  jq -nc \
    --argjson daemon "$daemon" \
    --argjson launchctl_present "$loaded" \
    --arg pid "$pid" \
    --argjson uptime "$uptime" \
    --argjson plist_present "$plist_present" \
    --argjson binary_present "$binary_present" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg restart_action "$restart_action" \
    '$daemon + {
      launchctl_present:$launchctl_present,
      pid:(if $pid == "" then null else $pid end),
      process_uptime_seconds:$uptime,
      plist_present:$plist_present,
      binary_present:$binary_present,
      status:$status,
      reason:$reason,
      planned_restart_action:(if $restart_action == "" then null else $restart_action end)
    }'
}

audit_json() {
  local tmp state total warn pass
  tmp="$(mktemp -d -t tentacle-launchd-audit.XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN
  state="$(state_json)"
  jq -c '.daemons[]' "$REGISTRY" | while IFS= read -r daemon; do
    row_json "$daemon" "$state"
  done | jq -s '.' >"$tmp/rows.json"
  total="$(jq 'length' "$tmp/rows.json")"
  warn="$(jq '[.[] | select(.status == "warn")] | length' "$tmp/rows.json")"
  pass="$(jq '[.[] | select(.status == "pass")] | length' "$tmp/rows.json")"
  jq -nc \
    --arg registry "$REGISTRY" \
    --argjson total "$total" \
    --argjson pass "$pass" \
    --argjson warn "$warn" \
    --argjson rows "$(cat "$tmp/rows.json")" \
    '{
      schema_version:"tentacle-launchd-matrix/v1",
      status:(if $warn > 0 then "warn" else "pass" end),
      registry_path:$registry,
      total:$total,
      pass_count:$pass,
      warn_count:$warn,
      mutation_performed:false,
      rows:$rows,
      restart_matrix:($rows | map({
        name,
        plist_label,
        expected_state,
        restart_policy,
        planned_restart_action,
        status,
        reason
      }))
    }'
}

validate_json() {
  local missing
  missing="$(jq '[.daemons[] | select((.plist_label // "") == "" or (.expected_uptime_seconds | type) != "number" or (.binary_path // "") == "" or (.restart_policy // "") == "")] | length' "$REGISTRY")"
  audit_json | jq --argjson missing "$missing" '. + {validation:(if $missing == 0 then "pass" else "fail" end), registry_missing_required_count:$missing}'
  [ "$missing" -eq 0 ]
}

repair_json() {
  jq -nc --argjson dry_run "$DRY_RUN" '{
    schema_version:"tentacle-launchd-matrix.repair/v1",
    status:"pass",
    dry_run:$dry_run,
    planned_actions:[],
    actual_actions:[],
    note:"read-only; use matrix output for operator-reviewed restart commands"
  }'
}

render_text() {
  jq -r '.rows[] | "\(.plist_label)\tstatus=\(.status)\treason=\(.reason)\trestart_policy=\(.restart_policy)"'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    audit|doctor|health|validate|matrix|repair|why|quickstart|help|completion)
      COMMAND="$1"; shift ;;
    --registry)
      REGISTRY="${2:?--registry requires FILE}"; shift 2 ;;
    --launchctl-list)
      LAUNCHCTL_LIST_FILE="${2:?--launchctl-list requires FILE}"; shift 2 ;;
    --json)
      JSON_OUT=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --schema)
      schema; exit 0 ;;
    --info)
      info; exit 0 ;;
    --examples)
      examples; exit 0 ;;
    --help|-h)
      usage; exit 0 ;;
    --version)
      printf '%s\n' "$VERSION"; exit 0 ;;
    *)
      if [ "$COMMAND" = "help" ] || [ "$COMMAND" = "completion" ]; then
        break
      fi
      printf 'ERR: unknown arg: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$COMMAND" in
  audit|doctor|health)
    if [ "$JSON_OUT" -eq 1 ]; then audit_json; else audit_json | render_text; fi ;;
  matrix)
    audit_json | jq '{schema_version:"tentacle-launchd-restart-matrix/v1",status,restart_matrix,mutation_performed}' ;;
  validate)
    if [ "$JSON_OUT" -eq 1 ]; then validate_json; else validate_json | render_text; fi ;;
  repair)
    if [ "$DRY_RUN" -ne 1 ]; then
      printf 'ERR: repair requires --dry-run; audit mode is read-only\n' >&2
      exit 2
    fi
    repair_json ;;
  why)
    printf '%s\n' 'Tentacle daemons need one registry that joins expected plist state to launchctl reality without mutating services.' ;;
  quickstart)
    quickstart ;;
  help)
    topic_help "${1:-overview}" ;;
  completion)
    completion "${1:-bash}" ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-75-actionable-slo-burn-alert-contract.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-120-runtime-boundary-health-contract.md`
