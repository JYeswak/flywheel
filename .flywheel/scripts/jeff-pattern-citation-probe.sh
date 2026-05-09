#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/josh/Developer/flywheel"
JSON_OUT=0
DOCTOR=0
PATHS=()

usage() {
  cat <<'EOF'
usage: jeff-pattern-citation-probe.sh [--repo PATH] [--json] [--doctor] [PATH ...]

Validates Jeff-originated pattern claims. Any doctrine, skill draft, or plan
line that imports/adopts a Jeff pattern must include:

  Source: Jeff <repo>:<file>:<line> + ZestStream adaptation
EOF
}

info() {
  jq -nc '{
    command:"jeff-pattern-citation-probe.sh",
    schema_version:"jeff-pattern-citation/v1",
    purpose:"Require file-line evidence before importing Jeff-originated patterns into flywheel doctrine, skills, or plans",
    signal:"jeff_pattern_uncited_count",
    required_citation:"Source: Jeff <repo>:<file>:<line> + ZestStream adaptation",
    owner_bead:"flywheel-jhcd"
  }'
}

schema() {
  jq -nc '{
    schema_version:"jeff-pattern-citation/v1",
    fields:["status","jeff_pattern_uncited_count","files_checked","rows"],
    row_fields:["file","line","reason","text"],
    status_values:["pass","fail"],
    doctor_mode:"exits zero and exposes jeff_pattern_uncited_count"
  }'
}

examples() {
  cat <<'EOF'
jeff-pattern-citation-probe.sh --json
jeff-pattern-citation-probe.sh --doctor --json
jeff-pattern-citation-probe.sh --json tests/fixtures/jeff-pattern-citation/valid.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --doctor) DOCTOR=1; JSON_OUT=1; shift ;;
    --schema) schema; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --version) printf '%s\n' "jeff-pattern-citation-probe 1.0.0"; exit 0 ;;
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

