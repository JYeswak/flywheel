#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$ROOT"

bash -n tests/doctrine-memory-wire.sh >/dev/null
bash tests/doctrine-memory-wire.sh >/dev/null
rg -n "^## L74 — AGENT-SECURITY-DENY-RULES-CANONICAL" AGENTS.md >/dev/null
rg -n "agent-security-control/v1|security-control" README.md .flywheel/canonical-paths.txt >/dev/null
bash tests/security-control-conformance.sh >/dev/null
bash tests/security-control-fleet-smoke.sh --dry-run >/dev/null
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-03uki-6bba97.md >/dev/null

printf 'PASS\n'
