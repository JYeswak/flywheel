#!/usr/bin/env bash
# flywheel-cli-surface: true
# file-rag-discipline-lint.sh — static linter for filesystem-as-RAG discipline.
#
# Implements the 8 lint rules (F1-F8) of `.flywheel/doctrine/filesystem-as-rag.md`.
# Pairs with scaffold-doc-frontmatter.sh (auto-fix for F1) and
# file-rag-discipline-pre-commit.sh (deny-on-error gate).
#
# Bead: flywheel-s8tdd. Spec: .flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md.
set -euo pipefail

SCHEMA_VERSION="file-rag-discipline-lint/v1"
VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

usage() {
  cat <<'USAGE'
file-rag-discipline-lint.sh — static linter for filesystem-as-RAG discipline

USAGE:
  file-rag-discipline-lint.sh <path>                    # one .md or dir
  file-rag-discipline-lint.sh --scan-all [--root DIR]   # whole repo
  file-rag-discipline-lint.sh <path> --rule F1,F4       # filter rules
  file-rag-discipline-lint.sh --scan-all --json         # baseline output
  file-rag-discipline-lint.sh --backfill-frontmatter <path>   # auto-fix F1

INTROSPECTION:
  --info | --schema | --examples | --doctor | --health | --help

RULES:
  F1 .md frontmatter present (or canonical-exempt)        error
  F2 dirs under audit/PLANS/doctrine have README/canonical warn
  F3 docs >200 lines have ## H2 anchors per ~80 lines     warn
  F4 no .bak.* committed files                            error
  F5 doc filenames are kebab-case                         warn
  F6 dated filenames use YYYY-MM-DD ISO format            warn
  F7 apply-spec.md has canonical H2 sections              warn
  F8 long docs (>500 lines) have a TOC near top           info

EXIT CODES:
  0 clean | 1 violations | 2 errors | 3 file not found
USAGE
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" '{
    schema_version:$sv, success:true, mode:"info",
    name:"file-rag-discipline-lint", version:$v,
    rules:[
      {id:"F1",label:"frontmatter-required",severity:"error"},
      {id:"F2",label:"dir-readme-or-canonical",severity:"warn"},
      {id:"F3",label:"section-anchors-spacing",severity:"warn"},
      {id:"F4",label:"no-bak-files",severity:"error"},
      {id:"F5",label:"kebab-case-filenames",severity:"warn"},
      {id:"F6",label:"dated-iso8601",severity:"warn"},
      {id:"F7",label:"apply-spec-canonical-sections",severity:"warn"},
      {id:"F8",label:"long-doc-toc",severity:"info"}
    ],
    exempt_files:["README.md","INCIDENTS.md","AGENTS.md","CHANGELOG.md","CONTRIBUTING.md","LICENSE.md"]
  }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    schema_version:$sv,
    title:"file-rag-discipline-lint output",
    type:"object",
    required:["schema_version","status","files_scanned","violations"],
    properties:{
      schema_version:{const:$sv},
      status:{enum:["clean","violations","error"]},
      files_scanned:{type:"integer",minimum:0},
      violations:{type:"array",items:{type:"object",
        required:["file","rule","label","severity","message"],
        properties:{
          file:{type:"string"},
          line:{type:"integer",minimum:0},
          rule:{enum:["F1","F2","F3","F4","F5","F6","F7","F8"]},
          label:{type:"string"},
          severity:{enum:["error","warn","info"]},
          message:{type:"string"}
        }}}
    }
  }'
}

emit_examples() {
  cat <<'EX'
file-rag-discipline-lint.sh .flywheel/doctrine/filesystem-as-rag.md
file-rag-discipline-lint.sh --scan-all
file-rag-discipline-lint.sh --scan-all --json > baseline.json
file-rag-discipline-lint.sh .flywheel/audit/ --rule F1,F2
file-rag-discipline-lint.sh --backfill-frontmatter .flywheel/doctrine/
EX
}

