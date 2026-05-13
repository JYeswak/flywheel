#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tmp-prune.sh"
PLIST="$ROOT/.flywheel/launchd/com.zeststream.tmp-prune.plist"
TEMPLATE_SCRIPT="$ROOT/templates/flywheel-install/.flywheel/scripts/tmp-prune.sh"
TEMPLATE_PLIST="$ROOT/templates/flywheel-install/.flywheel/launchd/com.zeststream.tmp-prune.plist"
TMP="$(mktemp -d -t mplb3.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_old_dir() {
  local path="$1"
  mkdir -p "$path"
  printf 'payload\n' >"$path/payload.txt"
  touch -t 202001010101 "$path/payload.txt" "$path"
}

make_new_dir() {
  local path="$1"
  mkdir -p "$path"
  printf 'payload\n' >"$path/payload.txt"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
bash -n "$TEMPLATE_SCRIPT" && pass "template_script_syntax" || fail "template_script_syntax"
plutil -lint "$PLIST" >/dev/null && pass "plist_lint" || fail "plist_lint"
plutil -lint "$TEMPLATE_PLIST" >/dev/null && pass "template_plist_lint" || fail "template_plist_lint"

fixture="$TMP/private-tmp"
receipts="$TMP/receipts"
mkdir -p "$fixture" "$receipts"

for name in \
  "alps.fixture" \
  "{session}-fixture" \
  "flywheel-fixture" \
  "beads.fixture" \
  "beads_fixture" \
  "claude-skills-sync" \
  "{proof-product}-fixture" \
  "br-fixture"
do
  make_old_dir "$fixture/$name"
done
make_new_dir "$fixture/alps.new"
make_old_dir "$fixture/com.apple.fixture"
make_old_dir "$fixture/launchd-fixture"
make_old_dir "$fixture/random-fixture"

FLYWHEEL_TMP_PRUNE_RECEIPT_DIR="$receipts" \
  "$SCRIPT" --root "$fixture" --days 1 --dry-run --json >"$TMP/dry.json"

assert_jq "$TMP/dry.json" '.schema_version == "tmp-prune/v1" and .dry_run == true and .apply == false and .status == "dry_run"' "dry_run_contract"
assert_jq "$TMP/dry.json" '.paths_to_prune_count == 8' "allowlisted_old_count"
assert_jq "$TMP/dry.json" '[.paths_to_prune[].basename] | sort == ["alps.fixture","{session}-fixture","beads.fixture","beads_fixture","br-fixture","claude-skills-sync","flywheel-fixture","{proof-product}-fixture"]' "dry_run_exact_manifest"
assert_jq "$TMP/dry.json" '.bytes_to_prune > 0 and (.paths_to_prune[] | has("bytes") and has("mtime_epoch"))' "bytes_and_mtime_recorded"
assert_jq "$TMP/dry.json" '.excluded.forbidden_prefix_count == 2 and .excluded.unknown_prefix_count == 1' "forbidden_and_unknown_excluded"
assert_jq "$TMP/dry.json" '[.paths_to_prune[].basename] | index("com.apple.fixture") == null and index("launchd-fixture") == null and index("random-fixture") == null and index("alps.new") == null' "dcg_allowlist_excludes_forbidden_unknown_and_new"
assert_jq "$TMP/dry.json" '.receipt_path | startswith("'"$receipts"'")' "receipt_path_under_owner_state"
[ -s "$(jq -r '.receipt_path' "$TMP/dry.json")" ] && pass "receipt_written" || fail "receipt_written"

if FLYWHEEL_TMP_PRUNE_RECEIPT_DIR="$receipts" "$SCRIPT" --root "$fixture" --apply --json >"$TMP/apply-without-key.json" 2>"$TMP/apply-without-key.err"; then
  fail "apply_requires_key"
else
  grep -q -- "--apply requires --idempotency-key" "$TMP/apply-without-key.err" && pass "apply_requires_key" || fail "apply_requires_key"
fi

assert_jq "$TMP/dry.json" '.allowlist_prefixes == ["alps.*","{session}*","flywheel-*","beads.*","beads_*","claude-skills-sync","{proof-product}-*","br-*"]' "allowlist_shape"

if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL: %s failures, %s passes\n' "$fail_count" "$pass_count" >&2
  exit 1
fi
printf 'PASS: %s checks\n' "$pass_count"
