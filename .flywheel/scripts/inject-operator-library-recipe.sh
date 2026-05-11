#!/usr/bin/env bash
# inject-operator-library-recipe.sh — auto-inject OPERATOR LIBRARY RECIPE BLOCK
# into dispatch packets for doc-authoring beads ([doctrine], [skill-md],
# [skill-promotion], [client-doc-*], [readme]).
#
# Sister to inject-forward-link-recipe.sh (flywheel-pmg3c N=4).
# Source bead: flywheel-vbk3h.
# Operator library source: ~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md
# Doctrine: .flywheel/doctrine/operator-library-recipe.md
#
# Behavior:
# 1. Read dispatch body from arg 1 (or - for stdin)
# 2. Detect doc-authoring title classes (4 supported)
# 3. If detected: insert OPERATOR LIBRARY RECIPE BLOCK before METADATA with
#    the per-class operator pipeline
# 4. Otherwise: pass through unchanged

set -euo pipefail

BODY_FILE="${1:-}"
TASK_ID="${2:-unknown}"
REPO_PATH="${3:-${PWD:-}}"

# ── canonical-cli-scoping triad ─────────────────────────────────────────
if [[ "$BODY_FILE" == "--help" || "$BODY_FILE" == "-h" ]]; then
  cat <<'EOF'
Usage: inject-operator-library-recipe.sh <task-body-file> [task-id] [repo-path]

Auto-injects OPERATOR LIBRARY RECIPE BLOCK into dispatch packets when
the bead title matches a doc-authoring class. Workers no longer need
to re-derive the per-class operator pipeline.

Supported title classes + operator pipelines:
  [doctrine] / [gap-memory-without-cross-link]  → ★ ORIENT → ✦ MOTIVATE → ◐ MENTAL-MODEL → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK
  [skill-md] / [skill-promotion]                → ★ ORIENT → ✦ MOTIVATE → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK → ⌘ REDUCE
  [client-doc-*]                                → ★ ORIENT → ⬡ EXEMPLIFY → ⚠ WARN → ⇄ CROSS-LINK
  [readme]                                      → ★ ORIENT → ✦ MOTIVATE → ⬡ EXEMPLIFY → ⌘ REDUCE

Pattern source: flywheel-vbk3h (P2 operator-library-auto-route).
Doctrine source: .flywheel/doctrine/operator-library-recipe.md.

Env vars:
  OPERATOR_LIBRARY_RECIPE_DISABLED=1  pass through unchanged (no injection)
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "--info" ]]; then
  printf 'inject-operator-library-recipe: dispatch-packet auto-injector for doc-authoring classes; 4 title-class pipelines; source flywheel-vbk3h; sister to inject-forward-link-recipe\n'
  exit 0
fi

if [[ "$BODY_FILE" == "--schema" ]]; then
  printf '%s\n' '{"schema_version":"inject-operator-library-recipe.v1","output":"markdown","triggers":["[doctrine]","[gap-memory-without-cross-link]","[skill-md]","[skill-promotion]","[client-doc-","[readme]"],"pipelines":4,"doctrine_source":".flywheel/doctrine/operator-library-recipe.md"}'
  exit 0
fi

if [[ "$BODY_FILE" == "--examples" ]]; then
  cat <<'EOF'
