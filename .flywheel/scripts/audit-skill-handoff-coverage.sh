#!/usr/bin/env bash
set -euo pipefail

PERIOD_DAYS="${AUDIT_SKILL_HANDOFF_PERIOD_DAYS:-30}"
SKILL_ROOTS="${AUDIT_SKILL_HANDOFF_SKILL_ROOTS:-$HOME/.claude/skills:$HOME/.codex/skills}"
DISPATCH_LOG="${AUDIT_SKILL_HANDOFF_DISPATCH_LOG:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)/.flywheel/dispatch-log.jsonl}"
SKILLOS_STATE_DIR="${AUDIT_SKILL_HANDOFF_SKILLOS_STATE_DIR:-$HOME/Developer/skillos/state}"
NOW_EPOCH="${AUDIT_SKILL_HANDOFF_NOW_EPOCH:-$(date +%s)}"

usage() {
  cat <<'EOF'
usage: audit-skill-handoff-coverage.sh [--period-days N] [--json]

Walk recent SKILL.md files and report missing flywheel -> skillos handoff
coverage. This script is read-only against SkillOS state.

Environment overrides:
  AUDIT_SKILL_HANDOFF_SKILL_ROOTS       colon-separated skill roots
  AUDIT_SKILL_HANDOFF_DISPATCH_LOG      dispatch log JSONL path
  AUDIT_SKILL_HANDOFF_SKILLOS_STATE_DIR SkillOS state directory
  AUDIT_SKILL_HANDOFF_NOW_EPOCH         deterministic test clock
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --period-days) PERIOD_DAYS="${2:-}"; shift 2 ;;
    --period-days=*) PERIOD_DAYS="${1#--period-days=}"; shift ;;
    --json|--no-color|--no-emoji) shift ;;
    --width) shift 2 ;;
    --help|-h|help) usage; exit 0 ;;
    *) printf 'ERROR: unknown arg %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || {
  printf 'ERROR: jq is required\n' >&2
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  printf 'ERROR: python3 is required\n' >&2
  exit 1
}

if ! [[ "$PERIOD_DAYS" =~ ^[0-9]+$ ]] || [[ "$PERIOD_DAYS" -lt 1 ]]; then
  printf 'ERROR: --period-days must be a positive integer\n' >&2
  exit 2
fi

TMPDIR_AUDIT="$(mktemp -d "${TMPDIR:-/tmp}/audit-skill-handoff.XXXXXX")"
trap 'rm -rf "$TMPDIR_AUDIT"' EXIT
skills_jsonl="$TMPDIR_AUDIT/skills.jsonl"
dispatch_index_json="$TMPDIR_AUDIT/dispatch-index.json"
receipt_index_txt="$TMPDIR_AUDIT/receipt-index.txt"
: >"$skills_jsonl"

build_dispatch_index() {
  if [[ ! -s "$DISPATCH_LOG" ]]; then
    printf '{}\n' >"$dispatch_index_json"
    return 0
  fi
  jq -Rsc '
    split("\n")
    | map(fromjson? // empty)
    | map(select(.skill and (.event == "skillos_handoff_sent" or .event == "skillos_handoff_skipped")))
    | reduce .[] as $row ({};
        .[$row.skill] =
          if $row.event == "skillos_handoff_skipped" and (($row.skillos_handoff_skipped_reason // "") != "")
          then {state:"intentional_skip", reason:$row.skillos_handoff_skipped_reason, dispatch_row:$row}
          elif $row.event == "skillos_handoff_sent"
          then {state:"sent", dispatch_row:$row}
          else (.[$row.skill] // {state:"missing"})
          end
      )
  ' "$DISPATCH_LOG" >"$dispatch_index_json"
}

cutoff_epoch=$((NOW_EPOCH - (PERIOD_DAYS * 86400)))
build_dispatch_index
if [[ -d "$SKILLOS_STATE_DIR" ]]; then
  find "$SKILLOS_STATE_DIR" -maxdepth 1 -type f -name '*.json' -exec basename {} \; >"$receipt_index_txt"
else
  : >"$receipt_index_txt"
fi

python3 - "$SKILL_ROOTS" "$cutoff_epoch" "$skills_jsonl" <<'PY'
import datetime as dt
import json
import os
import sys

roots_arg, cutoff_arg, out_path = sys.argv[1:4]
cutoff = int(cutoff_arg)

def version_from_skill_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                stripped = line.strip()
                if stripped.startswith("version:"):
                    return stripped.split(":", 1)[1].strip().strip('"') or "0.0.0"
    except OSError:
        pass
    return "0.0.0"

with open(out_path, "w", encoding="utf-8") as out:
    for root in [item for item in roots_arg.split(":") if item]:
        if not os.path.isdir(root):
            continue
        try:
            skill_dirs = sorted(os.scandir(root), key=lambda item: item.name)
        except OSError:
            continue
        for entry in skill_dirs:
            if not entry.is_dir(follow_symlinks=False):
                continue
            skill_file = os.path.join(entry.path, "SKILL.md")
            try:
                stat = os.stat(skill_file)
            except OSError:
                continue
            if int(stat.st_mtime) < cutoff:
                continue
            mtime = dt.datetime.fromtimestamp(stat.st_mtime, tz=dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            row = {
                "skill": entry.name,
                "path": entry.path,
                "version": version_from_skill_file(skill_file),
                "mtime": mtime,
            }
            out.write(json.dumps(row, sort_keys=True) + "\n")
PY

jq -n \
  --argjson period_days "$PERIOD_DAYS" \
  --arg dispatch_log "$DISPATCH_LOG" \
  --arg skill_roots "$SKILL_ROOTS" \
  --arg skillos_state_dir "$SKILLOS_STATE_DIR" \
  --slurpfile skills "$skills_jsonl" \
  --slurpfile dispatch_index "$dispatch_index_json" \
  --rawfile receipt_index "$receipt_index_txt" \
  '{
    dispatch_index:($dispatch_index[0] // {}),
    receipt_names:($receipt_index | split("\n") | map(select(length > 0)))
  } as $indexes
  | def minor($version):
      if ($version | test("^[0-9]+[.][0-9]+[.]")) then
        ($version | split(".") | .[0:2] | join("."))
      else $version end;
    def has_receipt($skill; $version):
      (minor($version)) as $minor
      | any($indexes.receipt_names[]; startswith($skill + "-v" + $version + "-")
          or startswith($skill + "-v" + $minor + "-")
          or startswith($skill + "-"));
    {
    period_days:$period_days,
    skills_checked:($skills | length),
    dispatch_log:$dispatch_log,
    skill_roots:($skill_roots | split(":")),
    skillos_state_dir:$skillos_state_dir,
    gaps:[
      $skills[]
      | . as $skill_row
      | ($indexes.dispatch_index[$skill_row.skill] // {state:"missing"}) as $dispatch
      | if $dispatch.state == "intentional_skip" then empty
        elif $dispatch.state == "missing" then
          {skill:$skill_row.skill, mtime:$skill_row.mtime, reason:"no_dispatch_log_entry"}
        elif (has_receipt($skill_row.skill; $skill_row.version) | not) then
          {skill:$skill_row.skill, version:$skill_row.version, mtime:$skill_row.mtime, reason:"no_skillos_receipt"}
        else empty end
    ],
    intentional_skips:[
      $skills[]
      | . as $skill_row
      | ($indexes.dispatch_index[$skill_row.skill] // {state:"missing"}) as $dispatch
      | select($dispatch.state == "intentional_skip")
      | {skill:$skill_row.skill, reason:$dispatch.reason, mtime:$skill_row.mtime}
    ]
  }'

exit 0
