#!/usr/bin/env bash
# flywheel-cli-surface: true
# scaffold-doc-frontmatter.sh — add YAML frontmatter to .md files idempotently.
#
# Pairs with file-rag-discipline-lint.sh (auto-fix for F1). Infers:
#   title    from H1 or filename
#   type     from path (audit-spec/doctrine/plan/report/handoff/evidence/general)
#   created  from git first-commit-date or file mtime
#   bead     from path pattern (flywheel-<id>)
#
# Idempotent: skips files that already have frontmatter.
# Mutating modes require --apply --idempotency-key <KEY>.
#
# Bead: {bead-id}. Spec: .flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md.
set -euo pipefail

SCHEMA_VERSION="scaffold-doc-frontmatter/v1"
VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ "$(basename "$(dirname "$SCRIPT_DIR")")" == ".flywheel" ]]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
fi
RUN_LOG="${RUN_LOG:-$REPO_ROOT/.flywheel/state/scaffold-doc-frontmatter-runs.jsonl}"

usage() {
  cat <<'USAGE'
scaffold-doc-frontmatter.sh — add YAML frontmatter to .md files

USAGE:
  scaffold-doc-frontmatter.sh <file>                               # dry-run preview
  scaffold-doc-frontmatter.sh <file> --apply --idempotency-key K   # apply
  scaffold-doc-frontmatter.sh <dir> --recursive                    # dir dry-run
  scaffold-doc-frontmatter.sh <dir> --recursive --apply --idempotency-key K

INTROSPECTION:
  --info | --schema | --examples | --doctor | --help

EXIT CODES:
  0 ok | 1 idem-key required for --apply | 2 bad args | 3 not found
USAGE
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" '{
    schema_version:$sv, success:true, mode:"info",
    name:"scaffold-doc-frontmatter", version:$v,
    inferred_fields:["title","type","created","bead","frontmatter_source"],
    type_path_map:{
      ".flywheel/doctrine/":"doctrine",
      ".flywheel/PLANS/":"plan",
      ".flywheel/audit/":"audit-spec",
      ".flywheel/reports/":"report",
      ".flywheel/handoffs/":"handoff",
      ".flywheel/evidence/":"evidence",
      ".flywheel/journal/":"journey-entry",
      ".flywheel/research/":"research"
    },
    idempotency_required:true,
    apply_default:false
  }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    schema_version:$sv,
    title:"scaffold-doc-frontmatter run row",
    type:"object",
    required:["schema_version","ts","mode","files_processed","files_modified","files_skipped"],
    properties:{
      schema_version:{const:$sv},
      ts:{type:"string",format:"date-time"},
      mode:{enum:["dry-run","apply"]},
      idempotency_key:{type:["string","null"]},
      files_processed:{type:"integer",minimum:0},
      files_modified:{type:"integer",minimum:0},
      files_skipped:{type:"integer",minimum:0},
      target:{type:"string"}
    }
  }'
}

emit_examples() {
  cat <<'EX'
scaffold-doc-frontmatter.sh .flywheel/doctrine/filesystem-as-rag.md
scaffold-doc-frontmatter.sh .flywheel/doctrine/ --recursive
scaffold-doc-frontmatter.sh .flywheel/doctrine/ --recursive --apply --idempotency-key fs-rag-backfill-2026-05-10
EX
}

emit_doctor() {
  local jq_ok=true git_ok=true
  command -v jq >/dev/null 2>&1 || jq_ok=false
  command -v git >/dev/null 2>&1 || git_ok=false
  jq -nc --arg sv "$SCHEMA_VERSION" --argjson jq "$jq_ok" --argjson git "$git_ok" '{
    schema_version:($sv | sub("/v1$"; ".doctor.v1")),
    status:(if $jq and $git then "pass" else "warn" end),
    jq_present:$jq, git_present:$git
  }'
}

# ---------- frontmatter detection ----------
has_frontmatter() {
  local f="$1"
  [[ -r "$f" ]] || return 1
  head -1 "$f" | grep -qE '^---[[:space:]]*$' || return 1
  awk 'NR>1 && /^---[[:space:]]*$/ {print NR; exit} NR>50 {exit}' "$f" | grep -qE '^[0-9]+$'
}

