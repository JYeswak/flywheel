#!/usr/bin/env bash
set -euo pipefail
TARGET="/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh"
"$TARGET" --help >/dev/null
"$TARGET" capabilities --json | jq -e '.schema_version and (.features or .command)' >/dev/null
"$TARGET" --json | jq -e 'type == "object"' >/dev/null
printf 'PASS .flywheel/scripts/storage-probe.sh agent ergonomics regression\n'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
