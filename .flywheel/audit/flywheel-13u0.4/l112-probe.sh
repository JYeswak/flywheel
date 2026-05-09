#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
cd "$repo"

test -s .flywheel/audit/flywheel-13u0.4/disposition.md
test -s .flywheel/audit/flywheel-13u0.4/compliance-pack.md
test -s .flywheel/audit/flywheel-13u0.4/validation-receipt.json

rg -q "research-health-prelude-fail" .flywheel/audit/flywheel-13u0.4/disposition.md
rg -q "br-source-repo-dot-after-create" .flywheel/audit/flywheel-13u0.4/disposition.md
rg -q "ntm-pane-unhealthy" .flywheel/audit/flywheel-13u0.4/disposition.md
rg -q "learn-review-and-m964-validate_findings" .flywheel/audit/flywheel-13u0.4/disposition.md
rg -q "intentionally not edited" .flywheel/audit/flywheel-13u0.4/disposition.md

br show flywheel-13u0.5 --json | jq -e '.[0].status == "open" and (.[0].title | test("source_repo dot"))' >/dev/null
br show flywheel-13u0.4 --json | jq -e '.[0].status == "closed" and (.[0].close_reason | test("Dispositioned all four"))' >/dev/null
br show flywheel-e2dj flywheel-ap9n flywheel-0jnj --json | jq -e 'length == 3 and all(.[]; .status == "closed")' >/dev/null
br show flywheel-6tks --json | jq -e '.[0].status == "closed" and (.[0].description | test("research-health-prelude-fail")) and (.[0].description | test("ntm-pane-unhealthy"))' >/dev/null

bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-13u0.4/validation-receipt.json >/dev/null
printf 'flywheel-13u0.4-l112-pass\n'
