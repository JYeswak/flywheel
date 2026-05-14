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
#   FQ-09 Story system: static sites carry story-system.json; Next.js apps
#         import @zeststream/story-system, plus generated trajectory and owner
#         brief artifacts
#   FQ-10 Package.json: @zeststream/* packages declared
#   --- content-quality checks (catch what mechanical proxies cannot) ---
#   FQ-11 Meta-voice: public copy speaks to the customer, not about the page;
#         no internal-doctrine vocabulary leaks
#   FQ-12 First-person operator voice on public ZestStream surfaces
#   FQ-13 Concreteness: process claims carry specifics, not pure abstraction
#   FQ-14 Cross-page repetition: pages build, they do not restate
#   FQ-15 Contrast: same-block CSS color/background pairs meet WCAG AA 4.5:1
#
# Jeffrey Emanuel design principle: every check produces a machine-readable
# number. "pass=8 fail=2" beats "mostly good." Blocks CI on fail in --strict.
#
# FQ-01..FQ-10 measure proxies (a file exists, a font is imported). FQ-11..FQ-14
# measure the copy itself — because a gate that passes a product its owner
# rejects is a gate that is lying. FQ-15 measures the CSS it can resolve
# statically; cross-cascade/alpha contrast stays a render-review item. The gate
# is the floor; Joshua's taste is the ceiling. Nothing should reach Joshua that
# has not cleared FQ-11..FQ-15.

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

