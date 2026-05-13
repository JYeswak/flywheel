#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

required=(
  README.md
  LICENSE
  CHARTER.md
  CHANGELOG.md
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
  SECURITY.md
  SUPPORT.md
  ARCHITECTURE.md
)

for file in "${required[@]}"; do
  if [[ -s "$ROOT/$file" ]]; then
    pass "$file exists"
  else
    fail "$file exists"
  fi
done

if grep -q 'Signed-off-by' "$ROOT/CONTRIBUTING.md"; then
  pass "DCO marker present"
else
  fail "DCO marker present"
fi

if grep -q '^## Why flywheel$' "$ROOT/README.md" \
  && ROOT="$ROOT" python3 <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
readme = (root / "README.md").read_text(encoding="utf-8")
evidence = (root / "docs/evidence/publication-evidence.md").read_text(encoding="utf-8")
readme_match = re.search(
    r"classified ([\d,]+) source files, copied ([\d,]+) public-safe files, excluded\s+"
    r"([\d,]+) denylisted .*?reduced a ([\d,]+)-row manual\s+review queue",
    readme,
    flags=re.S,
)
evidence_match = re.search(
    r"Fresh export status pass with ([\d,]+) classified files, ([\d,]+) copied "
    r"public-safe files, and ([\d,]+) denylist-excluded files; .*? ([\d,]+) "
    r"manual-review rows",
    evidence,
    flags=re.S,
)
run_match = re.search(r"codex-public-export-\d{8}T\d{4}Z", evidence)
if not readme_match or not evidence_match or not run_match:
    sys.exit(1)
readme_counts = tuple(int(value.replace(",", "")) for value in readme_match.groups())
evidence_counts = tuple(int(value.replace(",", "")) for value in evidence_match.groups())
if readme_counts != evidence_counts:
    sys.exit(1)
manifest = root / ".flywheel/extraction/assembly-runs" / run_match.group(0) / "manifest.json"
if manifest.exists():
    data = json.loads(manifest.read_text(encoding="utf-8"))
    classification_path = Path(data["classification_path"])
    manual_review_path = Path(data["manual_review_path"])
    manifest_counts = (
        sum(1 for _ in classification_path.open(encoding="utf-8")),
        int(data["copied_count"]),
        int(data["denylist_excluded_count"]),
        sum(1 for _ in manual_review_path.open(encoding="utf-8")),
    )
    if readme_counts != manifest_counts:
        sys.exit(1)
PY
then
  pass "README has concrete Flywheel metric"
else
  fail "README has concrete Flywheel metric"
fi

if grep -q '^## \[0\.2\.0\] - ' "$ROOT/CHANGELOG.md"; then
  pass "CHANGELOG has 0.2.0 section"
else
  fail "CHANGELOG has 0.2.0 section"
fi

for file in README.md LICENSE CHARTER.md CHANGELOG.md CODE_OF_CONDUCT.md CONTRIBUTING.md SECURITY.md SUPPORT.md ARCHITECTURE.md; do
  if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$ROOT/$file" --json >/dev/null; then
    pass "$file depersonalization scan"
  else
    fail "$file depersonalization scan"
  fi
done

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
