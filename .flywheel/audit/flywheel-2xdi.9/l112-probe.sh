#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
cd "$repo"

test -s .flywheel/audit/flywheel-2xdi.9/evidence.md
test -s .flywheel/audit/flywheel-2xdi.9/compliance-pack.md
test -s .flywheel/audit/flywheel-2xdi.9/validation-receipt.json

rg -q "resolved-by-follow-up-children" .flywheel/audit/flywheel-2xdi.9/evidence.md
rg -q "flywheel-8x2le" .flywheel/audit/flywheel-2xdi.9/evidence.md
rg -q "No .*INCIDENTS.md.*mutation" .flywheel/audit/flywheel-2xdi.9/evidence.md

br show flywheel-13u0 flywheel-13u0.1 flywheel-13u0.2 flywheel-13u0.3 flywheel-13u0.4 flywheel-13u0.5 flywheel-13u0.6 --json \
  | jq -e 'length == 7 and all(.[]; .status == "closed")' >/dev/null
br show flywheel-8x2le --json \
  | jq -e '.[0].status == "open" and (.[0].title | test("source_repo"))' >/dev/null
br show flywheel-2xdi.9 --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | test("resolved-by-follow-up-children"))' >/dev/null

bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-2xdi.9/validation-receipt.json >/dev/null
printf 'flywheel-2xdi.9-l112-pass\n'
