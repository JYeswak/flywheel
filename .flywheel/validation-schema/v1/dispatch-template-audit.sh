#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  printf '{"valid":false,"errors":[{"file":null,"code":"usage","message":"usage: dispatch-template-audit.sh DISPATCH.md [...]"}]}\n' >&2
  exit 2
fi

python3 - "$@" <<'PY'
import json
import sys
from pathlib import Path

REQUIREMENTS = [
    ("validation_block_missing", "VALIDATION BLOCK", "dispatch packet must include a VALIDATION BLOCK"),
    ("schema_ref_missing", ".flywheel/validation-schema/v1/schema.json", "validation schema path must be named"),
    ("parser_ref_missing", ".flywheel/validation-schema/v1/parse.sh", "validation parser path must be named"),
    ("validate_callback_missing", "validate-callback", "orchestrator validate-callback step must be named"),
    ("evidence_field_missing", "evidence=", "callback must include evidence="),
    ("artifact_checks_field_missing", "artifact_checks=", "callback must include artifact_checks="),
    ("four_lens_field_missing", "four_lens=", "callback must include four_lens=brand:N,sniff:N,jeff:N,public:N"),
    ("four_lens_self_grade_missing", "Four-Lens Self-Grade", "dispatch must require a Four-Lens Self-Grade evidence section"),
    ("three_judges_missing", "Three Judges", "dispatch must require the public lens Three Judges check"),
    ("validation_notes_field_missing", "validation_notes=", "callback must include validation_notes="),
    ("files_released_field_missing", "files_released=", "callback must include files_released="),
    ("fuckups_logged_field_missing", "fuckups_logged=", "callback must include fuckups_logged="),
    ("next_phase_field_missing", "next_phase=", "callback must include next_phase="),
    ("chain_if_capacity_field_missing", "chain_if_capacity", "callback must include chain_if_capacity"),
    ("chain_blocked_reason_field_missing", "chain_blocked_reason=", "callback must include chain_blocked_reason="),
    ("bead_receipt_missing", "no_bead_reason=", "callback must include a bead receipt alternative"),
    ("beads_filed_missing", "beads_filed=", "callback must name beads_filed alternative"),
    ("beads_updated_missing", "beads_updated=", "callback must name beads_updated alternative"),
    ("agent_mail_missing", "Agent Mail", "dispatch must mention Agent Mail reservation/release"),
    ("reservation_missing", "reservation", "dispatch must mention file reservation"),
    ("release_missing", "release", "dispatch must mention release"),
    ("l52_missing", "L52", "dispatch must cite L52 bead/no-bead receipt"),
    ("l53_missing", "L53", "dispatch must cite L53 fuckup logging"),
    ("agent_context_missing", "agent execution context", "dispatch must require agent-context runtime proof"),
    ("unknown_nonpass_missing", "status=unknown", "dispatch must state unknown is non-pass"),
]


def check(path: Path):
    try:
        text = path.read_text()
    except Exception as exc:
        return {
            "file": str(path),
            "valid": False,
            "errors": [{"file": str(path), "code": "read_error", "message": str(exc)}],
        }

    errors = []
    for code, needle, message in REQUIREMENTS:
        if needle not in text:
            errors.append({"file": str(path), "code": code, "message": message})

    if not ("DONE" in text and "BLOCKED" in text):
        errors.append({
            "file": str(path),
            "code": "callback_verbs_missing",
            "message": "dispatch must include DONE and BLOCKED callback instructions",
        })

    return {"file": str(path), "valid": not errors, "errors": errors}


results = [check(Path(arg)) for arg in sys.argv[1:]]
errors = []
for result in results:
    errors.extend(result["errors"])

payload = {
    "schema": "dispatch-template-validation/v1",
    "valid": not errors,
    "files_checked": len(results),
    "results": sorted(
        [{"file": r["file"], "valid": r["valid"]} for r in results],
        key=lambda r: r["file"],
    ),
    "errors": sorted(errors, key=lambda e: (e["file"], e["code"], e["message"])),
}
print(json.dumps(payload, indent=2, sort_keys=True))
sys.exit(0 if payload["valid"] else 1)
PY
