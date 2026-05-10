#!/usr/bin/env bash
# tests/codex-release-watchtower-extension.sh
# Bead flywheel-mspmr (AG5): regression coverage for the codex
# release tracker added to jeff-binary-version-watchtower.sh.
#
# The 0.129 canary on flywheel-x2okl proved unstable
# (background-terminal wedge class). Doctrine: HOLD codex 0.129 fleet
# rollout until 0.130 stable cuts. The watchtower extension polls
# openai/codex latestRelease and surfaces a `recanary_recommended`
# signal when the cut happens.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WATCHTOWER="${WATCHTOWER:-$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: watchtower exists + bash -n + carries flywheel-mspmr citation + codex_release_watch fn
if [[ -x "$WATCHTOWER" ]] && bash -n "$WATCHTOWER" 2>/dev/null \
  && grep -q "flywheel-mspmr" "$WATCHTOWER" \
  && grep -q "codex_release_watch" "$WATCHTOWER" \
  && grep -q "recanary_recommended" "$WATCHTOWER"; then
  pass "watchtower has codex_release_watch helper + flywheel-mspmr citation + recanary_recommended signal"
else
  fail "watchtower extension missing or fix not landed"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: schema_version bumped to v3
if grep -qE 'VERSION="jeff-binary-version-watchtower\.v3"' "$WATCHTOWER"; then
  pass "schema_version bumped to v3 (extension is a breaking add to the watchtower envelope)"
else
  fail "schema_version not bumped to v3"
fi

# Test 3: --codex-release-fixture flag is wired
if grep -qE '\-\-codex-release-fixture' "$WATCHTOWER"; then
  pass "--codex-release-fixture flag wired for fixture-test isolation"
else
  fail "--codex-release-fixture flag not wired"
fi

# Build fixtures
FIXTURE_DIR="$(mktemp -d -t codex-release-watchtower.XXXXXX)"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

# Fixture A: hold_target_not_released (latest is 0.129, our held version)
cat >"$FIXTURE_DIR/hold.json" <<'JSON'
{
  "repo": "openai/codex",
  "url": "https://github.com/openai/codex",
  "repo_public": true,
  "latest_release": "rust-v0.129.5",
  "latest_release_normalized": "0.129.5",
  "pushed_at": "2026-05-08T20:00:00Z",
  "hold_version": "0.129",
  "target_version": "0.130",
  "status": "hold_target_not_released",
  "recanary_recommended": false
}
JSON

# Fixture B: target_released (0.130.0 cut)
cat >"$FIXTURE_DIR/target.json" <<'JSON'
{
  "repo": "openai/codex",
  "url": "https://github.com/openai/codex",
  "repo_public": true,
  "latest_release": "rust-v0.130.0",
  "latest_release_normalized": "0.130.0",
  "pushed_at": "2026-05-10T00:36:19Z",
  "hold_version": "0.129",
  "target_version": "0.130",
  "status": "target_released",
  "recanary_recommended": true
}
JSON

# Fixture C: newer_than_target (0.131 cut)
cat >"$FIXTURE_DIR/newer.json" <<'JSON'
{
  "repo": "openai/codex",
  "url": "https://github.com/openai/codex",
  "repo_public": true,
  "latest_release": "rust-v0.131.0",
  "latest_release_normalized": "0.131.0",
  "pushed_at": "2026-05-15T00:00:00Z",
  "hold_version": "0.129",
  "target_version": "0.130",
  "status": "newer_than_target",
  "recanary_recommended": true
}
JSON

# Test 4: hold_target_not_released → recanary_recommended=false (canary stays suspended)
RESULT="$(FRANKENTERM_RELEASE_FIXTURE=/dev/null "$WATCHTOWER" --codex-release-fixture "$FIXTURE_DIR/hold.json" --frankenterm-release-fixture <(echo '[]') --json 2>/dev/null || true)"
if [[ -z "$RESULT" ]]; then
  # Fall back to inline temp fixture for frankenterm
  fzero="$(mktemp -t fz.XXXXXX)"
  echo '[]' >"$fzero"
  RESULT="$("$WATCHTOWER" --codex-release-fixture "$FIXTURE_DIR/hold.json" --frankenterm-release-fixture "$fzero" --json 2>/dev/null || true)"
  rm -f "$fzero"
fi
if jq -e '.watchlists.codex_release.status == "hold_target_not_released" and .watchlists.codex_release.recanary_recommended == false' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "hold_target_not_released fixture → status=hold_target_not_released, recanary_recommended=false"
else
  fail "hold fixture did not surface canonical status; got: $(jq -c '.watchlists.codex_release // {}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 5: target_released → recanary_recommended=true (re-canary signal)