# ---------- inference ----------
infer_type() {
  local f="$1"
  case "$f" in
    *.flywheel/doctrine/*) echo "doctrine" ;;
    *.flywheel/PLANS/*)    echo "plan" ;;
    *.flywheel/audit/*)    [[ "$f" == */apply-spec.md ]] && echo "apply-spec" || echo "audit" ;;
    *.flywheel/reports/*)  echo "report" ;;
    *.flywheel/handoffs/*) echo "handoff" ;;
    *.flywheel/evidence/*) echo "evidence" ;;
    *.flywheel/journal/*)  echo "journey-entry" ;;
    *.flywheel/research/*) echo "research" ;;
    *.flywheel/rules/*)    echo "rule" ;;
    *)                     echo "general" ;;
  esac
}

infer_bead() {
  local f="$1"
  if [[ "$f" =~ flywheel-([a-z0-9]+) ]]; then
    echo "flywheel-${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

infer_title() {
  local f="$1"
  # Try first H1
  local h1
  h1=$(grep -m1 -E '^# [^#]' "$f" 2>/dev/null | sed 's/^# //')
  if [[ -n "$h1" ]]; then
    echo "$h1"
    return
  fi
  # Fallback: filename without extension, kebab → spaces
  local base
  base=$(basename "$f" .md)
  echo "$base" | tr '_' '-' | tr '-' ' ' | sed 's/.*/\u&/'
}

infer_created() {
  local f="$1"
  # Try git first-commit date
  local date
  date=$(git -C "$REPO_ROOT" log --diff-filter=A --follow --format=%aI -- "$f" 2>/dev/null | tail -1)
  if [[ -n "$date" ]]; then
    echo "${date%T*}"
    return
  fi
  # Fallback: file mtime
  if stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null; then
    return
  fi
  date -u +%Y-%m-%d
}

# ---------- frontmatter generation ----------
gen_frontmatter() {
  local f="$1"
  local title type created bead
  title=$(infer_title "$f")
  type=$(infer_type "$f")
  created=$(infer_created "$f")
  bead=$(infer_bead "$f")

  # Escape colons + quotes in title for YAML safety
  title=$(echo "$title" | sed 's/"/\\"/g')

  printf -- '---\n'
  printf 'title: "%s"\n' "$title"
  printf 'type: %s\n' "$type"
  printf 'created: %s\n' "$created"
  if [[ -n "$bead" ]]; then
    printf 'bead: %s\n' "$bead"
  fi
  printf 'frontmatter_source: scaffold-doc-frontmatter\n'
  printf -- '---\n'
}

# ---------- apply / dry-run ----------
process_file() {
  local f="$1" mode="$2"
  local rel="${f#$REPO_ROOT/}"

  if has_frontmatter "$f"; then
    printf 'SKIP %s (already has frontmatter)\n' "$rel"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  PROCESSED=$((PROCESSED + 1))

  local fm
  fm=$(gen_frontmatter "$f")

  if [[ "$mode" == "dry-run" ]]; then
    printf 'WOULD-MODIFY %s\n' "$rel"
    printf '%s\n' "$fm" | sed 's/^/  + /'
    return 0
  fi

  # apply: prepend frontmatter + blank line + original content
  local tmp
  tmp=$(mktemp)
  {
    printf '%s\n\n' "$fm"
    cat "$f"
  } > "$tmp"
  mv "$tmp" "$f"
  printf 'MODIFIED %s\n' "$rel"
  MODIFIED=$((MODIFIED + 1))
}

# ---------- main ----------
MODE=dry-run
RECURSIVE=false
IDEM_KEY=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --doctor|--health) emit_doctor; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --apply) MODE=apply; shift ;;
    --dry-run) MODE=dry-run; shift ;;
    --recursive|-r) RECURSIVE=true; shift ;;
    --idempotency-key) IDEM_KEY="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "ERR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "ERR: provide a path" >&2; exit 2; }
[[ -e "$TARGET" ]] || { echo "ERR: not found: $TARGET" >&2; exit 3; }

if [[ "$MODE" == "apply" && -z "$IDEM_KEY" ]]; then
  echo "ERR: --apply requires --idempotency-key <KEY>" >&2
  exit 1
fi

PROCESSED=0
MODIFIED=0
SKIPPED=0

if [[ -f "$TARGET" ]]; then
  process_file "$TARGET" "$MODE"
elif [[ -d "$TARGET" ]]; then
  if ! $RECURSIVE && [[ "$TARGET" != *.md ]]; then
    echo "WARN: $TARGET is a directory; pass --recursive (-r) to walk it" >&2
    exit 2
  fi
  while IFS= read -r f; do
    process_file "$f" "$MODE"
  done < <(find "$TARGET" -type f -name '*.md' 2>/dev/null | grep -vE '/(node_modules|venv|\.git|target/)/' | sort)
fi

# Audit row
mkdir -p "$(dirname "$RUN_LOG")"
ROW=$(jq -nc \
  --arg sv "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg mode "$MODE" \
  --arg key "$IDEM_KEY" \
  --argjson processed "$PROCESSED" \
  --argjson modified "$MODIFIED" \
  --argjson skipped "$SKIPPED" \
  --arg target "$TARGET" \
  '{schema_version:$sv,ts:$ts,mode:$mode,idempotency_key:($key|select(length>0)//null),files_processed:$processed,files_modified:$modified,files_skipped:$skipped,target:$target}')
printf '%s\n' "$ROW" >> "$RUN_LOG"
printf '\n%s\n' "$ROW"