inject-operator-library-recipe.sh /tmp/task-body.md flywheel-vbk3h
inject-operator-library-recipe.sh - flywheel-fixture < dispatch-body.md
OPERATOR_LIBRARY_RECIPE_DISABLED=1 inject-operator-library-recipe.sh /tmp/body.md fixture
inject-operator-library-recipe.sh --info
inject-operator-library-recipe.sh --schema
inject-operator-library-recipe.sh --doctor
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "--doctor" ]]; then
  DOCTRINE_PATH="${REPO_PATH%/}/.flywheel/doctrine/operator-library-recipe.md"
  BUILDER_PATH="${REPO_PATH%/}/.flywheel/scripts/build-dispatch-packet.sh"
  SOURCE_PATH="$HOME/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md"
  doctrine_ok="missing"; [[ -f "$DOCTRINE_PATH" ]] && doctrine_ok="present"
  builder_wired="not_wired"
  if [[ -f "$BUILDER_PATH" ]] && grep -q 'inject-operator-library-recipe' "$BUILDER_PATH" 2>/dev/null; then
    builder_wired="wired"
  fi
  source_ok="missing"; [[ -f "$SOURCE_PATH" ]] && source_ok="present"
  printf '{"schema_version":"inject-operator-library-recipe-doctor.v1","doctrine_doc":"%s","builder_wired":"%s","source_operator_library":"%s","repo_path":"%s"}\n' \
    "$doctrine_ok" "$builder_wired" "$source_ok" "$REPO_PATH"
  [[ "$doctrine_ok" == "present" && "$builder_wired" == "wired" && "$source_ok" == "present" ]] && exit 0 || exit 1
fi

# ── stdin handling ──────────────────────────────────────────────────────
TMP_BODY=""
if [[ "$BODY_FILE" == "-" || "$BODY_FILE" == "/dev/stdin" ]]; then
  TMP_BODY="$(mktemp "${TMPDIR:-/tmp}/operator-library-recipe-stdin.XXXXXX")"
  trap '[[ -z "$TMP_BODY" ]] || rm -f "$TMP_BODY"' EXIT
  cat >"$TMP_BODY"
  BODY_FILE="$TMP_BODY"
fi

if [[ -z "$BODY_FILE" || ! -r "$BODY_FILE" ]]; then
  echo "usage: inject-operator-library-recipe.sh <task-body-file> [task-id] [repo-path]" >&2
  exit 2
fi

# ── disabled passthrough ────────────────────────────────────────────────
if [[ "${OPERATOR_LIBRARY_RECIPE_DISABLED:-0}" == "1" ]]; then
  cat "$BODY_FILE"
  exit 0
fi

# ── trigger detection ───────────────────────────────────────────────────
# Determine which pipeline applies based on bead title.
PIPELINE=""
PIPELINE_NAME=""
if grep -qE '\[(doctrine|gap-memory-without-cross-link)\]' "$BODY_FILE"; then
  PIPELINE="orient_motivate_mental_exemplify_warn_crosslink"
  PIPELINE_NAME="doctrine"
elif grep -qE '\[(skill-md|skill-promotion)' "$BODY_FILE"; then
  PIPELINE="orient_motivate_exemplify_warn_crosslink_reduce"
  PIPELINE_NAME="skill-md"
elif grep -qE '\[client-doc-' "$BODY_FILE"; then
  PIPELINE="orient_exemplify_warn_crosslink"
  PIPELINE_NAME="client-doc"
elif grep -qE '\[readme\]' "$BODY_FILE"; then
  PIPELINE="orient_motivate_exemplify_reduce"
  PIPELINE_NAME="readme"
else
  cat "$BODY_FILE"
  exit 0
fi

# ── injection ───────────────────────────────────────────────────────────
RECIPE_FILE="$(mktemp "${TMPDIR:-/tmp}/operator-library-recipe.XXXXXX")"
trap '[[ -z "${RECIPE_FILE:-}" ]] || rm -f "$RECIPE_FILE"; [[ -z "${TMP_BODY:-}" ]] || rm -f "$TMP_BODY"' EXIT

# Synthesize per-class operator pipeline section
{
  echo "## OPERATOR LIBRARY RECIPE BLOCK"
  echo ""
  echo "Auto-injected for doc-authoring bead (title class: \`$PIPELINE_NAME\`) per"
  echo "\`.flywheel/scripts/inject-operator-library-recipe.sh\`. Canonical doctrine:"
  echo "\`.flywheel/doctrine/operator-library-recipe.md\`. Source library:"
  echo "\`~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md\`."
  echo ""
  echo "### Pipeline for this class"
  echo ""
  case "$PIPELINE_NAME" in
    doctrine)
      cat <<'PIPE'