fzero="$(mktemp -t fz.XXXXXX)"; echo '[]' >"$fzero"
RESULT="$("$WATCHTOWER" --codex-release-fixture "$FIXTURE_DIR/target.json" --frankenterm-release-fixture "$fzero" --json 2>/dev/null || true)"
rm -f "$fzero"
if jq -e '.watchlists.codex_release.status == "target_released" and .watchlists.codex_release.recanary_recommended == true' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "target_released fixture → status=target_released, recanary_recommended=true (canonical re-canary signal)"
else
  fail "target fixture did not surface canonical status; got: $(jq -c '.watchlists.codex_release // {}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 6: newer_than_target → recanary_recommended=true (next release after 0.130)
fzero="$(mktemp -t fz.XXXXXX)"; echo '[]' >"$fzero"
RESULT="$("$WATCHTOWER" --codex-release-fixture "$FIXTURE_DIR/newer.json" --frankenterm-release-fixture "$fzero" --json 2>/dev/null || true)"
rm -f "$fzero"
if jq -e '.watchlists.codex_release.status == "newer_than_target" and .watchlists.codex_release.recanary_recommended == true' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "newer_than_target fixture → status=newer_than_target, recanary_recommended=true"
else
  fail "newer fixture did not surface canonical status; got: $(jq -c '.watchlists.codex_release // {}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 7: source_bead is flywheel-mspmr (audit trail back to this dispatch)
fzero="$(mktemp -t fz.XXXXXX)"; echo '[]' >"$fzero"
RESULT="$("$WATCHTOWER" --codex-release-fixture "$FIXTURE_DIR/target.json" --frankenterm-release-fixture "$fzero" --json 2>/dev/null || true)"
rm -f "$fzero"
if jq -e '.watchlists.codex_release.source_bead == "flywheel-mspmr"' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "watchlist row carries source_bead=flywheel-mspmr (audit trail intact)"
else
  fail "source_bead citation missing"
fi

# Test 8: env-configurable hold/target versions
fzero="$(mktemp -t fz.XXXXXX)"; echo '[]' >"$fzero"
RESULT="$(CODEX_HOLD_VERSION=1.0 CODEX_TARGET_VERSION=2.0 "$WATCHTOWER" \
  --codex-release-fixture "$FIXTURE_DIR/target.json" \
  --frankenterm-release-fixture "$fzero" --json 2>/dev/null || true)"
rm -f "$fzero"
# When fixture is supplied, env vars don't override the fixture's hold/target;
# the fixture is canonical. But the env vars must be wired in source.
if grep -qE 'CODEX_HOLD_VERSION|CODEX_TARGET_VERSION' "$WATCHTOWER"; then
  pass "CODEX_HOLD_VERSION + CODEX_TARGET_VERSION env vars wired in source"
else
  fail "codex hold/target env vars not wired"
fi

# Test 9: existing ntm + frankenterm watchlists not regressed
fzero="$(mktemp -t fz.XXXXXX)"; echo '[]' >"$fzero"
RESULT="$("$WATCHTOWER" --frankenterm-release-fixture "$fzero" --codex-release-fixture "$FIXTURE_DIR/target.json" --json 2>/dev/null || true)"
rm -f "$fzero"
if jq -e '
  .schema_version == "jeff-binary-version-watchtower.v3"
  and (.rows | length) >= 1
  and (.rows[0].name == "ntm")
  and (.watchlists.frankenterm_release | type) == "object"
  and (.watchlists.codex_release | type) == "object"
' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "existing ntm + frankenterm watchlists not regressed; codex_release joins as third surface"
else
  fail "envelope shape regression; got: $(jq -c '{schema_version, rows_len: (.rows | length), watchlists: (.watchlists | keys)}' <<<"$RESULT" 2>/dev/null || echo "$RESULT" | head -c 200)"
fi

# Test 10: live probe (no fixture) produces a valid codex_release row
LIVE_RESULT="$("$WATCHTOWER" --json 2>/dev/null || true)"
if jq -e '
  .watchlists.codex_release.repo == "openai/codex"
  and (.watchlists.codex_release.status | test("^(hold_target_not_released|target_released|newer_than_target|unknown)$"))
' >/dev/null 2>&1 <<<"$LIVE_RESULT"; then
  pass "live probe produces canonical codex_release row (status in expected enum)"
else
  fail "live probe codex_release row malformed; got: $(jq -c '.watchlists.codex_release // {}' <<<"$LIVE_RESULT" 2>/dev/null || echo "$LIVE_RESULT" | head -c 200)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
