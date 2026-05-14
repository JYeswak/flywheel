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
  assets/operating-room-map.svg; do
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
require_literal "index.html" "Buy back the hours hiding between your tools." "landing leads with owner outcome"
require_literal "index.html" "25+ years in the work" "landing names Joshua operating background"
require_literal "index.html" "MBA" "landing names MBA credential"
require_literal "index.html" "ZIRKEL" "landing names ZIRKEL operating proof"
require_literal "index.html" "I help SMB owners buy their time back." "landing carries ZestStream canon line"
require_literal "index.html" "The Yuzu Method ™" "landing names Yuzu Method with trademark"
require_literal "index.html" "Peel. Press. Pour.™" "landing names Yuzu motto"
require_literal "index.html" "It is Saturday again." "landing opens with a specific owner scene"
require_literal "index.html" "The software is not the problem. The job has no clear path." "landing grounds the workflow problem"
require_literal "index.html" "I had the operations scars before I had the AI tools." "landing answers why Joshua"
require_literal "index.html" "six figures of student debt" "landing origin story includes struggle"
require_literal "index.html" "Twenty minutes, one problem, no pitch at the end." "landing frames low-friction Peel session"
# shellcheck disable=SC2016  # the $ in "$500 Peel Report." is an intentional literal price string, not a shell expansion
require_literal "index.html" "\$500 Peel Report." "landing names public Peel Report price"
require_literal "index.html" "Real work is easier to trust than promises." "landing answers proof-of-work objection"
require_literal "index.html" "regional gym" "landing leads proof with anonymized gym story"
require_literal "index.html" "regional insurance carrier" "landing leads proof with anonymized insurance story"
require_literal "index.html" "Five-system custom app" "landing leads proof with anonymized custom app story"
require_literal "index.html" "No CRM connection. No auto-response. No follow-up." "landing avoids technical cache proof for SMB proof"
require_literal "index.html" "Saturday does not have to be your backup system." "landing paints concrete after-state"
require_literal "index.html" "Monday's report is already built." "landing mirrors Saturday report before-scene"
require_literal "index.html" "Your Saturday is yours again." "landing names bought-back owner time"
require_literal "index.html" "Book a 20-minute Peel session. Free, specific, no pitch at the end." "landing uses brand-voice CTA exemplar"
require_literal "index.html" "Blocked is better than bluffing" "landing names blocked-over-bluffing trust stance"
require_literal "index.html" "Private work stays private." "landing names private work boundary"
require_literal "index.html" "This is not for everyone." "landing includes radical transparency fit filter"
require_literal "methodology/index.html" "This is how I decide where to intervene." "methodology states study-grade method"
require_literal "index.html" "Send me one workflow that keeps getting copied or chased." "landing gives low-friction next step"
require_literal "index.html" "For technical reviewers" "landing shrinks reviewer path near footer"
require_literal "index.html" "experience-hero" "landing uses immersive operating-room visual section"
require_literal "index.html" "operator-board" "landing renders bounded operator hero visual"
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
require_literal "what-is/index.html" "Turn one messy workflow into one safe first fix." "what-is opens with customer outcome"
require_literal "for-developers/index.html" "Claude Code" "developer page names Claude"
require_literal "for-developers/index.html" "Codex CLI" "developer page names Codex"
require_literal "for-developers/index.html" "Gemini CLI" "developer page names Gemini"
require_literal "for-developers/index.html" "OpenClaw" "developer page names OpenClaw"
require_literal "for-developers/index.html" "Jeffrey Emanuel" "developer page credits Jeffrey Emanuel"
require_literal "for-developers/index.html" "Dicklesworthstone" "developer page credits Dicklesworthstone"
require_literal "for-developers/index.html" "NTM" "developer page names NTM"
require_literal "for-developers/index.html" "Agent Mail" "developer page names Agent Mail"
require_literal "for-developers/index.html" "beads" "developer page names beads"
require_literal "for-developers/index.html" "CASS" "developer page names CASS"
require_literal "for-developers/index.html" "JSM" "developer page names JSM"
require_literal "for-developers/index.html" "dcg" "developer page names dcg"
require_literal "for-developers/index.html" "ubs" "developer page names ubs"
require_literal "for-developers/index.html" "caam" "developer page names caam"
require_literal "for-developers/index.html" "frankensqlite" "developer page names frankensqlite"
require_literal "for-developers/index.html" "https://github.com/Dicklesworthstone/ntm" "developer page links NTM repo"
require_literal "for-developers/index.html" "https://github.com/Dicklesworthstone/mcp_agent_mail" "developer page links Agent Mail repo"
require_literal "for-developers/index.html" "https://github.com/Dicklesworthstone/beads_rust" "developer page links beads repo"
require_literal "for-developers/index.html" "https://github.com/Dicklesworthstone/destructive_command_guard" "developer page links dcg repo"
require_literal "for-developers/index.html" "0.007 percent cache hit rate" "developer page owns technical cache before number"
require_literal "for-developers/index.html" "6.37 percent cache hit rate" "developer page owns technical cache after number"
require_literal "for-developers/index.html" "910x improvement, measured." "developer page owns technical measured result"
require_literal "for-developers/index.html" "Flywheel and SkillOS" "developer page names Joshua-built layer"
require_literal "for-developers/index.html" "bash install.sh --dry-run --json" "developer page gives public install dry-run"
require_literal "for-developers/index.html" "github.com/Dicklesworthstone" "developer page links Dicklesworthstone source"
require_literal "for-developers/index.html" "github.com/JYeswak/SkillOS" "developer footer links SkillOS"
require_literal "methodology/index.html" "Donella Meadows taught me to look below the event." "methodology cites Meadows lens"
require_literal "methodology/index.html" "Meadows' 12 leverage points" "methodology names Meadows leverage ladder"
require_literal "methodology/index.html" "Thinking in Systems" "methodology cites Thinking in Systems"
require_literal "methodology/index.html" "Meadows iceberg" "methodology explains iceberg lens"
require_literal "methodology/index.html" "Balancing feedback loop" "methodology maps quality gate to feedback loop"
require_literal "methodology/index.html" "Doctrine accretion is a stock" "methodology maps doctrine accretion to stock"
require_literal "methodology/index.html" "A dirty working tree is not an event problem." "methodology maps dirty tree to structure"
require_literal "methodology/index.html" "Flywheel and SkillOS are separate surfaces with a shared loop." "methodology maps Flywheel and SkillOS"
require_literal "methodology/index.html" "Jeffrey Emanuel" "methodology credits Jeffrey Emanuel"
require_literal "methodology/index.html" "https://www.jeffreyemanuel.com" "methodology links Jeffrey Emanuel site"
require_literal "methodology/index.html" "NTM, Agent Mail, beads, CASS" "methodology credits core Jeffrey substrate names"
require_literal "methodology/index.html" "JSM, dcg, ubs, caam, frankensqlite" "methodology credits extended Jeffrey substrate names"
require_literal "methodology/index.html" "section-theater dark" "methodology renders system map on dark surface"
require_literal "methodology/index.html" "Destructive-command guard" "methodology names destructive safety guard"
require_literal "methodology/index.html" "Cross-repo write guards" "methodology names cross-repo write guard"
require_literal "methodology/index.html" "Recovery bundles" "methodology names recovery bundles"
require_literal "methodology/index.html" "Repo-hygiene invariants" "methodology names repo hygiene invariants"
require_literal "methodology/index.html" "Trust the method means inspect the method." "methodology lands throughline"
require_literal "about/index.html" "joshua@zeststream.ai" "about includes public contact"
require_literal "about/index.html" 'aria-label="Joshua Nowak operator arc"' "about uses purpose-built operator visual"
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
reject_literal "A real slice, from this repo" "self-referential repo slice copy absent"
reject_literal "8/8 frontend quality score" "quality-gate self-story copy absent"
reject_literal "flywheel-t20qk" "internal bead copy absent from homepage"
reject_literal "handoff" "banned handoff word absent from homepage"
reject_literal "transformation" "banned transformation word absent from homepage"
reject_literal "scene-floor" "removed chopped hero floor visual"

if rg -q '<img [^>]*alt=""' "$SITE"; then
  fail "no empty image alt text"
else
  pass "no empty image alt text"
fi

if rg -qF "balancing and reinforcing feedback loops" "$SITE/methodology/index.html" \
  && rg -qF "stocks and flows" "$SITE/methodology/index.html" \
  && rg -qF "Donella Meadows Project archive" "$SITE/methodology/index.html"; then
  pass "methodology translates Meadows lens into study material"
else
  fail "methodology translates Meadows lens into study material"
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
