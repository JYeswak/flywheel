#!/usr/bin/env bash
set -euo pipefail
VERSION="close-validator-contract-probe/v1"
CONTRACT_VERSION="close-validator-receipt-contract/v1"
CALLBACK_TEXT=""
CALLBACK_FILE=""
CLOSE_LEDGER=""
JSON_OUT=0
QUIET=0
usage() {
  cat <<'USAGE'
usage: close-validator-contract-probe.sh [--callback-file PATH|--callback-text TEXT] [--close-ledger PATH] [--json] [--quiet]
       close-validator-contract-probe.sh --info|--examples|--help
USAGE
}
info() {
  jq -nc --arg version "$VERSION" --arg contract "$CONTRACT_VERSION" '{
    schema_version:"close-validator-contract-probe.info/v1",
    name:"close-validator-contract-probe",
    version:$version,
    contract_version:$contract,
    canonical_cli_flags:["--help","--info","--examples","--json","--quiet"],
    statuses:["pass","fail","duplicate_reconciled"],
    validates:["skill_receipts","stale_routes","credential_immutability","duplicate_close","l112_hashes","sanitized_evidence"]
  }'
}
examples() {
  jq -nc '{schema_version:"close-validator-contract-probe.examples/v1",examples:[
    "close-validator-contract-probe.sh --callback-file /tmp/close-receipt.json --close-ledger .beads/issues.jsonl --json",
    "printf %s \"$DONE_JSON\" | close-validator-contract-probe.sh --json",
    "close-validator-contract-probe.sh --callback-text \"DONE task evidence=/tmp/e.md\" --json"
  ]}'
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --callback-file) CALLBACK_FILE="${2:?--callback-file requires PATH}"; shift 2 ;;
    --callback-file=*) CALLBACK_FILE="${1#*=}"; shift ;;
    --callback-text) CALLBACK_TEXT="${2:?--callback-text requires TEXT}"; shift 2 ;;
    --callback-text=*) CALLBACK_TEXT="${1#*=}"; shift ;;
    --close-ledger) CLOSE_LEDGER="${2:?--close-ledger requires PATH}"; shift 2 ;;
    --close-ledger=*) CLOSE_LEDGER="${1#*=}"; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done
if [[ -n "$CALLBACK_FILE" ]]; then
  CALLBACK_TEXT="$(cat "$CALLBACK_FILE")"
elif [[ -z "$CALLBACK_TEXT" && ! -t 0 ]]; then
  CALLBACK_TEXT="$(cat)"
fi
result="$(python3 - "$CONTRACT_VERSION" "$CLOSE_LEDGER" "$CALLBACK_TEXT" <<'PY'
import hashlib, json, re, sys
from pathlib import Path
contract, ledger, raw = sys.argv[1], sys.argv[2], sys.argv[3]
failures, warnings = [], []
def sha256_text(value):
    return "sha256:" + hashlib.sha256(str(value).encode("utf-8")).hexdigest()
def add(code, detail):
    failures.append({"code": code, "detail": detail})
try:
    receipt = json.loads(raw or "{}")
    input_mode = "json"
except Exception as exc:
    receipt = {"raw_callback_text": raw, "parse_error": str(exc)}
    input_mode = "text"
    add("structured_receipt_required", "strict close requires JSON receipt fields")

