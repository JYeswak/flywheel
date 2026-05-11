#!/usr/bin/env bash
# .flywheel/tests/test-mv2th-detector-underfit-fix.sh
# Regression test for flywheel-mv2th.1 archetype detector extension.
#
# Pre-fix: alpsinsurance → unknown, mobile-eats → unknown
# Post-fix: alpsinsurance → fullstack (frontend Next.js + backend Flask)
#          mobile-eats → fullstack (Next.js with co-located app/api routes)
#
# AGs:
#   AG1 — `flywheel docs init --target ~/Developer/alpsinsurance` → archetype=fullstack
#   AG2 — `flywheel docs init --target ~/Developer/mobile-eats` → archetype=fullstack
#   AG3 — regression: flywheel + skillos still return unknown (no false positives)
#   AG4 — synthetic Rails project → backend-service
#   AG5 — synthetic react-native project → mobile-app

set -uo pipefail

FW=/Users/josh/.claude/skills/.flywheel/bin/flywheel

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

probe_archetype() {
  "$FW" docs init --target "$1" --json 2>/dev/null \
    | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("archetype","ERR"))'
}

# AG1
A=$(probe_archetype /Users/josh/Developer/alpsinsurance)
if [[ "$A" == "fullstack" ]]; then
  p "AG1 alpsinsurance → fullstack"
else
  f "AG1 alpsinsurance returned '$A' (expected fullstack)"
fi

# AG2
A=$(probe_archetype /Users/josh/Developer/mobile-eats)
if [[ "$A" == "fullstack" ]]; then
  p "AG2 mobile-eats → fullstack"
else
  f "AG2 mobile-eats returned '$A' (expected fullstack)"
fi

# AG3 — regression: substrate repos (no clean archetype) still return unknown
A=$(probe_archetype /Users/josh/Developer/flywheel)
if [[ "$A" == "unknown" ]]; then
  p "AG3a flywheel (substrate-repo) → unknown (preserved; no false-positive)"
else
  f "AG3a flywheel returned '$A' (expected unknown)"
fi
A=$(probe_archetype /Users/josh/Developer/skillos)
if [[ "$A" == "unknown" ]]; then
  p "AG3b skillos (substrate-repo) → unknown (preserved; no false-positive)"
else
  f "AG3b skillos returned '$A' (expected unknown)"
fi

# AG4 — synthetic Rails project → backend-service
TMP=$(/usr/bin/mktemp -d /tmp/mv2th.1-rails.XXXXXX)
trap "rm -rf $TMP" EXIT
cat > "$TMP/Gemfile" <<'GEM'
source 'https://rubygems.org'
gem 'rails', '~> 7.0'
gem 'pg'
GEM
A=$(probe_archetype "$TMP")
if [[ "$A" == "backend-service" ]]; then
  p "AG4 synthetic Rails Gemfile → backend-service"
else
  f "AG4 synthetic Rails returned '$A' (expected backend-service)"
fi

# AG5 — synthetic react-native project → mobile-app
TMP2=$(/usr/bin/mktemp -d /tmp/mv2th.1-rn.XXXXXX)
trap "rm -rf $TMP $TMP2" EXIT
cat > "$TMP2/package.json" <<'PKG'
{
  "name": "test-rn",
  "dependencies": {
    "react-native": "0.73.0",
    "expo": "~50.0.0"
  }
}
PKG
A=$(probe_archetype "$TMP2")
if [[ "$A" == "mobile-app" ]]; then
  p "AG5 synthetic react-native package.json → mobile-app"
else
  f "AG5 synthetic react-native returned '$A' (expected mobile-app)"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
