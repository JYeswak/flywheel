#!/usr/bin/env bash
set -euo pipefail

SCRIPT="${JEFF_SOURCES_REGEN_SCRIPT:-$HOME/.claude/skills/dicklesworthstone-stack/scripts/regen-sources-from-gh.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/regen-sources-from-gh-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_rc() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label rc=$actual expected=$expected"; fi
}

[[ -x "$SCRIPT" ]] || { fail "script executable"; exit 1; }
bash -n "$SCRIPT" && pass "script-syntax"

fixture="$TMP/repos.json"
sources="$TMP/sources.txt"
ledger="$TMP/ledger.jsonl"
dry_json="$TMP/dry.json"
apply_json="$TMP/apply.json"
apply_again_json="$TMP/apply-again.json"
doctor_json="$TMP/doctor.json"
validate_json="$TMP/validate.json"
audit_json="$TMP/audit.json"

cat >"$fixture" <<'JSON'
[
  {
    "name": "AlphaOld",
    "description": "older active repo",
    "isArchived": false,
    "updatedAt": "2026-05-04T01:00:00Z",
    "url": "https://github.com/Dicklesworthstone/AlphaOld"
  },
  {
    "name": "BetaNew",
    "description": "newest active repo | with pipe",
    "isArchived": false,
    "updatedAt": "2026-05-04T03:00:00Z",
    "url": "https://github.com/Dicklesworthstone/BetaNew"
  },
  {
    "name": "GammaMid",
    "description": "",
    "isArchived": false,
    "updatedAt": "2026-05-04T02:00:00Z",
    "url": "https://github.com/Dicklesworthstone/GammaMid"
  },
  {
    "name": "ArchivedRepo",
    "description": "archived tail",
    "isArchived": true,
    "updatedAt": "2026-05-04T04:00:00Z",
    "url": "https://github.com/Dicklesworthstone/ArchivedRepo"
  }
]
JSON

printf 'old manual content\n' >"$sources"
before_sha="$(sha "$sources")"

"$SCRIPT" --fixture "$fixture" --sources-file "$sources" --ledger "$ledger" --now 2026-05-05T00:00:00Z --dry-run --json >"$dry_json"
after_dry_sha="$(sha "$sources")"
if [[ "$before_sha" == "$after_dry_sha" ]]; then pass "dry-run-no-mutate"; else fail "dry-run-no-mutate"; fi
assert_jq "$dry_json" '.action == "dry-run" and .outcome == "planned" and .count == 4 and .archived_count == 1 and .would_write == true' "dry-run-plan-shape"

"$SCRIPT" --fixture "$fixture" --sources-file "$sources" --ledger "$ledger" --now 2026-05-05T00:00:00Z --apply --json >"$apply_json"
if [[ "$(sha "$sources")" != "$before_sha" ]]; then pass "apply-mutates"; else fail "apply-mutates"; fi
backup_path="$(jq -r '.backup_path' "$apply_json")"
if [[ -f "$backup_path" && "$(sha "$backup_path")" == "$before_sha" ]]; then pass "apply-mutates-and-backs-up"; else fail "apply-mutates-and-backs-up"; fi
assert_jq "$apply_json" '.action == "apply" and .outcome == "ok" and .changed == true and .count == 4 and .archived_count == 1' "apply-creates-receipt"
assert_jq "$ledger" 'select(.action == "apply" and .status == "ok" and .count == 4 and .archived_count == 1)' "apply-ledger-row"

