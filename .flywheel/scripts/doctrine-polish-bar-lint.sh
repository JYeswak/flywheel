#!/usr/bin/env bash
# doctrine-polish-bar-lint.sh — 8-dimension polish-bar rubric scorecard for
# .flywheel/doctrine/*.md files. Heuristic-based (regex/keyword + structure),
# NOT LLM-grade. Sister to docs-website skill's Polish Bar rubric.
#
# Bead: flywheel-ezz15.
# Schema: doctrine-polish-bar-lint/v1.
#
# 8 dimensions (each scored 0 or 1):
#   1. Orientation        — first 200 chars contain what/who/where markers
#   2. Motivation         — "why" + (failure mode|anti-pattern|trauma) markers
#   3. Mental model       — mermaid block OR ASCII diagram (3+ indented lines)
#   4. Narrative flow     — >=3 paragraphs, avg para length 50-300 words
#   5. Concrete example   — code block present (```)
#   6. Pitfalls           — Anti-pattern|Pitfall|Gotcha|Callout warning
#   7. Tips/tricks        — Tip|Beyond|Non-obvious|Sister
#   8. Cross-links        — markdown links to sister doctrine OR memory files
#
# Overall score: pass_count / 8.0 (0.0-1.0).
#
# Canonical-CLI-scoping triad: --help / --info / --schema / --examples / --doctor.
# Mutation discipline: --dry-run (default) / --apply-receipts (writes ledger).

set -uo pipefail

SCHEMA_VERSION="doctrine-polish-bar-lint/v1"
VERSION="0.1.0"
LEDGER_DEFAULT="${HOME}/.local/state/flywheel/doctrine-polish-bar.jsonl"

# ── canonical-cli-scoping triad ─────────────────────────────────────────
case "${1:-}" in
  -h|--help)
    cat <<'EOF'
usage: doctrine-polish-bar-lint.sh <path> [--json] [--apply-receipts] [--ledger PATH]
       doctrine-polish-bar-lint.sh --info|--schema|--examples|--doctor [--json]

