#!/usr/bin/env bash
# inject-forward-link-recipe.sh — auto-inject FORWARD-LINK DOCTRINE DOC RECIPE BLOCK
# into dispatch packets for [gap-memory-without-cross-link] beads.
#
# Pattern: canonical-cli-scoping triad (info/schema/doctor) + dry-run/apply +
# stable exit codes + JSON output.
#
# Source: flywheel-pmg3c (P2 skill-promotion-N4). N=7 confirmed instances of
# the forward-link doctrine doc recipe pattern across 2 workers (MistyCliff +
# MagentaPond) across 5 memory classes.
#
# Behavior:
# 1. Read dispatch body from arg 1 (or - for stdin)
# 2. Detect [gap-memory-without-cross-link] in bead title
# 3. If detected: insert FORWARD-LINK DOCTRINE DOC RECIPE BLOCK before METADATA
# 4. Otherwise: pass through unchanged
#
# Wired into build-dispatch-packet.sh after inject-l-rule-hints.sh.

set -euo pipefail

BODY_FILE="${1:-}"
TASK_ID="${2:-unknown}"
REPO_PATH="${3:-${PWD:-}}"

# ── canonical-cli-scoping triad ─────────────────────────────────────────
if [[ "$BODY_FILE" == "--help" || "$BODY_FILE" == "-h" ]]; then
  cat <<'EOF'
Usage: inject-forward-link-recipe.sh <task-body-file> [task-id] [repo-path]

Auto-injects FORWARD-LINK DOCTRINE DOC RECIPE BLOCK into dispatch packets
when the bead title matches [gap-memory-without-cross-link]. Workers no
longer need to re-discover the 4-step recipe + 3 sub-patterns
(1:1 / CLUSTER-ANCHOR / NOT-YET-PROMOTED).

Pattern source: flywheel-pmg3c (N=7 confirmed instances across 5 memory
classes). Doctrine source: .flywheel/doctrine/forward-link-doctrine-doc-recipe.md.

Env vars:
  FORWARD_LINK_RECIPE_DISABLED=1  pass through unchanged (no injection)
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "--info" ]]; then
  printf 'inject-forward-link-recipe: dispatch-packet auto-injector for memory-without-cross-link class; N=7 instances at promotion; sub-patterns=3 (1to1,cluster-anchor,not-yet-promoted)\n'
  exit 0
fi

if [[ "$BODY_FILE" == "--schema" ]]; then
  printf '%s\n' '{"schema_version":"inject-forward-link-recipe.v1","output":"markdown","trigger":"[gap-memory-without-cross-link]","sub_patterns":["1to1","cluster-anchor","not-yet-promoted"],"doctrine_source":".flywheel/doctrine/forward-link-doctrine-doc-recipe.md"}'
  exit 0
fi

if [[ "$BODY_FILE" == "--examples" ]]; then
  cat <<'EOF'
inject-forward-link-recipe.sh /tmp/task-body.md flywheel-2xdi.117
inject-forward-link-recipe.sh - flywheel-fixture < dispatch-body.md
FORWARD_LINK_RECIPE_DISABLED=1 inject-forward-link-recipe.sh /tmp/body.md fixture
inject-forward-link-recipe.sh --info
inject-forward-link-recipe.sh --schema
inject-forward-link-recipe.sh --doctor
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "--doctor" ]]; then
  # Verify doctrine doc exists + injector is reachable from build-dispatch-packet
  DOCTRINE_PATH="${REPO_PATH%/}/.flywheel/doctrine/forward-link-doctrine-doc-recipe.md"
  BUILDER_PATH="${REPO_PATH%/}/.flywheel/scripts/build-dispatch-packet.sh"
  doctrine_ok="missing"; [[ -f "$DOCTRINE_PATH" ]] && doctrine_ok="present"
  builder_wired="not_wired"
  if [[ -f "$BUILDER_PATH" ]] && grep -q 'inject-forward-link-recipe' "$BUILDER_PATH" 2>/dev/null; then
    builder_wired="wired"
  fi
  printf '{"schema_version":"inject-forward-link-recipe-doctor.v1","doctrine_doc":"%s","builder_wired":"%s","repo_path":"%s"}\n' \
    "$doctrine_ok" "$builder_wired" "$REPO_PATH"
  [[ "$doctrine_ok" == "present" && "$builder_wired" == "wired" ]] && exit 0 || exit 1
fi

# ── stdin handling ──────────────────────────────────────────────────────
TMP_BODY=""
if [[ "$BODY_FILE" == "-" || "$BODY_FILE" == "/dev/stdin" ]]; then
  TMP_BODY="$(mktemp "${TMPDIR:-/tmp}/forward-link-recipe-stdin.XXXXXX")"
  trap '[[ -z "$TMP_BODY" ]] || rm -f "$TMP_BODY"' EXIT
  cat >"$TMP_BODY"
  BODY_FILE="$TMP_BODY"