claim_line() {
  local line="$1" lower
  lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
  [[ "$lower" =~ (jeff|dicklesworthstone) ]] || return 1
  # Existing whitelist of self-referential / canonical-mentor tokens.
  [[ "$lower" =~ (jeff-pattern-citation|jeff_pattern_uncited_count|feedback_meadows_jeff_mentors|reference_dicklesworthstone|dicklesworthstone-stack) ]] && return 1
  [[ "$line" == *"Source: Jeff <repo>:<file>:<line> + ZestStream adaptation"* ]] && return 1
  # bead flywheel-4rmc approved exclusion classes:
  #   1. Markdown section headers — they introduce a block; the
  #      citation is on a separate line within the block. Header
  #      lines themselves are metadata, not claims.
  #   2. Sanitized historical excerpts in MISSION.md / receipts /
  #      audit packs — these capture past state (e.g.
  #      `**sanitized_excerpt:** "...jeff_patterns_adopted=N..."`)
  #      and are not new pattern claims.
  #   3. References to Jeff-DERIVED SKILLS (`jeff-convergence-audit`,
  #      `jeff-issue-chain`, `jeff-corpus`, `jeff-intel`, etc.) when
  #      they appear as the substrate name rather than a pattern
  #      adopted from Jeff source. These are skill citations, not
  #      pattern imports.
  # See .flywheel/audit/flywheel-4rmc/compliance-pack.md for the
  # full rationale and approved-exclusion fixture.
  [[ "$line" =~ ^\#+[[:space:]] ]] && return 1
  [[ "$lower" == *"sanitized_excerpt:"* ]] && return 1
  [[ "$lower" =~ jeff-(convergence-audit|issue-chain|corpus|intel|substrate|clone-backups|patterns?|swarm-ops|status|philosophy)[[:space:]]+(phase|skill|directory|tool|loop|tracker|substrate) ]] && return 1
  [[ "$lower" == *"jeff-convergence-audit "* || "$lower" == *"jeff-convergence-audit."* || "$lower" == *"jeff-issue-chain "* || "$lower" == *"jeff-issue-chain."* ]] && return 1
  [[ "$lower" =~ (source:[[:space:]]*jeff|inspired[[:space:]]+by[[:space:]]+jeff|jeff[^[:alnum:]]+(pattern|method|doctrine|skill|origin|originated|mentor|style|prior[[:space:]]+art)|dicklesworthstone[^[:alnum:]]+(pattern|method|doctrine|origin|originated)|adopt[^[:alnum:]]+.*jeff|adapt[^[:alnum:]]+.*jeff|learn[^[:alnum:]]+.*jeff|jeff-originated) ]]
}

valid_citation() {
  local line="$1"
  # Canonical prose shape (per bead body):
  #   "Source: Jeff <repo>:<file>:<line> + ZestStream adaptation"
  if [[ "$line" =~ Source:[[:space:]]Jeff[[:space:]][^[:space:]:]+:[^[:space:]]+:[0-9]+[[:space:]]\+[[:space:]]ZestStream[[:space:]]adaptation ]]; then
    return 0
  fi
  # Alternative structured-key shape adopted in wire-or-explain plan
  # outputs (bead flywheel-4rmc approved exclusion class — see
  # .flywheel/audit/flywheel-4rmc/compliance-pack.md). Lines that
  # carry an explicit `jeff_evidence_path=<path>:<line-or-range>`
  # are properly cited in machine-readable form even when they
  # don't use the prose shape.
  if [[ "$line" =~ jeff_evidence_path=\`?[^[:space:]\`]+:[0-9]+(-[0-9]+)?\`? ]]; then
    return 0
  fi
  return 1
}

relative_path() {
  local path="$1"
  case "$path" in
    "$REPO"/*) printf '%s\n' "${path#"$REPO"/}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

collect_default_paths() {
  local p
  for p in "$REPO/AGENTS.md" "$REPO/README.md" "$REPO/.flywheel/AGENTS.md" "$REPO/.flywheel/MISSION.md"; do
    [[ -f "$p" ]] && printf '%s\n' "$p"
  done
  # Walk PLANS (canonical uppercase) and doctrine. Skip the lowercase
  # `.flywheel/plans/` duplicate when both trees exist with identical
  # content — every hit there is already counted under PLANS, so the
  # walk would otherwise double-count. This is one of the
  # bead flywheel-4rmc approved exclusion classes; see
  # .flywheel/audit/flywheel-4rmc/compliance-pack.md for the
  # rationale + fixture.
  for p in "$REPO/.flywheel/PLANS" "$REPO/.flywheel/doctrine"; do
    [[ -d "$p" ]] && find "$p" -type f -name '*.md' -print
  done
  if [[ -d "$REPO/.flywheel/plans" && ! -d "$REPO/.flywheel/PLANS" ]]; then
    find "$REPO/.flywheel/plans" -type f -name '*.md' -print
  fi
}

tmp_files="$(mktemp "${TMPDIR:-/tmp}/jeff-pattern-files.XXXXXX")"
tmp_rows="$(mktemp "${TMPDIR:-/tmp}/jeff-pattern-rows.XXXXXX")"
trap 'rm -f "$tmp_files" "$tmp_rows"' EXIT
: >"$tmp_rows"

if [[ "${#PATHS[@]}" -gt 0 ]]; then
  for p in "${PATHS[@]}"; do
    [[ -f "$p" ]] && printf '%s\n' "$p" >>"$tmp_files"
  done
else
  collect_default_paths | sort -u >"$tmp_files"
fi

files_checked=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  files_checked=$((files_checked + 1))
  set +e
  hits="$(rg -n -i --color never 'jeff|dicklesworthstone' "$file" 2>/dev/null)"
  hit_rc=$?
  set -e
  [[ "$hit_rc" -eq 0 ]] || continue
  while IFS= read -r hit || [[ -n "$hit" ]]; do
    line_no="${hit%%:*}"
    line="${hit#*:}"
    if claim_line "$line" && ! valid_citation "$line"; then
      rel="$(relative_path "$file")"
      jq -nc \
        --arg file "$rel" \
        --argjson line "$line_no" \
        --arg reason "missing_jeff_file_line_source" \
        --arg text "$line" \
        '{file:$file,line:$line,reason:$reason,text:$text}' >>"$tmp_rows"
    fi
  done <<<"$hits"
done <"$tmp_files"

uncited_count="$(jq -s 'length' "$tmp_rows")"
status="pass"
if [[ "$uncited_count" -gt 0 ]]; then
  status="fail"
fi

result="$(jq -nc \
  --arg schema_version "jeff-pattern-citation/v1" \
  --arg status "$status" \
  --arg repo "$REPO" \
  --argjson files_checked "$files_checked" \
  --argjson count "$uncited_count" \
  --slurpfile rows "$tmp_rows" \
  '{
    schema_version:$schema_version,
    status:$status,
    repo:$repo,
    files_checked:$files_checked,
    jeff_pattern_uncited_count:$count,
    rows:$rows,
    signals:[{
      name:"jeff_pattern_uncited_count",
      producer:"jeff-pattern-citation-probe.sh",
      measurement:"Jeff-originated pattern claims missing Source: Jeff <repo>:<file>:<line> + ZestStream adaptation",
      consumer:"worker closeout / flywheel-loop doctor-equivalent probe",
      promotion_path:"L64 -> L56 -> bead update for uncited Jeff imports"
    }]
  }')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  jq -r '"status=\(.status) jeff_pattern_uncited_count=\(.jeff_pattern_uncited_count) files_checked=\(.files_checked)"' <<<"$result"
  jq -r '.rows[]? | "\(.file):\(.line): \(.reason): \(.text)"' <<<"$result"
fi

if [[ "$DOCTOR" -eq 1 ]]; then
  exit 0
fi
[[ "$status" == "pass" ]]
