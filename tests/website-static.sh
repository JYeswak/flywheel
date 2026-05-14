#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SITE="$ROOT/site"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$SITE/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_literal() {
  local rel="$1" literal="$2" label="$3"
  if rg -qF -- "$literal" "$SITE/$rel"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_literal() {
  local literal="$1" label="$2"
  if rg -qF -- "$literal" "$SITE"; then
    fail "$label"
  else
    pass "$label"
  fi
}

for rel in \
  index.html \
  what-is/index.html \
  for-developers/index.html \
  methodology/index.html \
  about/index.html \
  contact/index.html \
  styles.css \
  visual-system.css \
  assets/operating-room-map.svg \
  assets/loop-map.svg; do
  require_file "$rel"
done

while IFS= read -r -d '' html; do
  rel="${html#"$SITE/"}"
  require_literal "$rel" '<html lang="en">' "lang present: $rel"
  require_literal "$rel" '<meta name="viewport"' "viewport present: $rel"
  require_literal "$rel" '<h1' "h1 present: $rel"
done < <(find "$SITE" -name '*.html' -print0 | sort -z)

require_literal "index.html" "scripts/journey-smoke.sh --matrix reduced --dry-run --json" "landing has reduced first run"
require_literal "index.html" "https://github.com/JYeswak/flywheel" "landing links github"
require_literal "index.html" "Your business already has the data. <span>The work is just trapped between tools.</span>" "landing leads with SMB owner problem"
require_literal "index.html" "The Yuzu Method ™" "landing names Yuzu Method with trademark"
require_literal "index.html" "Peel. Press. Pour.™" "landing names Yuzu motto"
require_literal "index.html" "I help SMB owners buy their time back." "landing carries ZestStream canon line"
require_literal "index.html" "Passing a checklist is not the same as earning trust." "landing names real review failure"
require_literal "index.html" "Blocked is better than bluffing" "landing names blocked-over-bluffing trust stance"
require_literal "index.html" "Private work stays private." "landing names private work boundary"
require_literal "index.html" "copy, check, chase, and remember" "landing names common SMB manual work"
require_literal "methodology/index.html" "20-minute Peel session" "methodology names low-friction Peel session"
require_literal "index.html" "flywheel-t20qk" "landing names concrete improvement bead"
require_literal "index.html" "8/8 frontend quality score" "landing shows real before number"
require_literal "index.html" "Inspect the trajectory" "landing exposes trajectory CTA"
require_literal "index.html" "docs/stories/flywheel-trajectory.md" "landing links generated trajectory"
require_literal "index.html" "experience-hero" "landing uses immersive operating-room visual section"
require_literal "index.html" "scene-route" "landing renders selected slice inside scene"
require_literal "index.html" "Proof states" "landing includes proof states"
for rel in index.html what-is/index.html for-developers/index.html methodology/index.html about/index.html contact/index.html; do
  require_literal "$rel" "experience-hero" "page uses shared immersive hero: $rel"