**[doctrine] / [gap-memory-without-cross-link]:**

1. **★ ORIENT** — first 3 paragraphs: state what this doctrine is, who follows it, where it applies. Avoid "This document describes…".
2. **✦ MOTIVATE** — why does this doctrine exist? Name the trauma class, the failure mode it prevents, the cost of bypass.
3. **◐ MENTAL-MODEL** — diagram or table showing how the doctrine relates to sister discipline (e.g., 3-class taxonomy, recipe family, N-strike threshold).
4. **⬡ EXEMPLIFY** — copy-pasteable runnable example: actual command, actual bead-id, actual file path the operator can reproduce.
5. **⚠ WARN** — anti-patterns / pitfalls / gotchas: 3+ "do NOT" negatives that bound the doctrine's scope.
6. **⇄ CROSS-LINK** — links to sister doctrine docs + source memory + bead-id + N-strike precedent table.
PIPE
      ;;
    skill-md)
      cat <<'PIPE'
**[skill-md] / [skill-promotion]:**

1. **★ ORIENT** — first 3 paragraphs: skill purpose, when it fires, who invokes it.
2. **✦ MOTIVATE** — why this skill exists (cost paid in prior session that motivates the skill).
3. **⬡ EXEMPLIFY** — copy-pasteable runnable: actual invocation, expected envelope shape, exit codes.
4. **⚠ WARN** — anti-patterns: 3+ "do NOT" negatives.
5. **⇄ CROSS-LINK** — sister skills + canonical-cli triad references + supporting scripts.
6. **⌘ REDUCE** — cut by 30%+: trim duplicates with references/*.md, move long docs to references/, keep SKILL.md ≤500 lines.
PIPE
      ;;
    client-doc)
      cat <<'PIPE'
**[client-doc-*]:**

1. **★ ORIENT** — first 3 paragraphs: client-facing context (who reads this, what they should do next).
2. **⬡ EXEMPLIFY** — concrete copy-pasteable examples preferred over abstract description.
3. **⚠ WARN** — gotchas client operators must avoid (failure modes specific to client environment).
4. **⇄ CROSS-LINK** — client-facing related docs + internal source-of-truth pointers (one-way; internal links not exposed to client).
PIPE
      ;;
    readme)
      cat <<'PIPE'
**[readme]:**

1. **★ ORIENT** — title + one-line description + concrete what-it-does in first 3 paragraphs.
2. **✦ MOTIVATE** — why this project exists (problem solved); avoid "This project is…".
3. **⬡ EXEMPLIFY** — Quick Start: ≤5 copy-pasteable commands that prove the README works.
4. **⌘ REDUCE** — cut by 30%+: anything that isn't directly actionable goes to docs/ or references/.
PIPE
      ;;
  esac
  echo ""
  echo "### Operator definitions (canonical from OPERATOR-LIBRARY.md)"
  echo ""
  echo "- **★ ORIENT** — first 3 paragraphs: what/who/where"
  echo "- **✦ MOTIVATE** — why does this exist? what problem solved?"
  echo "- **◐ MENTAL-MODEL** — diagram/sketch showing relationships"
  echo "- **⬡ EXEMPLIFY** — copy-pasteable runnable example"
  echo "- **⚠ WARN** — anti-patterns / pitfalls / gotchas"
  echo "- **⇄ CROSS-LINK** — links to related surfaces"
  echo "- **⌘ REDUCE** — cut by 30%+"
  echo ""
  echo "For full operator list (11 operators) + per-operator prompt modules,"
  echo "see source: \`~/.claude/skills/documentation-website-for-software-project/references/OPERATOR-LIBRARY.md\`."
  echo ""
} > "$RECIPE_FILE"

# Inject the recipe file before ## METADATA section
awk -v RECIPE_FILE="$RECIPE_FILE" '
/^## METADATA/ {
  while ((getline line < RECIPE_FILE) > 0) print line
  close(RECIPE_FILE)
  print ""
}
{ print }
' "$BODY_FILE"
