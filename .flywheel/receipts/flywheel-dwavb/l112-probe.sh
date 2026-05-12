#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
cd "$repo"

rg -Fq 'evidence_redacted=<yes|no|n/a>' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
rg -Fq 'evidence_redacted=<yes|no|n/a>' /Users/josh/.claude/commands/flywheel/worker-tick.md
rg -Fq 'EVIDENCE_REDACTION_PATH_PATTERNS' .flywheel/scripts/validate-callback.py
rg -Fq 'gitleaks --no-git --piped' .flywheel/scripts/validate-callback.py
rg -Fq '"evidence_redaction"' .flywheel/validation-schema/v1/schema.json
rg -Fq 'dwavb evidence-class reservation requires redacted yes' tests/validate-callback.sh

tmp="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-dwavb-l112.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

callback='DONE flywheel-dwavb evidence=/tmp/evidence.md josh_request_id=null files_reserved=reports/evidence/proof.md files_released=reports/evidence/proof.md evidence_redacted=yes no_bead_reason=redacted-evidence'
out="$tmp/validation.json"
evidence="$tmp/evidence.md"
printf '%s\n' 'synthetic redacted evidence' >"$evidence"
callback="DONE flywheel-dwavb evidence=$evidence josh_request_id=null files_reserved=reports/evidence/proof.md files_released=reports/evidence/proof.md evidence_redacted=yes no_bead_reason=redacted-evidence"

python3 .flywheel/scripts/validate-callback.py \
  --dispatch-id flywheel-dwavb-l112 \
  --callback-ref "$callback" \
  --json >"$out"

jq -e '.status == "pass" and .validation_receipt.evidence_redaction.required == true and .validation_receipt.evidence_redaction.evidence_redacted == "yes"' "$out" >/dev/null

printf '%s\n' 'L112_PASS_flywheel-dwavb_evidence_redacted_contract'
