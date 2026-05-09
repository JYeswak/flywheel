#!/usr/bin/env bash
set -euo pipefail

VERSION="tentacle-source-presence-audit.v1"
COMMAND="audit"
JSON_OUT=0
ROOT="${TENTACLE_SOURCE_ROOT:-$HOME/Developer}"
MANIFEST_FILE="${TENTACLE_SOURCE_MANIFEST:-}"
DRY_RUN=0

usage() {
  cat <<'EOF'
usage: tentacle-source-presence-audit.sh [audit|validate|doctor|health|repair|why|quickstart|help|completion] [--json]
       tentacle-source-presence-audit.sh [--root PATH] [--manifest FILE] [--schema|--info|--examples]

Audits source clone presence for adopted Jeff tentacles. Missing sources are
surfaced as warn rows; this command never clones repositories.

Options:
  --root PATH       Source checkout root, default $HOME/Developer
  --manifest FILE   JSON array of tentacles for fixture or override use
  --json            Emit JSON
  --dry-run         Required for repair; repair is read-only
EOF
}

default_manifest() {
  cat <<'EOF'
[
  {"name":"ntm","repo":"ntm","adoption_status":"adopted","expected_path":"ntm"},
  {"name":"br","repo":"beads_rust","adoption_status":"adopted","expected_path":"beads_rust"},
  {"name":"bv","repo":"beads_viewer","adoption_status":"adopted","expected_path":"beads_viewer"},
  {"name":"dcg","repo":"destructive_command_guard","adoption_status":"adopted","expected_path":"destructive_command_guard"},
  {"name":"cass","repo":"cass_memory_system","adoption_status":"adopted","expected_path":"cass_memory_system"},
  {"name":"mcp_agent_mail","repo":"mcp_agent_mail","adoption_status":"adopted","expected_path":"mcp_agent_mail"},
  {"name":"vc","repo":"vibe-cockpit","adoption_status":"adopted","expected_path":"vibe-cockpit"},
  {"name":"pi","repo":"pi_agent_rust","adoption_status":"adopted","expected_path":"pi_agent_rust"},
  {"name":"frankensqlite","repo":"frankensqlite","adoption_status":"adopted_transitively","expected_path":"frankensqlite"},
  {"name":"asupersync","repo":"asupersync","adoption_status":"adopted_transitively","expected_path":"asupersync"}
]
EOF
}

schema() {
  jq -nc '{
    schema_version:"tentacle-source-presence-audit.schema/v1",
    required:["schema_version","status","total","source_present_count","source_missing_count","rows","auto_clone_attempted"],
    row_required:["name","repo","adoption_status","source_path","source_present","route","route_reason"],
    exit_codes:{"0":"audit/validation completed","1":"validation failed","2":"usage error"}
  }'
}

info() {
  jq -nc --arg version "$VERSION" --arg root "$ROOT" --arg manifest "${MANIFEST_FILE:-builtin}" \
    '{schema_version:"tentacle-source-presence-audit.info/v1",version:$version,root:$root,manifest:$manifest,mutation:"none"}'
}

examples() {
  jq -nc '{schema_version:"tentacle-source-presence-audit.examples/v1",examples:[
    ".flywheel/scripts/tentacle-source-presence-audit.sh --json",
    ".flywheel/scripts/tentacle-source-presence-audit.sh validate --json",
    ".flywheel/scripts/tentacle-source-presence-audit.sh --root /Users/josh/Developer --json",
    ".flywheel/scripts/tentacle-source-presence-audit.sh repair --dry-run --json"
  ]}'
}

quickstart() {
  cat <<'EOF'
1. Run: .flywheel/scripts/tentacle-source-presence-audit.sh --json
2. Inspect rows where source_present=false.
3. Missing adopted sources are warnings, not auto-clone actions.
4. Route clone decisions to Joshua/L61 outside this read-only audit.
EOF
}

topic_help() {
  local topic="${1:-overview}"
  case "$topic" in
    exit-codes)
      cat <<'EOF'
exit codes:
  0  audit completed or validation passed
  1  validation found a silent missing-source route
  2  usage error
EOF
      ;;
    overview|routing)
      cat <<'EOF'
routing:
  source_present=true   route=none
  missing adopted       route=warn, reason=surface_only_no_auto_clone_policy
  missing evaluating    route=warn, reason=deferred_source_decision
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
complete -W "audit validate doctor health repair why quickstart help completion exit-codes routing --json --root --manifest --schema --info --examples --dry-run --help" tentacle-source-presence-audit.sh
EOF
      ;;
    *)
      printf 'completion unavailable for %s\n' "$shell" >&2
      return 2
      ;;
  esac
}