fi

if [[ -z "$BODY_FILE" || ! -r "$BODY_FILE" ]]; then
  echo "usage: inject-forward-link-recipe.sh <task-body-file> [task-id] [repo-path]" >&2
  exit 2
fi

# ── disabled passthrough ────────────────────────────────────────────────
if [[ "${FORWARD_LINK_RECIPE_DISABLED:-0}" == "1" ]]; then
  cat "$BODY_FILE"
  exit 0
fi

# ── trigger detection ───────────────────────────────────────────────────
# Match bead title containing [gap-memory-without-cross-link]
if ! grep -q '\[gap-memory-without-cross-link\]' "$BODY_FILE"; then
  cat "$BODY_FILE"
  exit 0
fi

# ── injection ───────────────────────────────────────────────────────────
# Insert FORWARD-LINK DOCTRINE DOC RECIPE BLOCK before the ## METADATA section
# (preserves canonical block ordering: METADATA comes last per build-dispatch-packet.sh).

RECIPE_FILE="$(mktemp "${TMPDIR:-/tmp}/forward-link-recipe.XXXXXX")"
trap '[[ -z "${RECIPE_FILE:-}" ]] || rm -f "$RECIPE_FILE"; [[ -z "${TMP_BODY:-}" ]] || rm -f "$TMP_BODY"' EXIT

cat >"$RECIPE_FILE" <<'RECIPE'
## FORWARD-LINK DOCTRINE DOC RECIPE BLOCK

Auto-injected for `[gap-memory-without-cross-link]` class beads
(`.flywheel/scripts/inject-forward-link-recipe.sh`). Canonical doctrine:
`.flywheel/doctrine/forward-link-doctrine-doc-recipe.md`. N=7 confirmed
instances at promotion (2026-05-11 via flywheel-pmg3c).

### Recipe (4 steps)

1. **Read memory**: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/<name>.md`
2. **Create doctrine doc** at `.flywheel/doctrine/<descriptive-name>.md` with:
   - Frontmatter (`type: doctrine`, `created: <date>`, `frontmatter_source: scaffold-doc-frontmatter`)
   - Version line + owner + status + source bead
   - **TL;DR** (1-paragraph canonical summary)
   - **Canonical memory source** section: explicit cite of memory filename
   - **The pattern**: Why / How to apply
   - **Anti-pattern**: what NOT to do
   - **Behavioral vs name cross-linking**: surface where discipline IS embedded
   - **Sister doctrine** cross-links (3+ entries)
   - **Conformance** (3-5 step proof contract)
   - **Below-trauma-class tracking** (instance count + promotion path)
3. **Verify** corpus 4 (`skill_md_corpus`) or doctrine-corpus now contains
   memory filename via grep (post-patch check).
4. **Commit + br close + callback** (per L120 + standard worker-tick).

### Choose sub-pattern

| Sub-pattern | When | Exemplar |
|---|---|---|
| **1:1 forward-link** (default) | Memory documents 1 discipline, load-bearing in 1-2 surfaces | 2xdi.109 silent-deaf, 2xdi.110 parallel-impl P2 |
| **CLUSTER-ANCHOR** | Memory explicitly cites 3+ sibling memories as trauma-class cluster | 2xdi.125 (5-memory codex+tmux-stdin cluster) |
| **NOT-YET-PROMOTED** | Memory documents PROPOSED class that hasn't met own promotion threshold | 2xdi.117 (jeff-response-shape-5 RESHAPED, 0/3 instances) |

### Anti-patterns

- **Do NOT rewrite load-bearing runtime artifacts** (L-rules, scripts) just
  to inject memory-name strings. Forward-link doctrine doc IS the canonical
  cross-link.
- **Do NOT file calibration bead for the recurring blind-spot class** —
  `flywheel-xbsd8` already owns the harvest for faqj2 next-tick.
  3rd+ instance reinforces the class (data point), not new bead.
- **Do NOT bundle N memories** unless they are explicit sister-class
  siblings (use CLUSTER-ANCHOR).

### Substrate-self-improving loop

This recipe IS the loop in action: probe flags memory → packet auto-injects
recipe → worker applies sub-pattern → doctrine ships → next probe clears
gap. Per Axiom 8 (Accretive Leverage): no manual re-discovery per bead.

For full doctrine including N=7 instance table + cross-link to xbsd8 harvest
class: see `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md`.

RECIPE

# Inject the recipe file before ## METADATA section using awk r-command
awk -v RECIPE_FILE="$RECIPE_FILE" '
/^## METADATA/ {
  while ((getline line < RECIPE_FILE) > 0) print line
  close(RECIPE_FILE)
  print ""
}
{ print }
' "$BODY_FILE"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