emit_doctor() {
  local jq_ok=true
  command -v jq >/dev/null 2>&1 || jq_ok=false
  jq -nc --arg sv "$SCHEMA_VERSION" --argjson jq "$jq_ok" '{
    schema_version:($sv | sub("/v1$"; ".doctor.v1")),
    status:(if $jq then "pass" else "warn" end),
    jq_present:$jq
  }'
}

# ---------- exempt files ----------
EXEMPT_BASENAMES="README.md INCIDENTS.md AGENTS.md AGENTS-CANONICAL.md CHANGELOG.md CONTRIBUTING.md LICENSE.md MISSION.md STATE.md GOAL.md WORK.md PLAN.md TODO.md NOTES.md"

is_exempt() {
  local base
  base="$(basename "$1")"
  for ex in $EXEMPT_BASENAMES; do
    [[ "$base" == "$ex" ]] && return 0
  done
  return 1
}

# ---------- rule machinery ----------
_violations=()

emit_v() {
  # args: file line rule label severity message
  _violations+=("$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"$'\t'"$5"$'\t'"$6")
}

_rule_enabled() {
  local rule="$1" filter="${2:-}"
  [[ -z "$filter" ]] && return 0
  [[ ",$filter," == *",$rule,"* ]]
}

# Return 0 if file starts with valid YAML frontmatter
has_frontmatter() {
  local f="$1"
  [[ -r "$f" ]] || return 1
  head -1 "$f" | grep -qE '^---[[:space:]]*$' || return 1
  # require closing --- within first 50 lines
  awk 'NR>1 && /^---[[:space:]]*$/ {print NR; exit} NR>50 {exit}' "$f" | grep -qE '^[0-9]+$'
}

# Lint a single .md file
lint_md() {
  local f="$1" rules="$2"
  local lc base dir
  lc=$(wc -l <"$f" | tr -d ' ')
  base=$(basename "$f")
  dir=$(dirname "$f")

  # F1 — frontmatter required (unless exempt)
  if _rule_enabled F1 "$rules"; then
    if ! is_exempt "$f"; then
      if ! has_frontmatter "$f"; then
        emit_v "$f" 1 F1 frontmatter-required error "missing YAML frontmatter (---title/type/created at top)"
      fi
    fi
  fi

  # F3 — section anchors for long docs. Per filesystem-as-rag.md Rule 3,
  # long sections may use either ## H2 headers OR <!-- AGENT-ANCHOR: ... -->
  # comment markers. Count both toward the spacing requirement.
  if _rule_enabled F3 "$rules"; then
    if [[ "$lc" -gt 200 ]]; then
      local h2_count anchor_count total_anchors
      h2_count=$(grep -c '^## ' "$f" || true)
      anchor_count=$(grep -c '^<!-- AGENT-ANCHOR:' "$f" || true)
      total_anchors=$((h2_count + anchor_count))
      local expected_min=$(( lc / 80 ))
      [[ "$expected_min" -lt 1 ]] && expected_min=1
      if [[ "$total_anchors" -lt "$expected_min" ]]; then
        emit_v "$f" 1 F3 section-anchors-spacing warn "doc has $lc lines but only $total_anchors anchors (H2=$h2_count + AGENT-ANCHOR=$anchor_count); need ~$expected_min for ~80-line spacing"
      fi
    fi
  fi

  # F5 — kebab-case filenames (warn). Allow snake_case under tests/ + receipts/.
  if _rule_enabled F5 "$rules"; then
    if [[ "$f" == *"/tests/"* || "$f" == *"/receipts/"* || "$f" == *"/fixtures/"* || "$f" == *"/audit/"* ]]; then
      :
    elif [[ "$base" =~ [[:space:]] ]] || [[ "$base" =~ [A-Z] && "$base" != "README.md" && ! "$base" =~ ^[A-Z]+\.md$ ]]; then
      # Skip ALL-CAPS exempt-style and README.md
      emit_v "$f" 1 F5 kebab-case-filenames warn "filename '$base' not kebab-case (no spaces, lowercase)"
    fi
  fi

  # F6 — ISO date format YYYY-MM-DD if filename has a date-looking token
  if _rule_enabled F6 "$rules"; then
    # Look for any YYYY-MM-DD or YYYYMMDD or YYYY_MM_DD in basename
    if [[ "$base" =~ ([0-9]{4})[-_]?([0-9]{2})[-_]?([0-9]{2}) ]]; then
      local raw="${BASH_REMATCH[0]}"
      # canonical form is YYYY-MM-DD or YYYYMMDDTHHMMSSZ. Flag YYYY_MM_DD.
      if [[ "$raw" =~ _ ]]; then
        emit_v "$f" 1 F6 dated-iso8601 warn "filename uses '_' in date '$raw'; canonical form is YYYY-MM-DD"
      fi
    fi
  fi

  # F7 — apply-spec.md canonical H2 sections
  if _rule_enabled F7 "$rules"; then
    if [[ "$base" == "apply-spec.md" ]]; then
      local missing=()
      grep -qE '^## (Goal|Scope)' "$f" || missing+=("Goal/Scope")
      grep -qE '^## (Boundary|Out of scope)' "$f" || missing+=("Boundary")
      grep -qE '^## (Acceptance gate|Success criteria|Acceptance)' "$f" || missing+=("Acceptance")
      if [[ "${#missing[@]}" -gt 0 ]]; then
        emit_v "$f" 1 F7 apply-spec-canonical-sections warn "apply-spec.md missing H2 sections: ${missing[*]}"
      fi
    fi
  fi

  # F8 — long docs (>500 lines) need a TOC near top
  if _rule_enabled F8 "$rules"; then
    if [[ "$lc" -gt 500 ]]; then
      # crude TOC heuristic: any of "Table of Contents", "## TOC", "## Contents", or
      # multiple consecutive list lines with internal anchors in first 50 lines
      if ! head -50 "$f" | grep -qiE 'table of contents|^## (toc|contents)|\[.*\]\(#'; then
        emit_v "$f" 1 F8 long-doc-toc info "doc has $lc lines but no visible TOC in first 50 lines"
      fi
    fi
  fi
}

