#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/four-lens-did-total.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq
need br

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
(cd "$repo" && br init --prefix test >/dev/null)
bead="$(cd "$repo" && br create "did total structural fixture" --priority 1 --type task --description "fixture" --json | jq -r '.id')"

evidence="$TMP/evidence.md"
cat >"$evidence" <<EOF
---
schema_version: fixture-contract/v1
contract_version: callback-close-contract/v1
receipt_schema_version: four-lens-close-validator/v1
---

# Evidence

did=9/9 didnt=none gaps=none tests=PASS

Acceptance gates:
- gate one passed with receipt line 12.
- gate two passed with \`$VALIDATOR\`.
- gate three passed with \`tests/test_four_lens_validator_did_total_structural.sh\`.
- br dep cycles: No dependency cycles detected.

Files:
- \`$VALIDATOR\`
- \`tests/test_four_lens_validator_did_total_structural.sh\`
- \`.flywheel/scripts/validate-callback-before-close.sh\`

Run:
\`\`\`bash
bash tests/test_four_lens_validator_did_total_structural.sh
\`\`\`

Contract receipt: callback-close-contract/v1.
Payload schema: fixture-payload/v1.
Four-Lens Self-Grade: brand voice pass; Joshua sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.
Outcome: the structural gate prevents all-PASS lens receipts from closing partial work.
Result: did less than total is a close blocker before rubber-stamp drift can enter the bead graph.
Joshua lens: 25-year operations manager judgment says every silenced partial becomes tomorrow's broken regression, so the validator refuses APPROVE_CLOSE on did less than total.
EOF

bad_envelope="DONE fixture did=5/9 didnt=4 gaps=test-continuation tests_passing=true validator_brand_pass=true validator_sniff_pass=true validator_jeff_pass=true validator_public_pass=true"
set +e
"$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$evidence" --envelope "$bad_envelope" --json >"$TMP/bad.json"
bad_rc=$?
set -e

[ "$bad_rc" -eq 1 ] || fail "did less than total envelope should block close"
jq -e '
  .verdict == "BLOCK_CLOSE"
  and .validator_structural_pass == false
  and .envelope_did_total_mismatch == "5/9"
  and .structural.did == "5/9"
  and .structural.didnt == "4"
  and .four_lens.brand.status == "pass"
  and .four_lens.sniff.status == "pass"
  and .four_lens.jeff.status == "pass"
  and .four_lens.public.status == "pass"
  and any(.failures[]; contains("validator_structural_pass=false envelope_did_total_mismatch=5/9"))
' "$TMP/bad.json" >/dev/null || {
  jq . "$TMP/bad.json" >&2 || true
  fail "did less than total structural JSON shape wrong"
}

good_envelope="DONE fixture did=9/9 didnt=none gaps=none tests_passing=true validator_brand_pass=true validator_sniff_pass=true validator_jeff_pass=true validator_public_pass=true"
"$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$evidence" --envelope "$good_envelope" --json >"$TMP/good.json"
jq -e '
  .verdict == "SAFE_TO_CLOSE"
  and .validator_structural_pass == true
  and .envelope_did_total_mismatch == null
  and .structural.did == "9/9"
  and .four_lens.public.status == "pass"
' "$TMP/good.json" >/dev/null || {
  jq . "$TMP/good.json" >&2 || true
  fail "did equals total envelope should pass"
}

printf 'PASS: four-lens validator did-total structural\n'
