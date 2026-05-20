#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mp-scaffolders/MP-91-progress-counter-forced-motion-loop-scaffold.sh"
VALIDATOR="$ROOT/.flywheel/scripts/mp-validators/MP-91-progress-counter-forced-motion-loop-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mp91-scaffold.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/retry-loop.sh"

cat >"$TARGET" <<'EOF'
#!/usr/bin/env bash
# cron dispatch loop retry tick blocker HOLD path without counters.
EOF

if "$VALIDATOR" "$TARGET" >/dev/null 2>&1; then
  printf 'FAIL expected synthetic MP-91 target to fail before scaffold\n' >&2
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
printf 'PASS MP-91 scaffolder fixture\n'