# Lint a directory (F2 + F4 + recurse)
lint_dir() {
  local d="$1" rules="$2"

  # F2 — dirs under audit/PLANS/doctrine need README or canonical content
  if _rule_enabled F2 "$rules"; then
    if [[ "$d" =~ /(audit|PLANS|doctrine)/[^/]+/?$ ]]; then
      local has_canonical=false
      for marker in README.md apply-spec.md evidence.md STATE.json; do
        [[ -f "$d/$marker" ]] && has_canonical=true
      done
      if ! $has_canonical; then
        emit_v "$d" 0 F2 dir-readme-or-canonical warn "directory under audit/PLANS/doctrine without README.md or canonical content file"
      fi
    fi
  fi

  # F4 — no COMMITTED .bak files. Filter to git-tracked only so
  # peer-pane working-tree scratch (e.g., *.bak.scaffold-*) doesn't
  # surface as violations. Untracked .bak files are filesystem-only
  # and covered by .gitignore patterns.
  if _rule_enabled F4 "$rules"; then
    while IFS= read -r bakfile; do
      [[ -z "$bakfile" ]] && continue
      # Filter to git-tracked. If git not available, repo not initialized,
      # OR FLYWHEEL_F4_NO_GIT_FILTER=1 (test mode), fall back to filesystem
      # detection (legacy behavior).
      if [[ "${FLYWHEEL_F4_NO_GIT_FILTER:-0}" != "1" ]] && \
         command -v git >/dev/null 2>&1 && \
         git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        local rel="${bakfile#$REPO_ROOT/}"
        # If bakfile is outside REPO_ROOT (e.g., test fixture in /tmp),
        # ${bakfile#$REPO_ROOT/} returns the unchanged path. Detect that
        # via leading slash and treat as "tracked" semantics for the test.
        if [[ "$rel" == /* ]]; then
          :  # outside repo root — flag (test-fixture friendly)
        elif ! git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
          continue   # untracked inside repo — skip
        fi
      fi
      emit_v "$bakfile" 0 F4 no-bak-files error "committed backup file ($bakfile); use git history instead"
    done < <(find "$d" -maxdepth 6 -type f \( -name '*.bak' -o -name '*.bak.*' \) 2>/dev/null)
  fi
}

# Recursively walk + lint
walk_lint() {
  local target="$1" rules="$2"
  if [[ -f "$target" ]]; then
    [[ "$target" == *.md ]] && lint_md "$target" "$rules"
    return 0
  fi
  if [[ -d "$target" ]]; then
    lint_dir "$target" "$rules"
    while IFS= read -r f; do
      lint_md "$f" "$rules"
    done < <(find "$target" -type f -name '*.md' 2>/dev/null | grep -vE '/(node_modules|venv|\.git|target/)/' || true)
    while IFS= read -r d; do
      lint_dir "$d" "$rules"
    done < <(find "$target" -mindepth 1 -type d 2>/dev/null | grep -vE '/(node_modules|venv|\.git|target/)/' || true)
  fi
}

# ---------- main ----------
MODE=lint
JSON=false
SCAN_ALL=false
RULE_FILTER=""
ROOT_DIR="$REPO_ROOT"
TARGET=""
BACKFILL_TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --doctor|--health) emit_doctor; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --json) JSON=true; shift ;;
    --scan-all) SCAN_ALL=true; shift ;;
    --rule) RULE_FILTER="$2"; shift 2 ;;
    --root) ROOT_DIR="$2"; shift 2 ;;
    --backfill-frontmatter) BACKFILL_TARGET="$2"; MODE=backfill; shift 2 ;;
    --) shift; break ;;
    -*) echo "ERR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ "$MODE" == "backfill" ]]; then
  # Delegate to scaffolder
  exec "$SCRIPT_DIR/scaffold-doc-frontmatter.sh" --recursive --apply --idempotency-key "rag-lint-backfill-$(date -u +%Y%m%d)" "$BACKFILL_TARGET"
fi

declare -a TARGETS=()
if $SCAN_ALL; then
  TARGETS+=("$ROOT_DIR/.flywheel")
elif [[ -n "$TARGET" ]]; then
  TARGETS+=("$TARGET")
else
  echo "ERR: provide a path or --scan-all" >&2
  exit 2
fi

SCANNED=0
for t in "${TARGETS[@]}"; do
  if [[ ! -e "$t" ]]; then
    echo "ERR: not found: $t" >&2
    exit 3
  fi
  walk_lint "$t" "$RULE_FILTER"
  if [[ -f "$t" ]]; then
    SCANNED=$((SCANNED + 1))
  else
    md_count=$(find "$t" -type f -name '*.md' 2>/dev/null | grep -vE '/(node_modules|venv|\.git|target/)/' | wc -l | tr -d ' ')
    SCANNED=$((SCANNED + md_count))
  fi
done

VC="${#_violations[@]}"

if $JSON; then
  status="clean"
  [[ "$VC" -gt 0 ]] && status="violations"
  jq_input=""
  for row in "${_violations[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS=$'\t' read -r f line rule label severity message <<<"$row"
    jq_input+=$(jq -nc \
      --arg file "$f" \
      --argjson line "$line" \
      --arg rule "$rule" \
      --arg label "$label" \
      --arg severity "$severity" \
      --arg message "$message" \
      '{file:$file, line:$line, rule:$rule, label:$label, severity:$severity, message:$message}')
    jq_input+=$'\n'
  done
  if [[ -z "$jq_input" ]]; then
    violations_json="[]"
  else
    violations_json=$(echo -n "$jq_input" | jq -sc '.')
  fi
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg status "$status" \
    --argjson scanned "$SCANNED" \
    --argjson violations "$violations_json" \
    '{schema_version:$sv, status:$status, files_scanned:$scanned, violations:$violations}'
else
  for row in "${_violations[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS=$'\t' read -r f line rule label severity message <<<"$row"
    printf '%s:%s: %s [%s,%s]: %s\n' "$f" "$line" "$rule" "$label" "$severity" "$message"
  done
fi

# Exit code: 1 if any violation; 0 if clean. Errors are also rc=1
# (consistent with canonical-cli-lint).
[[ "$VC" -eq 0 ]] && exit 0
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