done
require_literal "visual-system.css" "--zs-lime: #d4f34a" "visual system exposes yuzu lime"
require_literal "visual-system.css" "--zs-yuzu: #f2c94c" "visual system exposes yuzu gold"
require_literal "assets/operating-room-map.svg" "SELECTED WORKFLOW SLICE" "operating map names selected slice"
require_literal "assets/operating-room-map.svg" "PROOF RAIL" "operating map names proof rail"
require_literal "../docs/runbooks/public-site-smb-journey-wireframe.md" "OperatingRoomHero" "wireframe defines reusable OperatingRoomHero primitive"
require_literal "../docs/runbooks/public-site-smb-journey-wireframe.md" "WorkflowMap" "wireframe defines reusable WorkflowMap primitive"
require_literal "../docs/runbooks/public-site-smb-journey-wireframe.md" "SliceWorkbench" "wireframe defines reusable SliceWorkbench primitive"
require_literal "../docs/runbooks/public-site-smb-journey-wireframe.md" "ProofRail" "wireframe defines reusable ProofRail primitive"
require_literal "../docs/runbooks/public-site-smb-journey-wireframe.md" "TrajectoryRail" "wireframe defines reusable TrajectoryRail primitive"
require_literal "what-is/index.html" "Flywheel is how I keep AI work from turning into a mess." "what-is states customer-facing Flywheel purpose"
require_literal "for-developers/index.html" "Claude Code" "developer page names Claude"
require_literal "for-developers/index.html" "Codex CLI" "developer page names Codex"
require_literal "for-developers/index.html" "Gemini CLI" "developer page names Gemini"
require_literal "for-developers/index.html" "OpenClaw" "developer page names OpenClaw"
require_literal "for-developers/index.html" "Reduced local mode" "developer page names reduced mode"
require_literal "for-developers/index.html" "4 named agent lanes carry isolated runtime receipts" "developer page states agent lanes are runtime proven"
require_literal "for-developers/index.html" "operator-provided Codex auth home" "developer page names Codex explicit auth scope"
require_literal "for-developers/index.html" "disposable isolated OpenClaw agent" "developer page names OpenClaw isolated agent proof"
require_literal "methodology/index.html" "Do not automate the mess. Map it first." "methodology names map-before-automation rule"
require_literal "methodology/index.html" "You are right to be careful." "methodology respects owner caution"
require_literal "methodology/index.html" "0.007% cache hit rate" "methodology gives real before number"
require_literal "methodology/index.html" "6.37%" "methodology gives real after number"
require_literal "methodology/index.html" "910× improvement" "methodology gives real improvement number"
require_literal "methodology/index.html" "\$500 Peel Report" "methodology names concrete next step"
require_literal "about/index.html" "joshua@zeststream.ai" "about includes public contact"
require_literal "about/index.html" 'alt="Joshua Nowak and ZestStream operating map for Flywheel"' "about image alt text"
require_literal "contact/index.html" "%5BFlywheel%5D%20Public%20site%20inquiry" "contact uses required subject prefix"
require_literal "contact/index.html" '<label for="topic">' "contact topic label"
require_literal "contact/index.html" '<label for="message">' "contact message label"

for private_term in "Blackfoot" "ALPS" "TerraTitle" "/Users/josh" ".ntm/pids" "mobile-eats"; do
  reject_literal "$private_term" "private term absent: $private_term"
done
reject_literal "Compatibility target until isolated runtime proof exists" "stale compatibility target copy absent"
reject_literal "Compatibility target until daemon or gateway smoke proves behavior" "stale OpenClaw target copy absent"
reject_literal "Agent-specific lanes stay compatibility targets" "stale homepage compatibility paragraph absent"
reject_literal "what an agent remembers from today's session" "session-memory copy absent from public site"
reject_literal "SkillOS is a capability control plane integration point" "meta SkillOS boundary copy absent"
reject_literal "Proof products show the method without becoming the mission ceiling" "meta proof-product copy absent"
reject_literal "The page is a trust surface, not a trophy case" "meta trust-surface copy absent"
reject_literal "make the owner feel" "notes-to-self owner-feel copy absent"
reject_literal "The page should not shame owners for being careful" "notes-to-self shame copy absent"

if rg -q '<img [^>]*alt=""' "$SITE"; then
  fail "no empty image alt text"
else
  pass "no empty image alt text"
fi

if rg -qF "0.007%" "$SITE/methodology/index.html" \
  && rg -qF "6.37%" "$SITE/methodology/index.html" \
  && rg -qF "910× improvement" "$SITE/methodology/index.html"; then
  pass "methodology translates proof into SMB-facing value"
else
  fail "methodology translates proof into SMB-facing value"
fi

if ROOT="$ROOT" python3 <<'PY'
import re
import sys
from pathlib import Path

root = Path(__import__("os").environ["ROOT"])
evidence = (root / "docs/evidence/publication-evidence.md").read_text(encoding="utf-8")
methodology = (root / "site/methodology/index.html").read_text(encoding="utf-8")
evidence_match = re.search(
    r"Fresh export status pass with ([\d,]+) classified files, ([\d,]+) copied "
    r"public-safe files, and ([\d,]+) denylist-excluded files; .*? ([\d,]+) "
    r"manual-review rows",
    evidence,
    flags=re.S,
)
if not evidence_match:
    sys.exit(1)
classified, copied, _excluded, manual_review = evidence_match.groups()
for value in (classified, copied, manual_review):
    if value in methodology:
        sys.exit(1)
PY
then
  pass "methodology keeps audit counts out of SMB copy"
else
  fail "methodology keeps audit counts out of SMB copy"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
