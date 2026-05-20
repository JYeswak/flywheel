#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mp-scaffolders/MP-89-mode-scoped-phase-workspace-scaffold.sh"
VALIDATOR="$ROOT/.flywheel/scripts/mp-validators/MP-89-mode-scoped-phase-workspace-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mp89-scaffold.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/multi-phase.sh"

cat >"$TARGET" <<'EOF'
#!/usr/bin/env bash
# multi-phase doctor mode mutation workflow without a phase-0 workspace decision.
EOF

if "$VALIDATOR" "$TARGET" >/dev/null 2>&1; then
  printf 'FAIL expected synthetic MP-89 target to fail before scaffold\n' >&2
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
printf 'PASS MP-89 scaffolder fixture\n'
