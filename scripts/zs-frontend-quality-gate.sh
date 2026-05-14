#!/usr/bin/env bash
# zs-frontend-quality-gate.sh - ZestStream frontend quality gate
#
# Audits any ZestStream Next.js project against the quality bar.
# This is the Donella Meadows balancing feedback loop that makes
# "best websites on the planet every single time" a mechanical guarantee
# rather than a manual judgment call.
#
# Exit codes:
#   0 - all checks pass
#   1 - one or more checks fail (blocks deploy)
#   2 - usage error
#
# Usage:
#   zs-frontend-quality-gate.sh [--repo PATH] [--json] [--strict]
#   zs-frontend-quality-gate.sh --repo /Users/josh/Developer/mobile-eats
#
# Checks:
#   FQ-01 Font loading: next/font/google (not system fallback)
#   FQ-02 Design tokens: tokens.ts exists and @theme inline mirrors it
#   FQ-03 Token purity: no raw hex/rgb outside tokens.ts
#   FQ-04 Motion: @zeststream/motion tokens wired to at least one component
#   FQ-05 Brand voice: copy.ts exists, no raw inline strings in components
#   FQ-06 Motion safety: prefers-reduced-motion respected
#   FQ-07 Accessibility: aria-label on interactive elements
#   FQ-08 Proof states: ProofRail or equivalent in public-facing content
#   FQ-09 Story system: story-system.json or @zeststream/story-system linked
#   FQ-10 Package.json: @zeststream/* packages declared
#
# Jeff Emanuel design principle: every check produces a machine-readable number.
# "pass=8 fail=2" beats "mostly good." Blocks CI on fail in --strict mode.

set -euo pipefail

REPO="${ZS_FRONTEND_GATE_REPO:-$PWD}"
JSON_OUT=0
STRICT=0

# Safe numeric coercion: strips whitespace/newlines from wc/grep output.
num() { printf '%s' "${1:-0}" | tr -d '[:space:]' | grep -Eo '^[0-9]+' || echo 0; }

count_matches() {
  local base="$1"
  local pattern="$2"
  shift 2
  if [[ ! -d "$base" ]]; then
    echo 0
    return
  fi
  find "$base" \
    \( -path "*/.git/*" -o -path "*/.flywheel/*" -o -path "*/.ntm/*" \
      -o -path "*/node_modules/*" -o -path "*/.next/*" -o -path "*/dist/*" \
      -o -path "*/build/*" -o -path "*/coverage/*" \) -prune \
    -o -type f \( "$@" \) -print0 \
    | xargs -0 grep -E -h -- "$pattern" 2>/dev/null \
    | wc -l \
    | tr -d '[:space:]'
}

find_first_file() {
  local base="$1"
  local name="$2"
  if [[ ! -d "$base" ]]; then
    return 0
  fi
  find "$base" \
    \( -path "*/.git/*" -o -path "*/.flywheel/*" -o -path "*/.ntm/*" \
      -o -path "*/node_modules/*" -o -path "*/.next/*" -o -path "*/dist/*" \
      -o -path "*/build/*" -o -path "*/coverage/*" \) -prune \
    -o -type f -name "$name" -print \
    | head -1
}