8-dimension polish-bar rubric scorecard for .flywheel/doctrine/*.md files.

Modes:
  <path>            score a doctrine doc file or directory (default --dry-run)
  --info            JSON metadata
  --schema          output JSON Schema
  --examples        curated examples
  --doctor          probe substrate health (ledger writable + doctrine dir present)

Flags:
  --json            JSON output (default for scoring mode)
  --apply-receipts  append result to ~/.local/state/flywheel/doctrine-polish-bar.jsonl
  --ledger PATH     override ledger path
  --dry-run         do not write ledger (default)
EOF
    exit 0
    ;;
  --info)
    printf '{"schema_version":"%s","version":"%s","dimensions":8,"score_range":"0.0-1.0","ledger_default":"%s"}\n' \
      "$SCHEMA_VERSION" "$VERSION" "$LEDGER_DEFAULT"
    exit 0
    ;;
  --schema)
    cat <<'EOF'
{
  "schema_version": "doctrine-polish-bar-lint/v1",
  "output": {
    "type": "object",
    "properties": {
      "schema_version": {"type": "string"},
      "path": {"type": "string"},
      "size_bytes": {"type": "integer"},
      "dimensions": {
        "type": "object",
        "properties": {
          "orientation": {"type": "boolean"},
          "motivation": {"type": "boolean"},
          "mental_model": {"type": "boolean"},
          "narrative_flow": {"type": "boolean"},
          "concrete_example": {"type": "boolean"},
          "pitfalls": {"type": "boolean"},
          "tips_tricks": {"type": "boolean"},
          "cross_links": {"type": "boolean"}
        }
      },
      "pass_count": {"type": "integer", "minimum": 0, "maximum": 8},
      "overall_score": {"type": "number", "minimum": 0.0, "maximum": 1.0},
      "ts": {"type": "string", "format": "date-time"}
    }
  }
}
EOF
    exit 0
    ;;
  --examples)
    cat <<'EOF'
doctrine-polish-bar-lint.sh .flywheel/doctrine/forward-link-doctrine-doc-recipe.md
doctrine-polish-bar-lint.sh .flywheel/doctrine/ --json
doctrine-polish-bar-lint.sh .flywheel/doctrine/cluster-maintainer-pattern.md --apply-receipts
doctrine-polish-bar-lint.sh --info
doctrine-polish-bar-lint.sh --doctor
EOF
    exit 0
    ;;
  --doctor)
    doctrine_dir="$(pwd)/.flywheel/doctrine"
    doctrine_ok="missing"; [[ -d "$doctrine_dir" ]] && doctrine_ok="present"
    ledger_dir="$(dirname "$LEDGER_DEFAULT")"
    ledger_writable="no"
    if mkdir -p "$ledger_dir" 2>/dev/null && [[ -w "$ledger_dir" ]]; then
      ledger_writable="yes"
    fi
    printf '{"schema_version":"doctrine-polish-bar-lint-doctor.v1","doctrine_dir":"%s","ledger_writable":"%s","ledger_path":"%s"}\n' \
      "$doctrine_ok" "$ledger_writable" "$LEDGER_DEFAULT"
    [[ "$doctrine_ok" == "present" && "$ledger_writable" == "yes" ]] && exit 0 || exit 1
    ;;
esac

# ── arg parsing ─────────────────────────────────────────────────────────
TARGET=""
JSON_OUT=1   # default JSON for scoring
APPLY_RECEIPTS=0
LEDGER="$LEDGER_DEFAULT"
DRY_RUN=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply-receipts) APPLY_RECEIPTS=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY_RECEIPTS=0; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    --ledger=*) LEDGER="${1#--ledger=}"; shift ;;
    -*) echo "ERR: unknown flag $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "ERR: usage: doctrine-polish-bar-lint.sh <path> [flags]" >&2
  exit 2
fi

if [[ ! -e "$TARGET" ]]; then
  echo "ERR: target not found: $TARGET" >&2
  exit 2
fi

# ── score a single doctrine doc via python heredoc ─────────────────────
score_doc() {
  local doc_path="$1"
  python3 - "$doc_path" "$SCHEMA_VERSION" <<'PY'
import json, os, re, sys
from datetime import datetime, timezone

path = sys.argv[1]
schema_version = sys.argv[2]
size = os.path.getsize(path)
text = open(path, encoding="utf-8", errors="replace").read()
lower = text.lower()
first_800 = text[:800].lower()  # use first ~800 chars for "first 3 paragraphs" approximation

# 1. Orientation — what/who/where markers in first 800 chars
orient_what = bool(re.search(r"\bwhat\b|\bpurpose\b|\bsummary\b|\btl[;]?dr\b", first_800))
orient_who = bool(re.search(r"\bwho\b|\bowner\b|\boperator\b|\bworker\b|\borchestrator\b", first_800))
orient_where = bool(re.search(r"\bwhere\b|\bsubstrate\b|\bsurface\b|\bskill\b|\b\.flywheel\b|\bproject\b", first_800))
orientation = orient_what and orient_who and orient_where

# 2. Motivation — "why" + (failure mode|anti-pattern|trauma)
mot_why = bool(re.search(r"\bwhy\b", lower))
mot_failure = bool(re.search(r"failure mode|anti.?pattern|trauma|drift|regression|gotcha", lower))
motivation = mot_why and mot_failure

# 3. Mental model — mermaid block OR ASCII diagram (3+ indented lines or box-drawing)
has_mermaid = bool(re.search(r"```mermaid", text))
# ASCII diagram heuristic: 3+ consecutive lines starting with whitespace + (box-drawing chars or pipe/arrow)
ascii_diag_re = re.compile(
    r"(^[ \t]+[│║┃┌┐└┘├┤┬┴┼─━║║║║|+>→↓<\\-]{2,}.*\n){3,}",
    re.MULTILINE,
)
has_ascii_diag = bool(ascii_diag_re.search(text))
mental_model = has_mermaid or has_ascii_diag

# 4. Narrative flow — paragraphs split on blank lines; >=3 paragraphs, avg para length 50-300 words
# Strip code blocks first (don't count as prose)
text_no_code = re.sub(r"```[\s\S]*?```", "", text)
paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text_no_code) if p.strip() and not p.strip().startswith("#")]
para_word_counts = [len(re.findall(r"\b\w+\b", p)) for p in paragraphs]
# filter out very short paras (list items, frontmatter, etc.) - keep paras >= 30 words
prose_paras = [w for w in para_word_counts if w >= 30]
if prose_paras:
    avg_para = sum(prose_paras) / len(prose_paras)
    narrative_flow = (len(prose_paras) >= 3 and 50 <= avg_para <= 400)
else:
    narrative_flow = False

# 5. Concrete example — code block (``` ... ```) present
concrete_example = bool(re.search(r"```", text))

# 6. Pitfalls — Anti-pattern | Pitfall | Gotcha | Callout warning
pitfalls = bool(re.search(r"anti.?pattern|pitfall|gotcha|<callout\s+type=[\"']?warning", lower))

# 7. Tips/tricks — Tip | Beyond | Non-obvious | Sister
tips_tricks = bool(re.search(r"\btip\b|\bbeyond\b|non.?obvious|\bsister\b|\bharvest\b", lower))

# 8. Cross-links — markdown link to .flywheel/doctrine/*.md OR memory files (feedback_*.md / project_*.md / reference_*.md)
cross_doctrine = bool(re.search(r"\.flywheel/doctrine/[^)\s]+\.md", text))
cross_memory = bool(re.search(r"\b(feedback_|project_|reference_)[a-z0-9_]+\.md", text))
cross_links = cross_doctrine or cross_memory

dims = {
    "orientation": orientation,
    "motivation": motivation,
    "mental_model": mental_model,
    "narrative_flow": narrative_flow,
    "concrete_example": concrete_example,
    "pitfalls": pitfalls,
    "tips_tricks": tips_tricks,
    "cross_links": cross_links,
}
pass_count = sum(1 for v in dims.values() if v)
overall = pass_count / 8.0

result = {
    "schema_version": schema_version,
    "path": path,
    "size_bytes": size,
    "dimensions": dims,
    "pass_count": pass_count,
    "overall_score": round(overall, 3),
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
print(json.dumps(result))
PY
}

# ── score one or many ──────────────────────────────────────────────────
declare -a RESULTS=()
if [[ -d "$TARGET" ]]; then
  while IFS= read -r doc; do
    [[ -z "$doc" ]] && continue
    [[ "$doc" == */README.md ]] && continue  # skip dir index
    RESULTS+=("$(score_doc "$doc")")
  done < <(find "$TARGET" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
else
  RESULTS+=("$(score_doc "$TARGET")")
fi

# ── apply-receipts: append to ledger ───────────────────────────────────
if [[ "$APPLY_RECEIPTS" -eq 1 ]]; then
  mkdir -p "$(dirname "$LEDGER")"
  for row in "${RESULTS[@]}"; do
    printf '%s\n' "$row" >> "$LEDGER"
  done
fi

# ── output ─────────────────────────────────────────────────────────────
if [[ ${#RESULTS[@]} -eq 1 ]]; then
  echo "${RESULTS[0]}"
else
  # Multi-file: emit as JSON array
  printf '['
  for i in "${!RESULTS[@]}"; do
    [[ $i -gt 0 ]] && printf ','
    printf '%s' "${RESULTS[$i]}"
  done
  printf ']\n'
fi

exit 0
