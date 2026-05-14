#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/four-lens-jeff-fail.XXXXXX")"
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
bead="$(cd "$repo" && br create "jeff unmarked contract fixture" --priority 1 --type task --description "fixture" --json | jq -r '.id')"

evidence="$TMP/evidence.md"
cat >"$evidence" <<EOF
# Evidence

did=5/5 didnt=none gaps=none tmp_dir_released=true tests=PASS

Acceptance gates:
- gate one passed with receipt line twelve
- gate two passed with \`$VALIDATOR\`
- gate three passed with executable proof
- br dep cycles: No dependency cycles detected.

Files:
- \`$VALIDATOR\`
- \`.flywheel/scripts/validate-callback-before-close.sh\`
- \`tests/validate-callback-before-close.sh\`

Run:
\`\`\`bash
bash tests/validate-callback-before-close.sh
\`\`\`

Contract receipt: callback close contract.
Payload schema: callback close payload.
Four-Lens Self-Grade: brand voice pass; {operator} sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.
Outcome: this fixture isolates the Jeff contract marker gate.
Result: unmarked contract evidence must block close.
Operator note: all other bar signals are present so the expected reason stays narrow.
Receipt note: the missing marker is the blocker.
EOF

set +e
TMPDIR="$TMP" "$VALIDATOR" --repo "$repo" --bead "$bead" --evidence "$evidence" --json >"$TMP/out.json"
rc=$?
set -e

[ "$rc" -ne 0 ] || fail "expected validator to reject unmarked contract evidence"
jq -e '.verdict == "BLOCK_CLOSE" and .four_lens.jeff.status == "fail" and .four_lens.jeff.reason == "contract_without_version" and (.failures[] | contains("contract_without_version"))' "$TMP/out.json" >/dev/null || {
  jq . "$TMP/out.json" >&2 || true
  fail "expected contract_without_version Jeff failure"
}

printf 'PASS: four-lens Jeff contract marker fail fixture\n'