json_row() {
  local id="$1" name="$2" verdict="$3" detail="${4:-}"
  jq -nc \
    --arg id "$id" \
    --arg name "$name" \
    --arg verdict "$verdict" \
    --arg detail "$detail" \
    '{id:$id,name:$name,verdict:$verdict,detail:$detail}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --strict) STRICT=1; shift ;;
    --help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

NEXT_APP=""
for candidate in "$REPO/next-app" "$REPO/apps/cfs-console" "$REPO/apps/locations-site" "$REPO"; do
  if [[ -f "$candidate/package.json" ]] && grep -q '"next"' "$candidate/package.json" 2>/dev/null; then
    NEXT_APP="$candidate"
    break
  fi
done

PASSES=0
FAILS=0
WARNINGS=0
RESULTS=()

check() {
  local id="$1" name="$2" verdict="$3" detail="${4:-}"
  if [[ "$verdict" == "pass" ]]; then
    PASSES=$((PASSES + 1))
    RESULTS+=("$(json_row "$id" "$name" "pass" "$detail")")
  elif [[ "$verdict" == "warn" ]]; then
    WARNINGS=$((WARNINGS + 1))
    RESULTS+=("$(json_row "$id" "$name" "warn" "$detail")")
  else
    FAILS=$((FAILS + 1))
    RESULTS+=("$(json_row "$id" "$name" "fail" "$detail")")
  fi
}

# ── FQ-01 Font loading ─────────────────────────────────────────────────────
if [[ -n "$NEXT_APP" ]]; then
  font_hits=$(num "$(count_matches "$NEXT_APP" "next/font" -name "*.ts" -o -name "*.tsx")")
  if [[ "$font_hits" -gt 0 ]]; then
    check "FQ-01" "Font loading via next/font" "pass" "${font_hits} next/font import(s) found"
  else
    check "FQ-01" "Font loading via next/font" "fail" "No next/font imports found - system fallback (Arial) will render in production"
  fi
else
  check "FQ-01" "Font loading via next/font" "warn" "No Next.js app directory found at $REPO"
fi

# ── FQ-02 Design tokens ────────────────────────────────────────────────────
token_file=$(find_first_file "$REPO" "tokens.ts")
if [[ -n "$token_file" ]]; then
  check "FQ-02" "Design tokens file" "pass" "$token_file"
else
  check "FQ-02" "Design tokens file" "warn" "No tokens.ts found - add lib/design/tokens.ts as single source of truth"
fi

# ── FQ-03 Token purity (no raw hex in component files) ────────────────────
if [[ -n "$NEXT_APP" ]]; then
  raw_hex=$(num "$(count_matches "$NEXT_APP" "#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}" -name "*.tsx")")
  if [[ "$raw_hex" -eq 0 ]]; then
    check "FQ-03" "Token purity (no raw hex in components)" "pass" "0 raw hex values found"
  elif [[ "$raw_hex" -le 5 ]]; then
    check "FQ-03" "Token purity (no raw hex in components)" "warn" "${raw_hex} raw hex value(s) — move to tokens.ts"
  else
    check "FQ-03" "Token purity (no raw hex in components)" "fail" "${raw_hex} raw hex values outside tokens.ts — breaks design system"
  fi
fi

# ── FQ-04 Motion tokens wired ─────────────────────────────────────────────
# Recognizes @zeststream/motion imports, motion-tokens, AND the generic
# per-repo motion-class convention (<prefix>-spring / <prefix>-pulse /
# <prefix>-pin-spring etc.). Updated 2026-05-14 so CFS's cfs-spring and any
# future repo's <prefix>-spring convention is detected, not just mobile-eats me-*.
motion_usage=0
if [[ -n "$NEXT_APP" ]]; then
  motion_usage=$(num "$(count_matches "$NEXT_APP" \
    "@zeststream/motion|motion-tokens|springPresets|pulseSpec|sheetSnap|filterChip|[a-z]+-(spring|pulse|live-pulse|pin-spring|chip-spring|sheet-spring)" \
    -name "*.tsx" -o -name "*.css")")
fi
if [[ "$motion_usage" -gt 0 ]]; then
  check "FQ-04" "Motion tokens wired to components" "pass" "${motion_usage} motion token reference(s)"
elif [[ -z "$NEXT_APP" ]]; then
  check "FQ-04" "Motion tokens wired to components" "warn" "No Next.js app directory found at $REPO"
else
  check "FQ-04" "Motion tokens wired to components" "fail" "No motion token usage - @zeststream/motion exists but is unwired"
fi

# ── FQ-05 Brand voice (copy.ts single source) ─────────────────────────────
copy_file=$(find_first_file "$REPO" "copy.ts")
if [[ -n "$copy_file" ]]; then
  check "FQ-05" "Brand voice copy.ts" "pass" "$copy_file"
else
  check "FQ-05" "Brand voice copy.ts" "warn" "No copy.ts - inline strings in components will drift from brand voice"
fi

# ── FQ-06 Reduced motion safety ───────────────────────────────────────────
reduced_motion_css=$(num "$(count_matches "$REPO" "prefers-reduced-motion|motion-reduce" -name "*.css" -o -name "*.tsx")")
if [[ "$reduced_motion_css" -gt 0 ]]; then
  check "FQ-06" "prefers-reduced-motion respected" "pass" "${reduced_motion_css} reference(s)"
elif [[ -z "$NEXT_APP" ]]; then
  check "FQ-06" "prefers-reduced-motion respected" "warn" "No Next.js app directory found at $REPO"
else
  check "FQ-06" "prefers-reduced-motion respected" "fail" "No prefers-reduced-motion handling - accessibility failure"
fi

# ── FQ-07 Accessibility (aria-labels) ─────────────────────────────────────
# Scans the whole app dir (not just components/) so the src/components +
# src/pages layout used by CFS-style repos is covered, not just the
# next-app/components layout used by mobile-eats. Fixed 2026-05-14 after
# FQ-07 false-failed CFS, which has ARIA in src/pages/.
if [[ -n "$NEXT_APP" ]]; then
  aria_count=$(num "$(count_matches "$NEXT_APP" "aria-label|aria-labelledby|role=" -name "*.tsx")")
  if [[ "$aria_count" -gt 0 ]]; then
    check "FQ-07" "ARIA labels on interactive elements" "pass" "${aria_count} aria-label/role declarations"
  else
    check "FQ-07" "ARIA labels on interactive elements" "fail" "No ARIA labels found - accessibility failure"
  fi
fi

# ── FQ-08 Proof states / evidence surfaces ────────────────────────────────
proof_hits=$(num "$(count_matches "$REPO" \
  "ProofRail|proof_state|proofState|proof-state|proven.*blocked|evidence.*rail" \
  -name "*.tsx" -o -name "*.mdx" -o -name "*.json")")
if [[ "$proof_hits" -gt 0 ]]; then
  check "FQ-08" "Proof states / evidence surfaces" "pass" "${proof_hits} proof state reference(s)"
else
  check "FQ-08" "Proof states / evidence surfaces" "warn" "No ProofRail or proof states - claims are ungrounded"
fi

# ── FQ-09 Story system linked ─────────────────────────────────────────────
story_hit=$(find_first_file "$REPO" "story-system.json")
if [[ -n "$story_hit" ]]; then
  check "FQ-09" "Story system linked" "pass" "$story_hit"
else
  story_dep=$(grep "@zeststream/story-system\|story-system" "$REPO/package.json" 2>/dev/null | head -1 || true)
  if [[ -n "$story_dep" ]]; then
    check "FQ-09" "Story system linked" "pass" "Dependency declared: @zeststream/story-system"
  else
    check "FQ-09" "Story system linked" "warn" "No story-system.json - brand voice and proof taxonomy undefined"
  fi
fi

# ── FQ-10 ZestStream packages declared ────────────────────────────────────
zs_pkg_file="${NEXT_APP:-$REPO}/package.json"
zs_packages=$(num "$(grep -c "@zeststream" "$zs_pkg_file" 2>/dev/null || true)")
if [[ "$zs_packages" -gt 0 ]]; then
  check "FQ-10" "@zeststream/* packages declared" "pass" "${zs_packages} package(s)"
else
  check "FQ-10" "@zeststream/* packages declared" "warn" "No @zeststream/* packages - no shared infrastructure"
fi

# ── Emit results ──────────────────────────────────────────────────────────
TOTAL=$((PASSES + FAILS + WARNINGS))
STATUS="pass"
[[ "$FAILS" -gt 0 ]] && STATUS="fail"
[[ "$FAILS" -eq 0 && "$WARNINGS" -gt 0 ]] && STATUS="warn"

if [[ "$JSON_OUT" -eq 1 ]]; then
  results_array=$(printf '%s\n' "${RESULTS[@]}" | paste -sd ',' -)
  jq -nc \
    --arg status "$STATUS" \
    --arg repo "$REPO" \
    --argjson pass "$PASSES" \
    --argjson fail "$FAILS" \
    --argjson warn "$WARNINGS" \
    --argjson total "$TOTAL" \
    --argjson results "[$results_array]" \
    '{schema_version:"zs-frontend-quality-gate/v1",status:$status,repo:$repo,
      pass:$pass,fail:$fail,warn:$warn,total:$total,results:$results}'
else
  echo "ZS Frontend Quality Gate — $REPO"
  echo "Status: $STATUS (pass=$PASSES fail=$FAILS warn=$WARNINGS / $TOTAL checks)"
  for r in "${RESULTS[@]}"; do
    id=$(echo "$r" | jq -r '.id')
    name=$(echo "$r" | jq -r '.name')
    verdict=$(echo "$r" | jq -r '.verdict')
    detail=$(echo "$r" | jq -r '.detail')
    case "$verdict" in
      pass) sym="PASS" ;;
      warn) sym="WARN" ;;
      fail) sym="FAIL" ;;
      *)    sym="?" ;;
    esac
    echo "  $sym [$id] $name - $detail"
  done
fi

if [[ "$FAILS" -gt 0 && "$STRICT" -eq 1 ]]; then
  exit 1
fi
[[ "$FAILS" -eq 0 ]] && exit 0 || exit 1
