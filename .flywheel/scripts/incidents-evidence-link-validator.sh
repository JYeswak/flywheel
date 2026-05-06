#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/josh/Developer/flywheel"
JSON_OUT=0
WARN_ONLY=0
CHANGED=0
RECENT_HOURS=0
PATHS=()

usage() {
  cat <<'EOF'
usage: incidents-evidence-link-validator.sh [--repo PATH] [--json] [--changed] [--recent-hours N] [--warn-only] [PATH ...]

Validates changed INCIDENTS.md entries against L56 evidence linkage.
Each incident entry must carry at least one evidence reference shaped as a
fuckup-log line ref, bead id, commit sha, or INCIDENTS.md anchor/path.
EOF
}

info() {
  jq -nc '{
    command:"incidents-evidence-link-validator.sh",
    schema_version:"incidents-evidence-link-validator/v1",
    purpose:"Require durable evidence links on changed INCIDENTS.md entries per L56",
    signal:"incidents_evidence_missing_count",
    accepted_evidence:["fuckup-log line ref","bead id","commit sha","INCIDENTS.md anchor/path"],
    owner:"QF.9"
  }'
}

schema() {
  jq -nc '{
    schema_version:"incidents-evidence-link-validator/v1",
    fields:["status","incidents_evidence_missing_count","files_checked","entries_checked","rows"],
    row_fields:["file","heading","start_line","end_line","reason"],
    status_values:["pass","fail","warn"],
    exit_codes:{"0":"pass or warn-only","1":"missing evidence refs","64":"usage error"}
  }'
}

examples() {
  cat <<'EOF'
incidents-evidence-link-validator.sh --json --changed
incidents-evidence-link-validator.sh --json --changed --recent-hours 24
incidents-evidence-link-validator.sh --json INCIDENTS.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --changed) CHANGED=1; shift ;;
    --recent-hours) RECENT_HOURS="${2:?}"; shift 2 ;;
    --warn-only) WARN_ONLY=1; shift ;;
    --schema) schema; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --version) printf '%s\n' "incidents-evidence-link-validator 1.0.0"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    *) PATHS+=("$1"); shift ;;
  esac