secret_patterns = [
    ("anthropic_key", r"sk-ant-[A-Za-z0-9_-]{8,}"),
    ("openai_key", r"sk-proj-[A-Za-z0-9_-]{8,}|sk-[A-Za-z0-9]{20,}"),
    ("github_token", r"(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+"),
    ("aws_access_key", r"A(?:KIA|SIA)[A-Z0-9]{16}"),
    ("google_api_key", r"AIza[A-Za-z0-9_-]{20,}"),
    ("jwt", r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"),
    ("bearer_token", r"Bearer\s+[A-Za-z0-9._-]{16,}"),
    ("slack_token", r"xox[baprs]-[A-Za-z0-9-]{10,}"),
    ("near_secret_keyword", r"(?i)(token|secret|password|pat)[^\\n]{0,24}[A-Za-z0-9+/._-]{32,}"),
]

def walk(obj, path="$"):
    if isinstance(obj, dict):
        for key, value in obj.items():
            yield from walk(value, f"{path}.{key}")
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            yield from walk(value, f"{path}[{idx}]")
    elif isinstance(obj, str):
        yield path, obj

for path, value in walk(receipt):
    if "[SCRUBBED:" in value:
        continue
    for name, pattern in secret_patterns:
        if re.search(pattern, value):
            add("secret_value_present", f"{path} matched {name}")
            break

skills = receipt.get("skill_receipts") if isinstance(receipt, dict) else None
if not isinstance(skills, list) or not skills:
    add("missing_skill_receipts", "skill_receipts[] is required and non-empty")
else:
    required = ("schema_version","receipt_identity_key","skill","resolved_to","source","path","sha","version","freshness_status","route_allowed","checked_at","action_taken","policy_version")
    for idx, skill in enumerate(skills):
        if not isinstance(skill, dict):
            add("malformed_skill_receipt", f"skill_receipts[{idx}] is not an object")
            continue
        for field in required:
            if field not in skill or skill.get(field) in ("", None):
                add("skill_receipt_missing_field", f"skill_receipts[{idx}].{field}")
        if skill.get("route_allowed") is not True:
            add("stale_or_blocked_skill_route", f"{skill.get('skill','<unknown>')} route_allowed is not true")
        if str(skill.get("freshness_status","")).lower() not in {"fresh","current","warn"}:
            add("stale_or_blocked_skill_route", f"{skill.get('skill','<unknown>')} freshness_status={skill.get('freshness_status')}")
        if skill.get("credential_touch") is True:
            if skill.get("secret_value_allowed") is not False:
                add("credential_receipt_allows_secret_value", skill.get("skill","<unknown>"))
            if not skill.get("safe_wrapper") or skill.get("safe_wrapper") == "n/a":
                add("credential_receipt_missing_safe_wrapper", skill.get("skill","<unknown>"))

l112 = receipt.get("l112") if isinstance(receipt, dict) else None
if not isinstance(l112, dict):
    add("missing_l112_receipt", "l112 object is required")
else:
    observed = str(l112.get("observed",""))
    expected = str(l112.get("expected",""))
    if not observed or not expected or observed != expected:
        add("l112_observed_mismatch", f"observed={observed!r} expected={expected!r}")
    if l112.get("output_hash") and l112.get("output_hash") != sha256_text(observed):
        add("l112_output_hash_mismatch", "output_hash does not match observed output")
    if l112.get("command_hash") and l112.get("command") and l112.get("command_hash") != sha256_text(l112.get("command")):
        add("l112_command_hash_mismatch", "command_hash does not match command")

duplicate_line = None
close_key = receipt.get("close_identity_key") if isinstance(receipt, dict) else None
ref_id = receipt.get("ref_id") if isinstance(receipt, dict) else None
if ledger:
    path = Path(ledger).expanduser()
    if path.exists():
        for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
            try:
                row = json.loads(line)
            except Exception:
                continue
            if close_key and row.get("close_identity_key") == close_key:
                duplicate_line = line_no
            if ref_id and row.get("event") == "close" and row.get("ref_id") == ref_id:
                duplicate_line = line_no

duplicate_reconciled = False
if duplicate_line is not None:
    if receipt.get("dedupe_policy") != "latest-row-by-ref_id-event":
        add("duplicate_close_missing_dedupe_policy", f"duplicate found at line {duplicate_line}")
    elif not receipt.get("previous_close_row"):
        add("duplicate_close_missing_previous_row", f"duplicate found at line {duplicate_line}")
    else:
        duplicate_reconciled = True
        warnings.append({"code":"duplicate_close_reconciled","detail":f"prior close row {duplicate_line}"})

valid = not failures
status = "fail"
if valid and duplicate_reconciled:
    status = "duplicate_reconciled"
elif valid:
    status = "pass"
out = {
    "schema_version": "close-validator-contract-probe.result/v1",
    "contract_version": contract,
    "status": status,
    "valid": valid,
    "input_mode": input_mode,
    "skill_receipts_count": len(skills) if isinstance(skills, list) else 0,
    "duplicate_close_reconciled": duplicate_reconciled,
    "duplicate_close_line": duplicate_line,
    "failures": failures,
    "warnings": warnings,
}
print(json.dumps(out, sort_keys=True, separators=(",", ":")))
PY
)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$result"
else
  [[ "$QUIET" -eq 1 ]] || printf '%s valid=%s failures=%s\n' "$(jq -r '.status' <<<"$result")" "$(jq -r '.valid' <<<"$result")" "$(jq -r '.failures | length' <<<"$result")"
fi

if jq -e '.valid == true' >/dev/null <<<"$result"; then
  exit 0
fi
exit 1