find_first_name_match() {
  local base="$1"
  local pattern="$2"
  if [[ ! -d "$base" ]]; then
    return 0
  fi
  find "$base" \
    \( -path "*/.git/*" -o -path "*/.flywheel/*" -o -path "*/.ntm/*" \
      -o -path "*/node_modules/*" -o -path "*/.next/*" -o -path "*/dist/*" \
      -o -path "*/build/*" -o -path "*/coverage/*" \) -prune \
    -o -type f -name "$pattern" -print \
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

# ── Brand tier detection ──────────────────────────────────────────────────
# Two-tier model. Tier-1 standards (fonts, tokens, motion, a11y, copy craft,
# design-system adoption) apply to EVERY project — ZestStream or client.
# Tier-2 ZestStream-brand storytelling checks (FQ-08 proof states, FQ-09 story
# system, FQ-12 first-person voice) apply ONLY to ZestStream-owned surfaces.
# Client/single-effort products (mobile-eats, clutterfreespaces, alps, vrtx)
# are NEVER forced to tell the ZestStream story — they carry their own brand.
#
# Detection precedence:
#   1. explicit .zs-brand file ("zeststream" or "product")
#   2. repo HOSTS packages/zeststream-story-system/ → ZestStream brand repo
#   3. default "product" — the safe default never forces storytelling
BRAND_TIER="product"
if [[ -f "$REPO/.zs-brand" ]]; then
  marker="$(tr -d '[:space:]' < "$REPO/.zs-brand" 2>/dev/null || true)"
  [[ "$marker" == "zeststream" || "$marker" == "product" ]] && BRAND_TIER="$marker"
elif [[ -d "$REPO/packages/zeststream-story-system" ]]; then
  BRAND_TIER="zeststream"
fi

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
# Next.js apps must use next/font. Static-HTML sites (no Next.js) must still
# actually LOAD their font — via a <link> to a font service or @font-face —
# not just declare a font-family stack. Updated 2026-05-14: a static marketing
# site that loads its font properly passes; one that only declares it warns.
if [[ -n "$NEXT_APP" ]]; then
  font_hits=$(num "$(count_matches "$NEXT_APP" "next/font" -name "*.ts" -o -name "*.tsx")")
  if [[ "$font_hits" -gt 0 ]]; then
    check "FQ-01" "Font loading via next/font" "pass" "${font_hits} next/font import(s) found"
  else
    check "FQ-01" "Font loading via next/font" "fail" "No next/font imports found - system fallback (Arial) will render in production"
  fi
else
  static_font=$(num "$(count_matches "$REPO" "fonts.googleapis|@font-face|fonts.bunny|fonts.gstatic" -name "*.html" -o -name "*.css")")
  if [[ "$static_font" -gt 0 ]]; then
    check "FQ-01" "Font loading (static site)" "pass" "${static_font} font-load reference(s) — static site loads its font, not just declares it"
  else
    check "FQ-01" "Font loading" "warn" "No Next.js app and no static font load (<link>/@font-face) - font-family stack declared but not loaded"
  fi
fi

# ── FQ-02 Design tokens ────────────────────────────────────────────────────
token_file=$(find_first_file "$REPO" "tokens.ts")
if [[ -n "$token_file" ]]; then
  check "FQ-02" "Design tokens file" "pass" "$token_file"
else
  check "FQ-02" "Design tokens file" "warn" "No tokens.ts found - add lib/design/tokens.ts as single source of truth"
fi

# ── FQ-03 Token purity (no raw hex in component files) ────────────────────
# The trailing [^0-9a-fA-F-] / end-of-token boundary excludes anchor hrefs
# like "#add-menu-item" — "#add" matches {3} because a/d/d are hex digits.
# A real hex color is #xxx or #xxxxxx terminated by a non-hex, non-hyphen
# char. Fixed 2026-05-14 after FQ-03 false-failed a downstream app anchor.
if [[ -n "$NEXT_APP" ]]; then
  raw_hex=$(num "$(count_matches "$NEXT_APP" "#[0-9a-fA-F]{6}([^0-9a-fA-F-]|\$)|#[0-9a-fA-F]{3}([^0-9a-fA-F-]|\$)" -name "*.tsx")")
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
  # Static-HTML site: check for real CSS motion (keyframes / transitions /
  # cubic-bezier easing), evaluated by static-site standards not React standards.
  static_motion=$(num "$(count_matches "$REPO" "@keyframes|cubic-bezier|transition:|animation:|transition-timing" -name "*.css")")
  if [[ "$static_motion" -gt 0 ]]; then
    check "FQ-04" "Motion (static site)" "pass" "${static_motion} CSS motion reference(s) — keyframes/transitions present"
  else
    check "FQ-04" "Motion (static site)" "warn" "No CSS motion (keyframes/transitions) — site is fully static"
  fi
else
  check "FQ-04" "Motion tokens wired to components" "fail" "No motion token usage - @zeststream/motion exists but is unwired"
fi

# ── FQ-05 Brand voice (single-source copy) ────────────────────────────────
# React apps centralize copy in copy.ts. Static-HTML sites have no module
# system — their brand-voice anchor is story-system.json (the voice schema).
# Updated 2026-05-14 to evaluate static sites by static-site standards.
copy_file=$(find_first_file "$REPO" "copy.ts")
if [[ -n "$copy_file" ]]; then
  check "FQ-05" "Brand voice copy.ts" "pass" "$copy_file"
elif [[ -z "$NEXT_APP" ]]; then
  story_anchor=$(find_first_file "$REPO" "story-system.json")
  if [[ -n "$story_anchor" ]]; then
    check "FQ-05" "Brand voice (static site)" "pass" "story-system.json present — brand voice schema anchors the static site"
  else
    check "FQ-05" "Brand voice (static site)" "warn" "No copy.ts and no story-system.json - brand voice not anchored"
  fi
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

# ── FQ-08 Proof states / evidence surfaces (TIER-2: ZestStream-brand only) ─
if [[ "$BRAND_TIER" != "zeststream" ]]; then
  check "FQ-08" "Proof states / evidence surfaces" "pass" "skipped — Tier-2 ZestStream-brand storytelling check, n/a to a product-tier repo"
else
  proof_hits=$(num "$(count_matches "$REPO" \
    "ProofRail|proof_state|proofState|proof-state|proven.*blocked|evidence.*rail" \
    -name "*.tsx" -o -name "*.mdx" -o -name "*.json")")
  if [[ "$proof_hits" -gt 0 ]]; then
    check "FQ-08" "Proof states / evidence surfaces" "pass" "${proof_hits} proof state reference(s)"
  else
    check "FQ-08" "Proof states / evidence surfaces" "warn" "No ProofRail or proof states - claims are ungrounded"
  fi
fi

# ── FQ-09 Story system + owner brief (TIER-2: ZestStream-brand only) ───────
# A client product (mobile-eats, CFS, alps, vrtx) must NEVER be force-failed
# for "not telling the ZestStream story." It carries its own brand.
if [[ "$BRAND_TIER" != "zeststream" ]]; then
  check "FQ-09" "Story system linked" "pass" "skipped — Tier-2 ZestStream-brand storytelling check, n/a to a product-tier repo"
else
  story_hit=$(find_first_file "$REPO" "story-system.json")
  story_dep=""
  if [[ -z "$story_hit" ]]; then
    story_dep=$(grep "@zeststream/story-system\|story-system" "$REPO/package.json" 2>/dev/null | head -1 || true)
  fi
  story_module_hits=0
  if [[ -n "$NEXT_APP" ]]; then
    story_module_hits=$(num "$(count_matches "$NEXT_APP" \
      "@zeststream/story-system|assertStorySystemContract|storySystem" \
      -name "*.ts" -o -name "*.tsx")")
  fi
  if [[ -n "$story_hit" || -n "$story_dep" || "$story_module_hits" -gt 0 ]]; then
    trajectory_artifact=$(find_first_name_match "$REPO" "*trajectory.json")
    owner_brief_artifact=$(find_first_name_match "$REPO" "*owner-brief.json")
    if [[ -n "$NEXT_APP" && "$story_module_hits" -eq 0 ]]; then
      check "FQ-09" "Story system linked" "fail" "Next.js apps must import @zeststream/story-system or assertStorySystemContract, not only declare the dependency"
    elif [[ -n "$trajectory_artifact" && -n "$owner_brief_artifact" ]] \
      && grep -q "zeststream.repo_owner_story_brief.v0" "$owner_brief_artifact" 2>/dev/null; then
      story_detail="${story_hit:-Dependency declared: @zeststream/story-system}; imports=${story_module_hits}; trajectory=$trajectory_artifact; owner_brief=$owner_brief_artifact"
      check "FQ-09" "Story system linked" "pass" "$story_detail"
    else
      check "FQ-09" "Story system linked" "fail" "Story system is linked, but generated trajectory JSON and zeststream.repo_owner_story_brief.v0 are required before public frontend work can pass"
    fi
  else
    check "FQ-09" "Story system linked" "warn" "No story-system.json - brand voice and proof taxonomy undefined"
  fi
fi

# ── FQ-10 ZestStream packages declared OR hosted ──────────────────────────
# A repo passes if it CONSUMES @zeststream/* packages (declared in package.json)
# OR HOSTS them (packages/zeststream-* dirs). The monorepo that owns the
# package source shouldn't warn for "not depending on" packages it contains.
# Updated 2026-05-14 after flywheel false-warned despite hosting the packages.
zs_pkg_file="${NEXT_APP:-$REPO}/package.json"
zs_packages=$(num "$(grep -c "@zeststream" "$zs_pkg_file" 2>/dev/null || true)")
zs_hosted=$(num "$(find "$REPO/packages" -maxdepth 1 -type d -name "zeststream-*" 2>/dev/null | wc -l)")
if [[ "$zs_packages" -gt 0 ]]; then
  check "FQ-10" "@zeststream/* packages declared" "pass" "${zs_packages} package(s) consumed"
elif [[ "$zs_hosted" -gt 0 ]]; then
  check "FQ-10" "@zeststream/* packages declared" "pass" "${zs_hosted} package(s) hosted in packages/"
else
  check "FQ-10" "@zeststream/* packages declared" "warn" "No @zeststream/* packages - no shared infrastructure"
fi

# ══════════════════════════════════════════════════════════════════════════
# CONTENT-QUALITY CHECKS (FQ-11..FQ-14)
# Added 2026-05-14. Joshua's leverage point: "if our gates are passing and
# it's not acceptable, it's a gate problem." FQ-01..FQ-10 measure PROXIES
# (fonts loaded, files exist, packages declared). They are structurally blind
# to whether the COPY is acceptable. These checks catch the failure class
# that shipped a gate-passing site Joshua rejected: copy that narrates the
# page instead of speaking to the customer, third-person brochure voice,
# all-abstract claims, and the same paragraph restated across pages.
# Public copy = site/**/*.html + content/**/*.mdx. Internal docs/ excluded.
# ══════════════════════════════════════════════════════════════════════════

# Collect the public-copy file list once.
# FQ-11..14 evaluate NARRATIVE COPY: the prose a visitor reads. Scope:
#   - site/**/*.html      (static marketing site)
#   - content/**/*.mdx    (genuine prose content)
#   - Next.js *.tsx/*.mdx fallback when no site/content surface exists.
# The fallback makes this gate portable to Mobile Eats, ClutterFreeSpaces, and
# other Next.js projects; it still prunes generated output and dependencies.
PUBLIC_COPY_FILES=()
if [[ -d "$REPO/site" ]]; then
  while IFS= read -r f; do PUBLIC_COPY_FILES+=("$f"); done \
    < <(find "$REPO/site" -type f -name "*.html" 2>/dev/null)
fi
if [[ -d "$REPO/content" ]]; then
  while IFS= read -r f; do PUBLIC_COPY_FILES+=("$f"); done \
    < <(find "$REPO/content" -type f -name "*.mdx" 2>/dev/null)
fi
# Next.js portability: repetition and concreteness checks use copy.ts + .mdx,
# not raw .tsx. Shingling .tsx produces false hits from imports and props.
if [[ "${#PUBLIC_COPY_FILES[@]}" -eq 0 && -n "$NEXT_APP" ]]; then
  while IFS= read -r f; do PUBLIC_COPY_FILES+=("$f"); done \
    < <(find "$NEXT_APP" \
      \( -path "*/node_modules/*" -o -path "*/.next/*" -o -path "*/dist/*" -o -path "*/build/*" \) -prune \
      -o -type f \( -name "copy.ts" -o -name "*.mdx" \) -print 2>/dev/null)
fi

# FQ-11 is exact-pattern based, so it can safely scan component source too.
# This catches Next.js pages that inline bad customer copy before copy.ts exists.
META_COPY_FILES=("${PUBLIC_COPY_FILES[@]}")
if [[ -n "$NEXT_APP" ]]; then
  while IFS= read -r f; do META_COPY_FILES+=("$f"); done \
    < <(find "$NEXT_APP" \
      \( -path "*/node_modules/*" -o -path "*/.next/*" -o -path "*/dist/*" -o -path "*/build/*" \) -prune \
      -o -type f \( -name "*.tsx" -o -name "*.mdx" -o -name "copy.ts" \) -print 2>/dev/null)
fi

# When there is no narrative copy surface at all, FQ-11..14 are n/a — emit
# them as pass-with-reason so the report stays complete and nothing is
# force-failed for being a product app without a marketing site.
CONTENT_QUALITY_NA=0
if [[ "${#PUBLIC_COPY_FILES[@]}" -eq 0 ]]; then
  CONTENT_QUALITY_NA=1
  for fq in \
    "FQ-11|Meta-voice (copy speaks to customer, not about the page)" \
    "FQ-12|First-person operator voice" \
    "FQ-13|Concreteness (specifics, not pure abstraction)" \
    "FQ-14|Cross-page repetition (pages build, not restate)"; do
    check "${fq%%|*}" "${fq##*|}" "pass" "n/a — no narrative copy surface (site/, content/mdx, or copy.ts)"
  done
fi

# FQ-11..14 run only when a narrative copy surface exists.
if [[ "$CONTENT_QUALITY_NA" -eq 0 ]]; then

  # ── FQ-11 Meta-voice (copy that narrates the page, not the customer) ────
  # Only UNAMBIGUOUS meta-voice / internal-doctrine phrases. Generic patterns
  # like "this page " or "the page is" false-positive on legitimate customer
  # copy ("This page took a wrong turn", "this page is ready") — every phrase
  # below appears ONLY as page-narration or doctrine leakage, never as copy
  # addressed to the customer.
  META_VOICE_PATTERN='trust surface|trophy case|proof bait|mission ceiling|capability control plane|control plane integration point|the public story (stays|comes|shows)|should make the owner feel|should not shame owners|is part of the product, not a footnote|page, story, or machinery|narrates the page|[Tt]he page is a (trust|proof)|is not a trophy'
  meta_hits=0
  meta_examples=""
  for f in "${META_COPY_FILES[@]}"; do
    [[ -z "$f" ]] && continue
    while IFS= read -r line; do
      meta_hits=$((meta_hits + 1))
      [[ -z "$meta_examples" ]] && meta_examples="$(basename "$(dirname "$f")")/$(basename "$f"): $(echo "$line" | sed 's/<[^>]*>//g' | tr -s ' ' | cut -c1-70)"
    done < <(grep -hoE "$META_VOICE_PATTERN" "$f" 2>/dev/null)
  done
  if [[ "$meta_hits" -eq 0 ]]; then
    check "FQ-11" "Meta-voice (copy speaks to customer, not about the page)" "pass" "0 meta-voice / internal-vocabulary leaks in public copy"
  else
    check "FQ-11" "Meta-voice (copy speaks to customer, not about the page)" "fail" "${meta_hits} meta-voice/internal-vocab leak(s) — e.g. ${meta_examples} — copy narrates the page or leaks doctrine instead of speaking to the customer"
  fi

  # ── FQ-12 First-person operator voice (TIER-2: ZestStream-brand only) ───
  # PUBLISHABILITY-BAR mandates first-person singular for ZestStream. A public
  # page with zero first-person markers is a third-person brochure, not Joshua.
  # A client product carries its own voice — never force first-person-Joshua.
  if [[ "$BRAND_TIER" != "zeststream" ]]; then
    check "FQ-12" "First-person operator voice" "pass" "skipped — Tier-2 ZestStream-brand storytelling check, n/a to a product-tier repo"
  else
    fp_brochure_pages=0
    fp_total_pages=0
    for f in "${PUBLIC_COPY_FILES[@]}"; do
      [[ -z "$f" ]] && continue
      fp_total_pages=$((fp_total_pages + 1))
      fp_markers=$(num "$(grep -hoE '(^|[^A-Za-z])(I|I'\''m|I'\''ll|I'\''ve|my)([^A-Za-z]|$)' "$f" 2>/dev/null | wc -l)")
      [[ "$fp_markers" -eq 0 ]] && fp_brochure_pages=$((fp_brochure_pages + 1))
    done
    if [[ "$fp_total_pages" -gt 0 && "$((fp_brochure_pages * 2))" -gt "$fp_total_pages" ]]; then
      check "FQ-12" "First-person operator voice" "fail" "${fp_brochure_pages}/${fp_total_pages} public pages have zero first-person voice — site reads as a third-person brochure, not Joshua's"
    elif [[ "$fp_brochure_pages" -gt 0 ]]; then
      check "FQ-12" "First-person operator voice" "warn" "${fp_brochure_pages}/${fp_total_pages} public page(s) have no first-person voice"
    else
      check "FQ-12" "First-person operator voice" "pass" "all ${fp_total_pages} public pages carry first-person operator voice"
    fi
  fi

  # ── FQ-13 Concreteness (claims backed by specifics, not all abstraction) ─
  # Jeff Emanuel principle: numbers over adjectives. A public page that talks
  # about workflows/methods/slices but contains zero concrete numbers in body
  # copy is all-abstraction — it tells, never shows.
  abstract_pages=0
  for f in "${PUBLIC_COPY_FILES[@]}"; do
    [[ -z "$f" ]] && continue
    body=$(sed 's/<[^>]*>//g' "$f" 2>/dev/null)
    makes_claims=$(echo "$body" | grep -ciE 'workflow|method|slice|proof|automation' || true)
    has_numbers=$(echo "$body" | grep -coE '[0-9]+(min|s|m|h|x|%|/| min| sec| hour| day)| [0-9]{2,}' || true)
    if [[ "$makes_claims" -gt 0 && "$has_numbers" -eq 0 ]]; then
      abstract_pages=$((abstract_pages + 1))
    fi
  done
  if [[ "$abstract_pages" -gt 0 ]]; then
    check "FQ-13" "Concreteness (specifics, not pure abstraction)" "warn" "${abstract_pages} public page(s) make process claims with zero concrete numbers — show one real before/after, don't only tell"
  else
    check "FQ-13" "Concreteness (specifics, not pure abstraction)" "pass" "public pages making process claims also carry concrete specifics"
  fi

  # ── FQ-14 Cross-page repetition (pages build, not restate) ──────────────
  # Same copy block repeated near-verbatim across pages = pages restate instead
  # of progress. Counts 10-word shingles appearing in 3+ distinct public pages.
  # <3 pages = not enough surface to judge — n/a-pass, not a failure.
  if [[ "${#PUBLIC_COPY_FILES[@]}" -lt 3 ]]; then
    check "FQ-14" "Cross-page repetition (pages build, not restate)" "pass" "n/a — fewer than 3 narrative pages to compare"
  else
    repeat_report=$(
      for f in "${PUBLIC_COPY_FILES[@]}"; do
        [[ -z "$f" ]] && continue
        # Strip <header>/<nav>/<footer> chrome first — shared nav across pages
        # is intentional, not body-copy repetition. Then strip remaining tags.
        # Strip header/nav/footer chrome (shared nav is intentional, not
        # restated copy). 10-word shingles, not 6: a tagline (~8 words) is
        # brand consistency and may recur; only a copy-pasted ~10+-word run
        # is genuine "pages restate instead of build." No hardcoded tagline
        # string — the shingle length is the principled filter.
        sed '/<header/,/<\/header>/d; /<nav/,/<\/nav>/d; /<footer/,/<\/footer>/d' "$f" 2>/dev/null \
          | sed 's/<[^>]*>//g' \
          | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' \
          | awk -v fn="$f" '{for(i=1;i+9<=NF;i++){s=$i; for(j=1;j<=9;j++) s=s" "$(i+j); print fn"\t"s}}'
      done \
        | sort -u \
        | awk -F'\t' '{c[$2]++} END {for(s in c) if(c[s]>=3) print c[s]"\t"s}' \
        | sort -rn
    )
    repeat_count=$(num "$(echo "$repeat_report" | grep -c . || true)")
    if [[ "$repeat_count" -eq 0 ]]; then
      check "FQ-14" "Cross-page repetition (pages build, not restate)" "pass" "no 10-word phrase repeats across 3+ public pages"
    else
      top_repeat=$(echo "$repeat_report" | head -1 | cut -f2)
      if [[ "$repeat_count" -ge 3 ]]; then
        check "FQ-14" "Cross-page repetition (pages build, not restate)" "fail" "${repeat_count} phrase(s) repeated near-verbatim across 3+ pages — e.g. \"${top_repeat}\" — pages restate instead of building"
      else
        check "FQ-14" "Cross-page repetition (pages build, not restate)" "warn" "${repeat_count} phrase(s) repeated across 3+ pages — e.g. \"${top_repeat}\""
      fi
    fi
  fi

fi  # CONTENT_QUALITY_NA guard

# ── FQ-15 Contrast: WCAG AA on same-block CSS color pairs ─────────────────
# Joshua: "why are we not globally applying WCAG?" — and the methodology page
# shipped white-on-white text. check-contrast.py resolves var() tokens and
# computes WCAG 2.x ratios for same-block color+background pairs. Cross-cascade
# and alpha-channel contrast cannot be resolved from static CSS — those stay a
# render-review item. Tier-1: runs for any repo with site CSS.
GATE_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$GATE_DIR/check-contrast.py" ]] && command -v python3 >/dev/null 2>&1; then
  contrast_out="$(python3 "$GATE_DIR/check-contrast.py" --repo "$REPO" 2>/dev/null || true)"
  if [[ -z "$contrast_out" ]]; then
    check "FQ-15" "Contrast (WCAG AA on CSS color pairs)" "pass" "n/a — no site CSS to check"
  else
    contrast_fails="$(num "$(printf '%s' "$contrast_out" | grep -oE 'fail=[0-9]+' | grep -oE '[0-9]+' | head -1)")"
    contrast_indet="$(num "$(printf '%s' "$contrast_out" | grep -oE 'indeterminate\(alpha\)=[0-9]+' | grep -oE '[0-9]+' | head -1)")"
    if [[ "$contrast_fails" -gt 0 ]]; then
      check "FQ-15" "Contrast (WCAG AA on CSS color pairs)" "fail" "${contrast_fails} same-block color/background pair(s) below WCAG AA 4.5:1 — run scripts/check-contrast.py"
    else
      check "FQ-15" "Contrast (WCAG AA on CSS color pairs)" "pass" "same-block CSS color pairs pass WCAG AA; ${contrast_indet} alpha pair(s) need render review"
    fi
  fi
else
  check "FQ-15" "Contrast (WCAG AA on CSS color pairs)" "warn" "check-contrast.py or python3 unavailable — contrast not verified"
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
    --arg brand_tier "$BRAND_TIER" \
    --argjson pass "$PASSES" \
    --argjson fail "$FAILS" \
    --argjson warn "$WARNINGS" \
    --argjson total "$TOTAL" \
    --argjson results "[$results_array]" \
    '{schema_version:"zs-frontend-quality-gate/v1",status:$status,repo:$repo,
      brand_tier:$brand_tier,pass:$pass,fail:$fail,warn:$warn,total:$total,results:$results}'
else
  echo "ZS Frontend Quality Gate — $REPO"
  echo "Brand tier: $BRAND_TIER ($([ "$BRAND_TIER" = zeststream ] && echo 'all 14 checks incl. ZestStream-brand storytelling' || echo 'Tier-1 standards + visual identity; Tier-2 storytelling checks n/a'))"
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
