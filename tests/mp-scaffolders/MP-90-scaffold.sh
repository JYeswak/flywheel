#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mp-scaffolders/MP-90-adjacent-skill-boundary-router-scaffold.sh"
VALIDATOR="$ROOT/.flywheel/scripts/mp-validators/MP-90-adjacent-skill-boundary-router-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mp90-scaffold.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/skill-router.sh"

cat >"$TARGET" <<'EOF'
#!/usr/bin/env bash
# skill router with handoff and companion options, but no boundary matrix yet.
EOF

if "$VALIDATOR" "$TARGET" >/dev/null 2>&1; then
  printf 'FAIL expected synthetic MP-90 target to fail before scaffold\n' >&2
  exit 1
fi

before="$(shasum -a 256 "$TARGET" | awk '{print $1}')"
"$SCRIPT" --dry-run "$TARGET" >/dev/null
after="$(shasum -a 256 "$TARGET" | awk '{print $1}')"
[[ "$before" == "$after" ]] || { printf 'FAIL dry-run mutated target\n' >&2; exit 1; }

"$SCRIPT" --apply "$TARGET" >/dev/null
"$VALIDATOR" "$TARGET" >/dev/null
again="$(shasum -a 256 "$TARGET" | awk '{print $1}')"
"$SCRIPT" --apply "$TARGET" >/dev/null
stable="$(shasum -a 256 "$TARGET" | awk '{print $1}')"
[[ "$again" == "$stable" ]] || { printf 'FAIL second apply was not idempotent\n' >&2; exit 1; }
printf 'PASS MP-90 scaffolder fixture\n'
