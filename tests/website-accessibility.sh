#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

result="$(python3 "$ROOT/scripts/website_accessibility.py" --site "$ROOT/site" --json)"

if jq -e '.status == "pass" and .page_count == 6 and .fail_count == 0 and all(.pages[]; .status == "pass")' <<<"$result" >/dev/null; then
  printf 'PASS static accessibility checks report zero errors across public site pages\n'
else
  printf 'FAIL static accessibility checks report zero errors across public site pages\n' >&2
  jq -c '{status, page_count, fail_count, pages}' <<<"$result" >&2
  exit 1
fi