done
while [[ $# -gt 0 ]]; do
  PATHS+=("$1")
  shift
done

tmp_files="$(mktemp "${TMPDIR:-/tmp}/incidents-evidence-files.XXXXXX")"
tmp_rows="$(mktemp "${TMPDIR:-/tmp}/incidents-evidence-rows.XXXXXX")"
trap 'rm -f "$tmp_files" "$tmp_rows"' EXIT
: >"$tmp_files"
: >"$tmp_rows"

relative_path() {
  local path="$1"
  case "$path" in
    "$REPO"/*) printf '%s\n' "${path#"$REPO"/}" ;;
    "$HOME"/*) printf '~/%s\n' "${path#"$HOME"/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

add_file() {
  local p="$1"
  [[ -f "$p" ]] || return 0
  printf '%s\n' "$p" >>"$tmp_files"
}

add_incidents_file() {
  local p="$1"
  [[ "$(basename "$p")" == "INCIDENTS.md" ]] || return 0
  add_file "$p"
}

collect_changed() {
  local line path
  git -C "$REPO" status --short --untracked-files=all 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
    path="${line:3}"
    case "$path" in
      *" -> "*) path="${path##* -> }" ;;
    esac
    case "$path" in
      */INCIDENTS.md|INCIDENTS.md) add_incidents_file "$REPO/$path" ;;
    esac
  done
}

collect_recent() {
  local minutes="$1"
  [[ "$minutes" =~ ^[0-9]+$ ]] || return 0
  [[ "$minutes" -gt 0 ]] || return 0
  local roots=("$REPO" "$HOME/.claude/skills")
  local root
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" -name INCIDENTS.md -mmin "-$minutes" -print 2>/dev/null
  done | while IFS= read -r p || [[ -n "$p" ]]; do
    add_incidents_file "$p"
  done
}

is_incident_entry() {
  local body="$1"
  rg -q --color never '^(Date|Class|Promotion Action|Severity|Forever-Rule|Root Cause|Cost|Fix Applied/Status):' <<<"$body"
}

evidence_reason() {
  local body="$1"
  if ! rg -q --color never '^Evidence:' <<<"$body"; then
    printf '%s\n' "missing_evidence_block"
    return 0
  fi
  if ! evidence_ref_present "$body"; then
    printf '%s\n' "missing_evidence_reference"
    return 0
  fi
  printf '%s\n' ""
}

evidence_ref_present() {
  local body="$1"
  rg -q --color never \
    '(fuckup-log\.jsonl(#L[0-9]+(-L[0-9]+)?|:[0-9]+|[[:space:]]+lines?[[:space:]][0-9])|\.flywheel/fuckup-log/[^[:space:]`]+\.md|~/.local/state/flywheel/fuckup-log\.jsonl#L[0-9]+(-L[0-9]+)?|\b(flywheel|bd|br)-[a-z0-9]{3,}\b|\b[0-9a-f]{7,40}\b|INCIDENTS\.md#[A-Za-z0-9_.:/~@#+-]+)' \
    <<<"$body"
}

emit_missing() {
  local file="$1" heading="$2" start="$3" end="$4" reason="$5"
  jq -nc \
    --arg file "$(relative_path "$file")" \
    --arg heading "$heading" \
    --arg reason "$reason" \
    --argjson start_line "$start" \
    --argjson end_line "$end" \
    '{file:$file,heading:$heading,start_line:$start_line,end_line:$end_line,reason:$reason}' >>"$tmp_rows"
}

entries_checked=0

scan_entry() {
  local file="$1" heading="$2" start="$3" end="$4" body="$5"
  [[ "$start" -gt 0 ]] || return 0
  is_incident_entry "$body" || return 0
  entries_checked=$((entries_checked + 1))
  local reason
  reason="$(evidence_reason "$body")"
  [[ -z "$reason" ]] || emit_missing "$file" "$heading" "$start" "$end" "$reason"
}

scan_file() {
  local file="$1" line line_no=0 heading="" start=0 body=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    if [[ "$line" =~ ^##[[:space:]]+(.+) ]]; then
      scan_entry "$file" "$heading" "$start" "$((line_no - 1))" "$body"
      heading="${BASH_REMATCH[1]}"
      start="$line_no"
      body="$line"$'\n'
    elif [[ "$start" -gt 0 ]]; then
      body+="$line"$'\n'
    fi
  done <"$file"
  scan_entry "$file" "$heading" "$start" "$line_no" "$body"
}

if [[ "${#PATHS[@]}" -gt 0 ]]; then
  for p in "${PATHS[@]}"; do
    add_file "$p"
  done
else
  [[ "$CHANGED" -eq 1 || "$RECENT_HOURS" -eq 0 ]] && collect_changed
  if [[ "$RECENT_HOURS" -gt 0 ]]; then
    collect_recent "$((RECENT_HOURS * 60))"
  fi
fi

sort -u "$tmp_files" -o "$tmp_files"

files_checked=0
while IFS= read -r file || [[ -n "$file" ]]; do
  [[ -f "$file" ]] || continue
  files_checked=$((files_checked + 1))
  scan_file "$file"
done <"$tmp_files"

missing_count="$(jq -s 'length' "$tmp_rows")"
status="pass"
if [[ "$missing_count" -gt 0 ]]; then
  if [[ "$WARN_ONLY" -eq 1 ]]; then
    status="warn"
  else
    status="fail"
  fi
fi

result="$(jq -nc \
  --arg schema_version "incidents-evidence-link-validator/v1" \
  --arg status "$status" \
  --arg repo "$REPO" \
  --argjson files_checked "$files_checked" \
  --argjson entries_checked "$entries_checked" \
  --argjson missing_count "$missing_count" \
  --slurpfile rows "$tmp_rows" \
  '{
    schema_version:$schema_version,
    status:$status,
    repo:$repo,
    files_checked:$files_checked,
    entries_checked:$entries_checked,
    incidents_evidence_missing_count:$missing_count,
    rows:$rows,
    signal:{
      name:"incidents_evidence_missing_count",
      producer:"incidents-evidence-link-validator.sh",
      measurement:"Changed INCIDENTS.md entries missing Evidence block or durable evidence reference",
      consumer:"QF.9 quickfix now; future flywheel doctor strict mode",
      promotion_path:"L56 doctrine-orphaning validator"
    }
  }')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  jq -r '"status=\(.status) incidents_evidence_missing_count=\(.incidents_evidence_missing_count) files_checked=\(.files_checked) entries_checked=\(.entries_checked)"' <<<"$result"
  jq -r '.rows[]? | "\(.file):\(.start_line)-\(.end_line): \(.reason): \(.heading)"' <<<"$result"
fi

[[ "$status" != "fail" ]]