load_manifest() {
  if [ -n "$MANIFEST_FILE" ]; then
    cat "$MANIFEST_FILE"
  else
    default_manifest
  fi
}

audit_json() {
  local manifest rows tmp status
  tmp="$(mktemp -d -t tentacle-source.XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN
  load_manifest >"$tmp/manifest.json"
  rows="$tmp/rows.json"
  jq -c --arg root "$ROOT" '
    map(
      .source_path = ($root + "/" + (.expected_path // .repo)) |
      .source_present = ((.source_path | tostring) as $p | false)
    )
  ' "$tmp/manifest.json" >"$tmp/base.json"

  jq -c '.[]' "$tmp/base.json" | while IFS= read -r row; do
    path="$(printf '%s\n' "$row" | jq -r '.source_path')"
    if [ -d "$path" ]; then
      present=true
    else
      present=false
    fi
    printf '%s\n' "$row" | jq -c --argjson present "$present" '
      .source_present = $present |
      if $present then
        .route = "none" |
        .route_reason = "source_present"
      elif (.adoption_status | test("adopted")) then
        .route = "warn" |
        .route_reason = "surface_only_no_auto_clone_policy"
      else
        .route = "warn" |
        .route_reason = "deferred_source_decision"
      end |
      .auto_clone_attempted = false
    '
  done | jq -s '.' >"$rows"

  status="$(jq -r 'if any(.[]; .source_present == false) then "warn" else "pass" end' "$rows")"
  jq -nc \
    --arg status "$status" \
    --arg root "$ROOT" \
    --argjson rows "$(cat "$rows")" \
    '{
      schema_version:"tentacle-source-presence-audit/v1",
      status:$status,
      root:$root,
      total:($rows | length),
      source_present_count:($rows | map(select(.source_present == true)) | length),
      source_missing_count:($rows | map(select(.source_present == false)) | length),
      warn_count:($rows | map(select(.route == "warn")) | length),
      l61_message_count:($rows | map(select(.route == "l61_message")) | length),
      auto_clone_attempted:false,
      rows:$rows
    }'
}

render_text() {
  jq -r '.rows[] | "\(.name)\tsource_present=\(.source_present)\troute=\(.route)\tpath=\(.source_path)"'
}

validate_json() {
  local data invalid
  data="$(audit_json)"
  invalid="$(printf '%s\n' "$data" | jq '[.rows[] | select(.source_present == false and (.route != "warn" and .route != "l61_message"))] | length')"
  if [ "$invalid" -eq 0 ] && printf '%s\n' "$data" | jq -e '.auto_clone_attempted == false' >/dev/null; then
    printf '%s\n' "$data" | jq '. + {validation:"pass"}'
    return 0
  fi
  printf '%s\n' "$data" | jq '. + {validation:"fail"}'
  return 1
}

repair_json() {
  jq -nc --argjson dry_run "$DRY_RUN" '{
    schema_version:"tentacle-source-presence-audit.repair/v1",
    status:"pass",
    dry_run:$dry_run,
    planned_actions:[],
    actual_actions:[],
    note:"read-only; clone decisions route outside this audit"
  }'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    audit|validate|doctor|health|repair|why|quickstart|help|completion)
      COMMAND="$1"; shift ;;
    --root)
      ROOT="${2:?--root requires PATH}"; shift 2 ;;
    --manifest)
      MANIFEST_FILE="${2:?--manifest requires FILE}"; shift 2 ;;
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
    if [ "$JSON_OUT" -eq 1 ]; then
      audit_json
    else
      audit_json | render_text
    fi
    ;;
  validate)
    if [ "$JSON_OUT" -eq 1 ]; then
      validate_json
    else
      validate_json | render_text
    fi
    ;;
  repair)
    if [ "$DRY_RUN" -ne 1 ]; then
      printf 'ERR: repair requires --dry-run; this audit is read-only\n' >&2
      exit 2
    fi
    repair_json
    ;;
  why)
    printf '%s\n' 'Source-to-binary traceability needs local source presence; clone decisions remain Joshua/L61-routed.'
    ;;
  quickstart)
    quickstart ;;
  help)
    topic_help "${1:-overview}" ;;
  completion)
    completion "${1:-bash}" ;;
esac
