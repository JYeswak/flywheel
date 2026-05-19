#!/usr/bin/env bash
set -euo pipefail

MODE="doctor"
JSON=0

usage() {
  cat <<'USAGE'
Usage:
  jeff-fixes-pull-probe.sh doctor|health [--json]
  jeff-fixes-pull-probe.sh --dry-run [--json]
  jeff-fixes-pull-probe.sh --info [--json]
  jeff-fixes-pull-probe.sh --examples
  jeff-fixes-pull-probe.sh completion
  jeff-fixes-pull-probe.sh --help
USAGE
}

find_puller() {
  for candidate in "$HOME/.local/bin/jeff-fixes-puller" "$HOME/.local/bin/jeff-fixes-pull" "$HOME/Developer/flywheel/.flywheel/scripts/jeff-fixes-puller.sh"; do
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

emit_json() {
  local puller output
  if puller="$(find_puller)"; then
    output="$("$puller" --dry-run --json 2>/dev/null || printf '{"status":"degraded","warnings":["jeff_fixes_puller_failed"]}')"
    jq -c --arg puller "$puller" 'if type == "object" then . + {command:"jeff-fixes-pull-probe",puller:$puller} else {command:"jeff-fixes-pull-probe",puller:$puller,result:.} end' <<<"$output"
  else
    jq -nc '{command:"jeff-fixes-pull-probe",status:"degraded",reason:"jeff_fixes_puller_missing",warnings:["orch_jeff_fixes_pull_probe_missing"]}'
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|--doctor|--health|--dry-run) MODE="doctor"; shift ;;
    --json) JSON=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    completion) MODE="completion"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  doctor)
    if [[ "$JSON" -eq 1 ]]; then
      emit_json
    else
      emit_json | jq -r '"jeff-fixes-pull-probe " + (.status // "ok") + " reason=" + (.reason // "none")'
    fi
    ;;
  info)
    jq -nc '{command:"jeff-fixes-pull-probe",read_only:true,mutation_mode:"dry-run-only"}'
    ;;
  examples)
    printf '%s\n' '.flywheel/scripts/jeff-fixes-pull-probe.sh doctor --json'
    ;;
  completion)
    printf 'complete -W "doctor health --dry-run --json --info --examples completion --help" jeff-fixes-pull-probe.sh\n'
    ;;
  help)
    usage
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
