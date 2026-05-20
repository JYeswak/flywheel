#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mp-scaffolders/MP-97-federated-retrieval-parity-provenance-scaffold.sh"
VALIDATOR="$ROOT/.flywheel/scripts/mp-validators/MP-97-federated-retrieval-parity-provenance-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mp97-scaffold.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/retrieval.sh"

cat >"$TARGET" <<'EOF'
#!/usr/bin/env bash
# qdrant RAG retrieval vector collection source routing without parity proof.
EOF

if "$VALIDATOR" "$TARGET" >/dev/null 2>&1; then
  printf 'FAIL expected synthetic MP-97 target to fail before scaffold\n' >&2
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
printf 'PASS MP-97 scaffolder fixture\n'
