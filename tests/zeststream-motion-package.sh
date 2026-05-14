#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local path="$1"
  if [[ -s "$ROOT/$path" ]]; then
    pass "file exists: $path"
  else
    fail "file exists: $path"
  fi
}

require_literal() {
  local path="$1"
  local literal="$2"
  local label="$3"
  if rg -qF "$literal" "$ROOT/$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_file "packages/zeststream-motion/package.json"
require_file "packages/zeststream-motion/README.md"
require_file "packages/zeststream-motion/tsconfig.json"
require_file "packages/zeststream-motion/src/index.ts"
require_file "packages/zeststream-motion/src/tokens.ts"
for component in SpringChip SpringSheet ConfidenceBadge StreamingText SkeletonMatch; do
  require_file "packages/zeststream-motion/src/components/${component}.tsx"
done

require_literal "packages/zeststream-motion/package.json" "@zeststream/motion" "motion package name"
require_literal "packages/zeststream-motion/package.json" "./tokens" "motion package exports tokens"
require_literal "packages/zeststream-motion/src/index.ts" "springPresets" "motion index exports spring presets"
require_literal "packages/zeststream-motion/src/tokens.ts" "filterChip" "motion tokens include filter chip preset"
require_literal "packages/zeststream-motion/src/tokens.ts" "sheetSnap" "motion tokens include sheet snap preset"
require_literal "packages/zeststream-motion/README.md" "prefers-reduced-motion" "motion readme names reduced motion"
require_literal "packages/zeststream-motion/README.md" "@zeststream/motion/tokens" "motion readme names token export"
require_literal "scripts/zs-frontend-quality-gate.sh" "@zeststream/motion" "frontend gate recognizes motion package"

if python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
package = json.loads((root / "packages/zeststream-motion/package.json").read_text())
for subpath, target in package.get("exports", {}).items():
    if not (root / "packages/zeststream-motion" / target).exists():
        raise SystemExit(f"missing export target: {target}")
PY
then
  pass "motion package exports point to existing files"
else
  fail "motion package exports point to existing files"
fi

if [[ -x "$ROOT/packages/zeststream-motion/node_modules/.bin/tsc" ]]; then
  if (cd "$ROOT/packages/zeststream-motion" && ./node_modules/.bin/tsc --noEmit); then
    pass "motion package typecheck"
  else
    fail "motion package typecheck"
  fi
else
  pass "motion package typecheck skipped without local node_modules"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
