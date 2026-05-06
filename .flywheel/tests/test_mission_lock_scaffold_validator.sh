#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-scaffold-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-scaffold-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

section_hash() {
  python3 - "$1" "$2" <<'PY'
import hashlib, re, sys
path, title = sys.argv[1], sys.argv[2]
lines = open(path, encoding="utf-8").read().splitlines()
body, current = [], None
for line in lines:
    m = re.match(r"^##\s+(.+?)\s*$", line)
    if m:
        current = m.group(1).strip()
        continue
    if current and current.lower() == title.lower():
        if not re.search(r"<!--\s*section[_-]hash:", line, re.I):
            body.append(line.rstrip())
while body and body[0] == "":
    body.pop(0)
while body and body[-1] == "":
    body.pop()
print(hashlib.sha256(("\n".join(body) + "\n").encode()).hexdigest())
PY
}

append_hash() {
  local file="$1" title="$2" hash
  hash="$(section_hash "$file" "$title")"
  printf '<!-- section_hash: %s sha256:%s -->\n' "$title" "$hash" >>"$file"
}

write_fixture() {
  local path="$1" mode="${2:-valid}" dir
  dir="$(dirname "$path")"
  mkdir -p "$dir/substrate"
  printf '{"tokens":true}\n' >"$dir/substrate/tokens.json"
  {
    printf '# Fixture Mission\n\n'
    printf 'schema_version: 1\n'
    printf 'doc_type: mission\n'
    printf 'status: locked\n'
    printf 'lock_hash: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n\n'
    printf '## Mission Source\n\nFixture mission source.\n\n'
    if [[ "$mode" != "missing_section" ]]; then
      printf '## North-Star Outcome\n\nDurable mission lock substrate.\n\n'
    fi
    printf '## Primary Beneficiary\n\nFlywheel workers.\n\n'
    printf '## Explicit Non-Goals\n\nNo runtime mutation.\n\n'
    printf '## Safety And Privacy Boundaries\n\nNo secret payloads.\n\n'
    printf '## Evidence That Would Change The Mission\n\nOwner review.\n\n'
    printf '## Owner-Review Cadence\n\nQuarterly.\n\n'
    printf '## Lock Receipt\n\nLocked for scaffold validation.\n'
    if [[ "$mode" == "blocked_readiness" ]]; then
      printf 'blocked_readiness: blocked_phase0_missing\n'
    fi
    printf '\n## Negative invariants (security)\n\n'
    if [[ "$mode" != "empty_negative" ]]; then
      printf -- '- SEC-005: every touched surface declares secret source of truth, principal type, allowed operations, forbidden principals, and service-role/admin credential policy.\n'
    fi
    printf '\n## Substrate inventory\n\n'
    if [[ "$mode" == "bad_substrate" ]]; then
      printf -- '- design tokens: `substrate/missing.json`\n'
    else
      printf -- '- design tokens: `substrate/tokens.json`\n'
    fi
    printf '\n'
  } >"$path"
  append_hash "$path" "Mission Source"
  append_hash "$path" "Negative invariants (security)"
}

run_expect() {
  local name="$1" mode="$2" expected_verdict="$3" jq_expr="$4" fixture out rc
  fixture="$TMP/${name// /_}.md"
  out="$TMP/${name// /_}.json"
  write_fixture "$fixture" "$mode"
  set +e
  "$SCRIPT" --mission "$fixture" --json >"$out"
  rc=$?
  set -e
  if jq -e --arg verdict "$expected_verdict" ".verdict == \$verdict and ($jq_expr)" "$out" >/dev/null; then
    if [[ "$expected_verdict" == "blocked" && "$rc" -eq 1 ]] || [[ "$expected_verdict" != "blocked" && "$rc" -eq 0 ]]; then
      pass "$name"
      return
    fi
  fi
  fail "$name"
  printf 'rc=%s\n' "$rc" >&2
  cat "$out" >&2 || true
}

bash -n "$SCRIPT"
"$SCRIPT" --help | rg -q '^usage:'
"$SCRIPT" --info | jq -e '.name == "mission-lock-scaffold-validator.sh" and .mutates == false and (.canonical_cli_verbs | length == 5)' >/dev/null
"$SCRIPT" --examples --json | jq -e '.examples | length >= 3' >/dev/null
"$SCRIPT" schema --json | jq -e '.required_sections | length >= 9' >/dev/null
pass "canonical CLI metadata"

run_expect "valid mission ready" valid ready '.checks.required_sections_present == "pass" and .checks.section_hashes_match == "pass" and .checks.substrate_inventory_resolves == "pass" and .checks.negative_invariants_non_empty == "pass"'
run_expect "missing required section blocks" missing_section blocked '.checks.required_sections_present == "fail" and (.blockers[] | contains("missing_required_section:North-Star Outcome"))'

hash_bad="$TMP/hash_mismatch.md"
write_fixture "$hash_bad" valid
perl -0pi -e 's/sha256:[0-9a-f]{64}/sha256:0000000000000000000000000000000000000000000000000000000000000000/' "$hash_bad"
set +e
"$SCRIPT" --mission "$hash_bad" --json >"$TMP/hash_mismatch.json"
hash_rc=$?
set -e
if [[ "$hash_rc" -eq 1 ]] && jq -e '.verdict == "blocked" and .checks.section_hashes_match == "fail" and (.blockers[] | startswith("section_hash_mismatch:"))' "$TMP/hash_mismatch.json" >/dev/null; then
  pass "hash mismatch blocks"
else
  fail "hash mismatch blocks"
  cat "$TMP/hash_mismatch.json" >&2 || true
fi

run_expect "substrate pointer missing blocks" bad_substrate blocked '.checks.substrate_inventory_resolves == "fail" and (.blockers[] | startswith("substrate_inventory_unresolved:"))'
run_expect "empty negative invariants blocks" empty_negative blocked '.checks.negative_invariants_non_empty == "fail" and (.blockers[] == "negative_invariants_empty")'
run_expect "blocked readiness state reported" blocked_readiness blocked '(.checks.blocked_readiness_states | index("blocked_phase0_missing")) and (.blockers[] == "blocked_readiness:blocked_phase0_missing")'

"$SCRIPT" --mission "$TMP/valid_mission_ready.md" --quiet >/tmp/mission-lock-scaffold-quiet.out
[[ ! -s /tmp/mission-lock-scaffold-quiet.out ]]
pass "quiet ready emits no text"

printf 'RESULT test_cases=%s failures=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 8 && "$fail_count" == "0" ]]
