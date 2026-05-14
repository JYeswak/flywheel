#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$ROOT/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_literal() {
  local rel="$1" literal="$2" label="$3"
  if rg -qF -- "$literal" "$ROOT/$rel"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_file "packages/zeststream-story-system/package.json"
require_file "packages/zeststream-story-system/README.md"
require_file "packages/zeststream-story-system/story-system.json"
require_file "packages/zeststream-story-system/tokens.css"
require_file "scripts/validate_story_system_package.py"

require_literal "packages/zeststream-story-system/package.json" "@zeststream/story-system" "package names shared story system"
require_literal "packages/zeststream-story-system/story-system.json" "zeststream.story_system_package.v0" "story system names schema"
require_literal "packages/zeststream-story-system/story-system.json" "OperatingRoomHero" "story system includes operating room hero"
require_literal "packages/zeststream-story-system/story-system.json" "TrustWorryMatrix" "story system includes trust worry matrix"
require_literal "packages/zeststream-story-system/story-system.json" "AI will transform your business" "story system carries blocked hype phrase"
require_literal "packages/zeststream-story-system/tokens.css" "--zs-yuzu: #f2c94c" "package exposes yuzu token"
require_literal "packages/zeststream-story-system/tokens.css" "--zs-lime: #d4f34a" "package exposes lime token"

if python3 "$ROOT/scripts/validate_story_system_package.py" --json >"$ROOT/.flywheel/tmp-story-system-validation.json"; then
  pass "story system package validator"
else
  fail "story system package validator"
fi

rm -f "$ROOT/.flywheel/tmp-story-system-validation.json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