mapfile -t lines <"$sources"
if [[ "${lines[0]}" == https://github.com/Dicklesworthstone/BetaNew* &&
      "${lines[1]}" == https://github.com/Dicklesworthstone/GammaMid* &&
      "${lines[2]}" == https://github.com/Dicklesworthstone/AlphaOld* &&
      "${lines[3]}" == https://github.com/Dicklesworthstone/ArchivedRepo* ]]; then
  pass "sort-active-desc-archived-tail"
else
  fail "sort-active-desc-archived-tail"
  printf '%s\n' "${lines[@]}" >&2
fi

if rg -q '^https://github\.com/Dicklesworthstone/BetaNew \| newest active repo with pipe \| false \| 2026-05-04T03:00:00Z$' "$sources" \
  && rg -q '^https://github\.com/Dicklesworthstone/GammaMid \| No description \| false \| 2026-05-04T02:00:00Z$' "$sources"; then
  pass "format-matches-schema"
else
  fail "format-matches-schema"
  sed -n '1,20p' "$sources" >&2
fi

applied_sha="$(sha "$sources")"
"$SCRIPT" --fixture "$fixture" --sources-file "$sources" --ledger "$ledger" --now 2026-05-05T00:00:00Z --apply --json >"$apply_again_json"
if [[ "$(sha "$sources")" == "$applied_sha" ]]; then pass "idempotent-re-apply"; else fail "idempotent-re-apply"; fi
assert_jq "$apply_again_json" '.changed == false and .backup_path == null' "idempotent-receipt"

"$SCRIPT" doctor --sources-file "$sources" --ledger "$ledger" --json >"$doctor_json"
assert_jq "$doctor_json" '.count == 4 and .archive_count == 1 and .freshness != null and .invalid_count == 0' "doctor-shape"

"$SCRIPT" validate --sources-file "$sources" --json >"$validate_json"
assert_jq "$validate_json" '.status == "pass" and .count == 4 and .invalid_count == 0' "validate-good-sources"

malformed="$TMP/malformed.txt"
printf 'not a schema line\n' >"$malformed"
set +e
"$SCRIPT" validate --sources-file "$malformed" --json >"$TMP/malformed.json" 2>/dev/null
malformed_rc=$?
set -e
assert_rc "$malformed_rc" 1 "validate-detects-malformed-lines"
assert_jq "$TMP/malformed.json" '.status == "fail" and .invalid_count == 1' "validate-malformed-json"

"$SCRIPT" audit --ledger "$ledger" --json >"$audit_json"
assert_jq "$audit_json" '(.rows | length) >= 2 and any(.rows[]; .action == "apply")' "audit-lists-past-regens"

if "$SCRIPT" --info | jq -e '(.canonical_cli_surfaces | index("doctor")) and (.canonical_cli_surfaces | index("repair"))' >/dev/null; then pass "info-canonical-triad"; else fail "info-canonical-triad"; fi
if "$SCRIPT" --examples | jq -e '(.examples | length) >= 5' >/dev/null; then pass "examples-json"; else fail "examples-json"; fi
if "$SCRIPT" quickstart | jq -e '(.steps | length) >= 4' >/dev/null; then pass "quickstart-json"; else fail "quickstart-json"; fi
if "$SCRIPT" help validate | jq -e '.topic == "validate"' >/dev/null; then pass "help-topic"; else fail "help-topic"; fi
if "$SCRIPT" completion zsh | rg -q '^#compdef regen-sources-from-gh.sh'; then pass "completion-zsh"; else fail "completion-zsh"; fi

stubbin="$TMP/bin"
mkdir -p "$stubbin"
cat >"$stubbin/gh" <<'SH'
#!/usr/bin/env bash
printf 'API rate limit exceeded for test fixture\n' >&2
exit 1
SH
chmod +x "$stubbin/gh"
set +e
PATH="$stubbin:$PATH" "$SCRIPT" --sources-file "$TMP/rate-limit.txt" --ledger "$ledger" --json >"$TMP/rate-limit.json" 2>/dev/null
rate_rc=$?
set -e
assert_rc "$rate_rc" 3 "gh-api-rate-limit-exits-3"
assert_jq "$TMP/rate-limit.json" '.failure_class == "github_rate_limited"' "rate-limit-json-shape"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL test_regen_sources_from_gh pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS test_regen_sources_from_gh pass=%s fail=%s\n' "$pass_count" "$fail_count"
