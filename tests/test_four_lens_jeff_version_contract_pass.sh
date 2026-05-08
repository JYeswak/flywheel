#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/four-lens-jeff-pass.XXXXXX")"
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
bead="$(cd "$repo" && br create "jeff versioned contract fixture" --priority 1 --type task --description "fixture" --json | jq -r '.id')"

evidence="$TMP/evidence.md"
cat >"$evidence" <<EOF
---
schema_version: fixture-contract/v1
contract_version: callback-close-contract/v1
receipt_schema_version: four-lens-close-validator/v1
---

# Evidence

did=5/5 didnt=none gaps=none tmp_dir_released=true tests=PASS

Acceptance gates:
- gate 1 passed with receipt line 12
- gate 2 passed with \`$VALIDATOR\`
- gate 3 passed with \`tests/test_four_lens_jeff_version_contract_pass.sh\`
- br dep cycles: No dependency cycles detected.

Files:
- \`$VALIDATOR\`
- \`tests/test_four_lens_jeff_version_contract_pass.sh\`
- \`.flywheel/validation-schema/v1/tick-receipt.schema.json\`

Run:
\`\`\`bash
bash tests/test_four_lens_jeff_version_contract_pass.sh
\`\`\`

Contract receipt: fixture-contract/v1.
Payload schema: fixture-payload/v1.
Four-Lens Self-Grade: brand voice pass; Joshua sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.
Outcome: versioned contract evidence prevents silent ingestion drift.
Result: the Jeff lens accepts explicit schema_version and v1 markers.
EOF

TMPDIR="$TMP" "$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$evidence" --json >"$TMP/out.json"
jq -e '.verdict == "SAFE_TO_CLOSE" and .four_lens.jeff.status == "pass"' "$TMP/out.json" >/dev/null || {
  jq . "$TMP/out.json" >&2 || true
  fail "expected Jeff lens pass for versioned contract evidence"
}

printf 'PASS: four-lens Jeff version contract pass fixture\n'
