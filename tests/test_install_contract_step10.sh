#!/usr/bin/env bash
set -euo pipefail

FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need git
need jq
[[ -x "$FLYWHEEL_LOOP_BIN" ]] || fail "flywheel-loop not executable: $FLYWHEEL_LOOP_BIN"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-reconcile-body.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q
mkdir -p "$tmp/.flywheel"

cat >"$tmp/.flywheel/loop.json" <<EOF
{
  "schema_version": 1,
  "repo": "$tmp",
  "repo_realpath": "$tmp",
  "git_root": "$tmp",
  "template_version": "legacy-test"
}
EOF

cat >"$tmp/.flywheel/MISSION.md" <<EOF
---
status: locked
lock_hash: legacy-mission-hash
---
Retain this mission body through reconcile preview.
EOF

cat >"$tmp/.flywheel/GOAL.md" <<EOF
---
status: locked
lock_hash: legacy-goal-hash
---
Retain this goal body through reconcile preview.
EOF

cat >"$tmp/.flywheel/STATE.md" <<EOF
---
status: locked
lock_hash: legacy-state-hash
---
Retain this state body through reconcile preview.
EOF

out="$("$FLYWHEEL_LOOP_BIN" init --reconcile --repo "$tmp" --json 2>/dev/null)"
status="$(jq -r '.status // empty' <<<"$out")"
[[ "$status" == "migration_preview" ]] || fail "expected migration_preview, got: ${status:-<empty>}"

mission_preview="$(jq -r '.preview_paths[] | select(test("(^|/)MISSION[.]md[.]preview[.]"))' <<<"$out" | head -1)"
[[ -n "$mission_preview" && -f "$mission_preview" ]] || fail "missing MISSION preview path"

grep -qF "Retain this mission body through reconcile preview." "$mission_preview" \
  || fail "MISSION preview did not preserve YAML-frontmatter body"

echo "PASS: reconcile preview preserves YAML-frontmatter body"
