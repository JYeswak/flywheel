#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

result="$(python3 "$ROOT/scripts/contact_route_probe.py" --file "$ROOT/site/contact/index.html" --json)"

if jq -e '
  .status == "pass"
  and .address == "joshua@zeststream.ai"
  and .subject == "[Flywheel] Public site inquiry"
  and .required_fields == ["message","topic"]
  and .delivery_claim == "mailto_client_open_only"
' <<<"$result" >/dev/null; then
  printf 'PASS contact route uses public address, subject prefix, labels, and mailto fallback\n'
else
  printf 'FAIL contact route uses public address, subject prefix, labels, and mailto fallback\n' >&2
  jq -c . <<<"$result" >&2
  exit 1
fi
