#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/validate-callback-before-close.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/vcbc.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq
need br
[ -x "$SCRIPT" ] || fail "validator not executable"

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
(cd "$repo" && br init --prefix test >/dev/null)
bead="$(cd "$repo" && br create "validator fixture parent" --priority 1 --type task --description "fixture parent" --json | jq -r '.id')"

good="$TMP/good.md"
cat >"$good" <<EOF
# Evidence
did=4/4 didnt=none gaps=none tests=PASS

Acceptance gates:
- gate 1 passed
- gate 2 passed

Files:
- \`$SCRIPT\`
- \`.flywheel/scripts/validate-callback-before-close.sh\`
- \`.flywheel/canonical-paths.txt\`
- \`tests/validate-callback-before-close.sh\`
- \`templates/flywheel-install/validate-callback-before-close.sh.tmpl\`

Run:
\`\`\`bash
bash tests/validate-callback-before-close.sh
\`\`\`

Contract version: four-lens-close-validator/v1
Four-Lens Self-Grade: brand voice pass; Joshua sniff pass; Jeff doctrine pass; public publishability pass for Three Judges.
Outcome: shipped validator proof reduces false closes and prevents unreviewed bead closeout.
Result: close path stays blocked until the evidence is specific, executable, and public-grade.
EOF

"$SCRIPT" --repo "$repo" --bead "$bead" --evidence "$good" --json >"$TMP/good.json"
jq -e '.verdict == "SAFE_TO_CLOSE" and .four_lens.public.status == "pass"' "$TMP/good.json" >/dev/null || fail "good evidence should pass"

bad="$TMP/bad.md"
cat >"$bad" <<EOF
did=1/4 didnt=3 gaps=none tests=PASS
status: robust solution
EOF

set +e
"$SCRIPT" --repo "$repo" --bead "$bead" --evidence "$bad" --json >"$TMP/bad.json"
bad_rc=$?
set -e
[ "$bad_rc" -eq 1 ] || fail "bad evidence should block"
jq -e '.verdict == "BLOCK_CLOSE" and .auto_rework.action == "would_create" and .four_lens.public.status == "fail"' "$TMP/bad.json" >/dev/null || fail "bad evidence dry-run should plan rework"

set +e
"$SCRIPT" --repo "$repo" --bead "$bead" --evidence "$bad" --apply --json >"$TMP/apply.json"
apply_rc=$?
set -e
[ "$apply_rc" -eq 1 ] || fail "apply still blocks close"
rework="$(jq -r '.auto_rework.bead // empty' "$TMP/apply.json")"
[ -n "$rework" ] || fail "apply should create rework bead"
(cd "$repo" && br show "$rework" >/dev/null) || fail "rework bead not found"

"$SCRIPT" --help >/dev/null
"$SCRIPT" --info >/dev/null
"$SCRIPT" --examples >/dev/null
"$SCRIPT" --version >/dev/null

echo "PASS: validate-callback-before-close"
