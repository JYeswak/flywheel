#!/usr/bin/env bash
set -euo pipefail

VERSION="scratch-cleanup/v1"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
MODE="dry-run"
JSON_OUT=0
COMMAND="cleanup"
TARGET=""

usage() {
  cat <<'USAGE'
usage: cleanup-scratch.sh [--dry-run|--apply] [--json] [--info] ABSOLUTE_PATH
       cleanup-scratch.sh doctor|health|schema|info|examples|validate|why [ARGS] [--json]

Safely removes one flywheel scratch directory. Default mode is --dry-run.
Allowed targets:
  /var/folders/*/T/(flywheel|josh|wave)-*
  /tmp/(flywheel|dispatch_)-*
USAGE
}

json_string() {
  jq -Rn --arg v "$1" '$v'
}

emit_json() {
  local status="$1" reason="$2" path="$3" exists="$4" action="$5"
  jq -cn \
    --arg schema_version "$VERSION" \
    --arg command "$COMMAND" \
    --arg mode "$MODE" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg path "$path" \
    --arg exists "$exists" \
    --arg action "$action" \
    '{schema_version:$schema_version,command:$command,mode:$mode,status:$status,reason:$reason,path:$path,exists:($exists=="true"),action:$action}'
}

emit_text() {
  local status="$1" reason="$2" path="$3" _exists="$4" action="$5"
  printf 'status=%s reason=%s action=%s path=%s\n' "$status" "$reason" "$action" "$path"
}

emit() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    emit_json "$@"
  else
    emit_text "$@"
  fi
}

is_allowed_path() {
  local path="$1"
  [[ "$path" =~ ^/var/folders/.*/T/(flywheel|josh|wave)-.+$ ]] && return 0
  [[ "$path" =~ ^/tmp/(flywheel|dispatch_)-.+$ ]] && return 0
  return 1
}

status_for_path() {
  local path="$1"
  if [[ "$path" != /* ]]; then
    emit refused path_not_absolute "$path" false none
    return 3
  fi
  if ! is_allowed_path "$path"; then
    emit refused path_outside_scratch_allowlist "$path" false none
    return 3
  fi
  if [[ ! -e "$path" ]]; then
    emit ok nonexistent_noop "$path" false none
    return 0
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    emit ok would_remove "$path" true dry_run
    return 0
  fi
  /usr/bin/python3 - "$path" <<'PY'
import os
import shutil
import sys
path = sys.argv[1]
if os.path.isdir(path) and not os.path.islink(path):
    shutil.rmtree(path)
else:
    os.unlink(path)
PY
  emit ok removed "$path" false removed
}

schema() {
  jq -cn --arg schema_version "$VERSION" '{
    schema_version:$schema_version,
    command:"cleanup-scratch",
    default_mode:"dry-run",
    mutation_modes:["--dry-run","--apply"],
    stable_exit_codes:{"0":"ok","2":"usage","3":"refused_invalid_path"},
    allowed_path_patterns:[
      "^/var/folders/.*/T/(flywheel|josh|wave)-.*",
      "^/tmp/(flywheel|dispatch_)-.*"
    ],
    output_fields:["schema_version","command","mode","status","reason","path","exists","action"]
  }'
}

doctor() {
  local status="pass"
  [[ -x "$SCRIPT_PATH" ]] || status="warn"
  jq -cn --arg schema_version "$VERSION" --arg status "$status" --arg script "$SCRIPT_PATH" '{
    schema_version:$schema_version,
    command:"doctor",
    status:$status,
    subsystems:{
      script:{status:(if $status=="pass" then "ok" else "warn" end), path:$script},
      python:{status:"ok", binary:"/usr/bin/python3"},
      jq:{status:"ok"}
    }
  }'
}

health() {
  jq -cn --arg schema_version "$VERSION" '{schema_version:$schema_version,command:"health",status:"pass"}'
}

examples() {
  jq -cn --arg schema_version "$VERSION" '{
    schema_version:$schema_version,
    command:"examples",
    examples:[
      "cleanup-scratch.sh --dry-run --json /tmp/flywheel-demo.abc123",
      "cleanup-scratch.sh --apply --json /tmp/flywheel-demo.abc123",
      "cleanup-scratch.sh validate /var/folders/x/y/T/flywheel-demo.abc123 --json",
      "cleanup-scratch.sh why path-policy --json"
    ]
  }'
}

info() {
  jq -cn --arg schema_version "$VERSION" --arg script "$SCRIPT_PATH" '{
    schema_version:$schema_version,
    name:"flywheel-cleanup-scratch",
    script:$script,
    default_mode:"dry-run",
    apply_requires_valid_scratch_path:true
  }'
}

why() {
  local subject="${1:-path-policy}"
  jq -cn --arg schema_version "$VERSION" --arg subject "$subject" '{
    schema_version:$schema_version,
    command:"why",
    subject:$subject,
    reason:"Workers need a narrow, audited primitive for dispatch scratch cleanup without raw recursive deletion in pane commands."
  }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|schema|info|examples|validate|why)
      COMMAND="$1"; shift ;;
    --dry-run)
      MODE="dry-run"; shift ;;
    --apply)
      MODE="apply"; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    --info)
      COMMAND="info"; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"; shift
      else
        printf 'unknown argument: %s\n' "$1" >&2
        exit 2
      fi ;;
  esac
done

case "$COMMAND" in
  schema) schema; exit 0 ;;
  doctor) doctor; exit 0 ;;
  health) health; exit 0 ;;
  examples) examples; exit 0 ;;
  info) info; exit 0 ;;
  why) why "$TARGET"; exit 0 ;;
  validate)
    [[ -n "$TARGET" ]] || { usage >&2; exit 2; }
    MODE="dry-run"
    set +e
    status_for_path "$TARGET" >/dev/null
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
      emit ok valid_scratch_path "$TARGET" "$([[ -e "$TARGET" ]] && printf true || printf false)" none
    else
      exit "$rc"
    fi
    ;;
  cleanup)
    [[ -n "$TARGET" ]] || { usage >&2; exit 2; }
    status_for_path "$TARGET"
    ;;
esac
