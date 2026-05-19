#!/usr/bin/env bash
# flywheel-cli-surface: true
# inject-doc-toc.sh — inject TOC into long markdown docs missing one.
#
# Auto-generates a TOC from H2 (and selected H3) headers in the body
# and inserts it after frontmatter (or after the first H1 if no
# frontmatter). Idempotent: skips files whose first 50 lines already
# contain "Table of Contents", "## TOC", "## Contents", or a markdown-
# anchor list.
#
# Bead: flywheel-at83y. Spec: .flywheel/audit/flywheel-fs-rag-high-impact/apply-spec.md.
set -euo pipefail

SCHEMA_VERSION="inject-doc-toc/v1"
VERSION="0.1.0"

usage() {
  cat <<'USAGE'
inject-doc-toc.sh — inject TOC into long markdown docs

USAGE:
  inject-doc-toc.sh <file>                                          # dry-run
  inject-doc-toc.sh <file> --apply --idempotency-key <KEY>          # apply
  inject-doc-toc.sh <file>... --apply --idempotency-key <KEY>       # multi
  inject-doc-toc.sh --info | --schema | --examples | --doctor | --help

EXIT CODES:
  0 ok | 1 idem-key required for --apply | 2 bad args | 3 not found
USAGE
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" '{
    schema_version:$sv, success:true, mode:"info",
    name:"inject-doc-toc", version:$v,
    idempotent:true,
    skip_marker:["Table of Contents","## TOC","## Contents","markdown anchor list"],
    inserts:"H2 + H3 anchors as bullet list with markdown anchor links",
    placement:"after frontmatter (or after first H1)"
  }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv, title:"inject-doc-toc result row",
    type:"object",
    required:["schema_version","mode","files_processed","files_modified","files_skipped"],
    properties:{
      schema_version:{const:$sv},
      mode:{enum:["dry-run","apply"]},
      idempotency_key:{type:["string","null"]},
      files_processed:{type:"integer",minimum:0},
      files_modified:{type:"integer",minimum:0},
      files_skipped:{type:"integer",minimum:0}
    }
  }'
}

emit_examples() {
  cat <<'EX'
inject-doc-toc.sh .flywheel/PLANS/recovery-system-2026-05-01/01-RESEARCH-C.md
inject-doc-toc.sh .flywheel/PLANS/recovery-system-2026-05-01/01-RESEARCH-C.md --apply --idempotency-key f8-batch-2026-05-10
EOF
EX
}

emit_doctor() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:($sv | sub("/v1$"; ".doctor.v1")), status:"pass"
  }'
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# Has TOC already? (idempotency check)
has_toc() {
  head -50 "$1" 2>/dev/null | grep -qiE 'table of contents|^## (toc|contents)|^- \[.*\]\(#'
}

# Generate TOC body from H2/H3 in file
gen_toc() {
  local f="$1"
  local toc=""
  toc+=$'\n## Contents\n\n'
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
      local title="${BASH_REMATCH[1]}"
      # Skip the Contents section itself
      [[ "$title" =~ ^(Contents|TOC|Table of Contents)$ ]] && continue
      local slug
      slug=$(slugify "$title")
      toc+="- [${title}](#${slug})"$'\n'
    elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
      local title="${BASH_REMATCH[1]}"
      local slug
      slug=$(slugify "$title")
      toc+="  - [${title}](#${slug})"$'\n'
    fi
  done < "$f"
  echo "$toc"
}

process_file() {
  local f="$1" mode="$2"
  if [[ ! -f "$f" ]]; then
    printf 'NOT-FOUND %s\n' "$f"
    return 3
  fi
  if has_toc "$f"; then
    printf 'SKIP %s (already has TOC)\n' "$f"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  PROCESSED=$((PROCESSED + 1))

  # Build TOC
  local toc
  toc=$(gen_toc "$f")
  if [[ "$(echo "$toc" | grep -c '^- \[')" -lt 2 ]]; then
    printf 'SKIP %s (fewer than 2 H2/H3 headers; TOC not useful)\n' "$f"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  if [[ "$mode" == "dry-run" ]]; then
    printf 'WOULD-INJECT %s\n' "$f"
    return 0
  fi

  # Apply: insert TOC after frontmatter (or after first H1) and before
  # the next non-blank content line. Use bash mapfile to avoid awk's
  # multiline -v variable handling.
  local tmp
  tmp=$(mktemp)
  mapfile -t lines < "$f"

  local in_fm=false fm_done=false injected=false
  local i
  for ((i=0; i<${#lines[@]}; i++)); do
    local L="${lines[$i]}"
    if [[ "$i" -eq 0 && "$L" == "---" ]]; then
      in_fm=true
      printf '%s\n' "$L" >> "$tmp"
      continue
    fi
    if $in_fm && [[ "$L" == "---" ]]; then
      printf '%s\n' "$L" >> "$tmp"
      in_fm=false
      fm_done=true
      printf '%s' "$toc" >> "$tmp"
      injected=true
      continue
    fi
    if $in_fm; then
      printf '%s\n' "$L" >> "$tmp"
      continue
    fi
    if ! $injected && [[ "$L" =~ ^\# ]] && [[ ! "$L" =~ ^\#\# ]]; then
      printf '%s\n' "$L" >> "$tmp"
      printf '%s' "$toc" >> "$tmp"
      injected=true
      continue
    fi
    printf '%s\n' "$L" >> "$tmp"
  done

  # Fallback: if no insertion point found (no frontmatter, no H1), prepend
  if ! $injected; then
    {
      printf '%s' "$toc"
      cat "$f"
    } > "$tmp"
  fi

  mv "$tmp" "$f"
  printf 'INJECTED %s\n' "$f"
  MODIFIED=$((MODIFIED + 1))
}

MODE=dry-run
IDEM_KEY=""
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --doctor|--health) emit_doctor; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --apply) MODE=apply; shift ;;
    --dry-run) MODE=dry-run; shift ;;
    --idempotency-key) IDEM_KEY="$2"; shift 2 ;;
    --) shift; while [[ $# -gt 0 ]]; do TARGETS+=("$1"); shift; done ;;
    -*) echo "ERR: unknown flag: $1" >&2; exit 2 ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

[[ "${#TARGETS[@]}" -eq 0 ]] && { echo "ERR: provide at least one file" >&2; exit 2; }
if [[ "$MODE" == "apply" && -z "$IDEM_KEY" ]]; then
  echo "ERR: --apply requires --idempotency-key <KEY>" >&2
  exit 1
fi

PROCESSED=0
MODIFIED=0
SKIPPED=0
for t in "${TARGETS[@]}"; do
  process_file "$t" "$MODE"
done

jq -nc \
  --arg sv "$SCHEMA_VERSION" \
  --arg mode "$MODE" \
  --arg key "$IDEM_KEY" \
  --argjson processed "$PROCESSED" \
  --argjson modified "$MODIFIED" \
  --argjson skipped "$SKIPPED" \
  '{schema_version:$sv,mode:$mode,idempotency_key:($key|select(length>0)//null),files_processed:$processed,files_modified:$modified,files_skipped:$skipped}'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
