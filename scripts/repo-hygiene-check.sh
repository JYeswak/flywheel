#!/usr/bin/env bash
# repo-hygiene-check.sh — enforces the repo-hygiene operational protocol.
#
# Implements the four invariants from
# .flywheel/doctrine/repo-hygiene-operational-protocol.md:
#   H-1  shadowing      — no tracked file matches a .gitignore rule       [fail]
#   H-2  output-in-git  — no large tracked dir of generated output        [fail]
#   H-3  accretion      — accreting surfaces under size threshold         [warn]
#   H-4  substrate      — rebuildable substrate is gitignored             [warn]
#
# Repo hygiene is an enforced operational protocol, not a periodic cleanup.
# Wire this into the flywheel tick/loop so accretion is caught at the tick.
#
# Exit codes: 0 all pass/warn · 1 one or more fail · 2 usage error
# Usage: repo-hygiene-check.sh [--repo PATH] [--json]

set -euo pipefail

REPO="${REPO_HYGIENE_REPO:-$PWD}"
JSON_OUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
cd "$REPO"

PASSES=0; FAILS=0; WARNINGS=0
RESULTS=()
emit() { # id verdict detail
  case "$2" in
    pass) PASSES=$((PASSES+1)) ;;
    warn) WARNINGS=$((WARNINGS+1)) ;;
    *)    FAILS=$((FAILS+1)) ;;
  esac
  RESULTS+=("$(jq -nc --arg id "$1" --arg v "$2" --arg d "$3" \
    '{id:$id,verdict:$v,detail:$d}')")
}

# ── H-1 shadowing — no tracked file matches a .gitignore rule ──────────────
# git check-ignore exits 1 when zero paths match — legitimate, not an error.
shadowed="$( { git ls-files | git check-ignore --no-index --stdin 2>/dev/null || true; } | wc -l | tr -d ' ')"
if [[ "$shadowed" -eq 0 ]]; then
  emit "H-1" "pass" "shadowing audit clean — 0 tracked files match a .gitignore rule"
else
  emit "H-1" "fail" "${shadowed} tracked file(s) are gitignored — pair the rule with 'git rm --cached'"
fi

# ── H-2 output-in-git — no large tracked dir of generated output ──────────
# A tracked directory >200 files that is mostly json/csv is generated output.
worst_dir=""; worst_n=0
while IFS= read -r d; do
  [[ -z "$d" ]] && continue
  n="$(git ls-files "$d" | wc -l | tr -d ' ')"
  [[ "$n" -le 200 ]] && continue
  gen="$(git ls-files "$d" | grep -cE '\.(json|csv)$' || true)"
  # >60% json/csv → generated output
  if [[ "$n" -gt 0 && $((gen * 100 / n)) -ge 60 ]]; then
    if [[ "$n" -gt "$worst_n" ]]; then worst_n="$n"; worst_dir="$d"; fi
  fi
done < <(git ls-files | sed 's#/[^/]*$##' | sort -u | awk -F/ '{print $1"/"$2}' | sort -u)
if [[ -z "$worst_dir" ]]; then
  emit "H-2" "pass" "no large tracked directory of generated output"
else
  emit "H-2" "fail" "${worst_dir} has ${worst_n} tracked generated files — gitignore it + git rm --cached"
fi

# ── H-3 accretion — accreting surfaces under size threshold ───────────────
# Register from the protocol doc. Threshold: 500 MB working-tree per surface.
THRESH_MB=500
over=()
for surface in .flywheel/extraction .flywheel/audit .flywheel/reports \
               .flywheel/summaries .beads .git-archive; do
  [[ -d "$surface" ]] || continue
  mb="$( { du -sm "$surface" 2>/dev/null || true; } | awk '{print $1}')"
  [[ -z "$mb" ]] && continue
  if [[ "$mb" -gt "$THRESH_MB" ]]; then over+=("${surface}=${mb}MB"); fi
done
if [[ ${#over[@]} -eq 0 ]]; then
  emit "H-3" "pass" "all accreting surfaces under ${THRESH_MB}MB"
else
  emit "H-3" "warn" "accreting surface(s) over ${THRESH_MB}MB: ${over[*]} — needs a retention policy"
fi

# ── H-4 substrate — rebuildable substrate is gitignored ───────────────────
# A substrate dir that exists on disk must be gitignored (git check-ignore -q
# exits 0 when the path is ignored).
unignored=()
for sub in node_modules .flywheel/extraction .flywheel/audit; do
  [[ -e "$sub" ]] || continue
  # Probe a path inside the dir — a trailing-slash .gitignore rule does not
  # match a bare directory path, but it does match a path within it.
  if ! git check-ignore -q "$sub/.hygiene-probe" 2>/dev/null; then
    unignored+=("$sub")
  fi
done
if [[ ${#unignored[@]} -eq 0 ]]; then
  emit "H-4" "pass" "rebuildable substrate on disk is gitignored"
else
  emit "H-4" "warn" "rebuildable substrate not gitignored: ${unignored[*]}"
fi

# ── emit ──────────────────────────────────────────────────────────────────
if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "${RESULTS[@]}" | jq -s \
    --argjson p "$PASSES" --argjson f "$FAILS" --argjson w "$WARNINGS" \
    '{schema:"flywheel.repo_hygiene_check.v0",pass:$p,fail:$f,warn:$w,checks:.}'
else
  echo "Repo Hygiene Check — $REPO"
  for r in "${RESULTS[@]}"; do
    printf '  %s [%s] %s\n' \
      "$(echo "$r" | jq -r '.verdict|ascii_upcase')" \
      "$(echo "$r" | jq -r '.id')" \
      "$(echo "$r" | jq -r '.detail')"
  done
  echo "Status: pass=${PASSES} fail=${FAILS} warn=${WARNINGS}"
fi
[[ "$FAILS" -gt 0 ]] && exit 1 || exit 0
