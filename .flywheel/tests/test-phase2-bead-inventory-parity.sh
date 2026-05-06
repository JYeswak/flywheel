#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ISSUES="$ROOT/.beads/issues.jsonl"
AUDIT="${P2_12_F4_AUDIT:-/tmp/p2-12-f4-bead-inventory-audit-2026-05-06.md}"

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

test -s "$ISSUES" || fail "issues_jsonl_missing"
pass "issues_jsonl_exists"

test -s "$AUDIT" || fail "audit_md_missing"
pass "audit_md_exists"

python3 - "$ROOT" "$ISSUES" <<'PY'
import json
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path

root = Path(sys.argv[1])
issues_path = Path(sys.argv[2])

phase2 = OrderedDict([
    ("P2-01", ("flywheel-4h6c8", ["templates/flywheel-install/polish-gate/v1/manifest.schema.json"])),
    ("P2-02", ("flywheel-3uaa5", ["templates/flywheel-install/polish-gate/discover-surfaces.py"])),
    ("P2-03", ("flywheel-3g6xh", ["templates/flywheel-install/polish-gate/run-grader.py"])),
    ("P2-04", ("flywheel-31bhc", ["templates/flywheel-install/polish-gate/README.md"])),
    ("P2-05", ("flywheel-9xuom", ["templates/flywheel-install/schema.json"])),
    ("P2-06", ("flywheel-1oruh", ["templates/flywheel-install/tests/test_polish_gate_integration.sh"])),
    ("P2-07", ("flywheel-p2-12-f1", [
        ".flywheel/tests/test-doctor-polish-gate-fields.sh",
        ".flywheel/validation-schema/v1/doctor-polish-gate-fields.schema.json",
    ])),
    ("P2-08", ("flywheel-3jq6y", ["templates/flywheel-install/validate-callback-before-close.sh.tmpl"])),
    ("P2-09", ("flywheel-5jq48", ["templates/flywheel-install/scripts/reconcile-polish-gate.sh"])),
    ("P2-10", ("flywheel-ok0yd", ["templates/flywheel-install/polish-gate/v1/scope-allowlist.schema.json"])),
    ("P2-11", ("flywheel-p2-11", [
        "templates/flywheel-install/polish-gate/replay-to-ledger.py",
        "templates/flywheel-install/tests/test_polish_gate_ledger_replay.sh",
    ])),
    ("P2-12", ("flywheel-p2-12", ["templates/flywheel-install/polish-gate/PHASE-2-AUDIT.md"])),
])

rows_by_id = defaultdict(list)
parse_errors = []
with issues_path.open(encoding="utf-8") as handle:
    for lineno, line in enumerate(handle, 1):
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            parse_errors.append(f"line {lineno}: {exc}")
            continue
        issue_id = row.get("id")
        if issue_id:
            rows_by_id[issue_id].append((lineno, row))

if parse_errors:
    raise SystemExit("JSONL parse errors:\n" + "\n".join(parse_errors))

def latest(issue_id):
    rows = rows_by_id.get(issue_id)
    if not rows:
        return None
    return rows[-1]

errors = []
for phase, (issue_id, evidence_paths) in phase2.items():
    item = latest(issue_id)
    if item is None:
        errors.append(f"{phase} missing bead {issue_id}")
        continue
    lineno, row = item
    if row.get("status") != "closed":
        errors.append(f"{phase} {issue_id} latest line {lineno} status={row.get('status')!r}")
    if row.get("status") == "closed" and not row.get("closed_at"):
        errors.append(f"{phase} {issue_id} missing closed_at")
    if row.get("status") == "closed" and not row.get("close_reason"):
        errors.append(f"{phase} {issue_id} missing close_reason")
    for evidence in evidence_paths:
        if not (root / evidence).exists():
            errors.append(f"{phase} {issue_id} missing evidence {evidence}")

alias = latest("flywheel-p2-07")
if alias is None:
    errors.append("P2-07 compatibility id flywheel-p2-07 missing")
else:
    lineno, row = alias
    reason = f"{row.get('close_reason', '')} {row.get('closure_reconciliation_via', '')}"
    if row.get("status") != "closed":
        errors.append(f"P2-07 compatibility row line {lineno} is not closed")
    if row.get("alias_of") != "flywheel-p2-12-f1":
        errors.append(f"P2-07 compatibility row line {lineno} alias_of={row.get('alias_of')!r}")
    if "p2-12-f4" not in reason:
        errors.append(f"P2-07 compatibility row line {lineno} missing p2-12-f4 reconciliation marker")

for issue_id in ("flywheel-p2-12-f1", "flywheel-p2-11", "flywheel-p2-12-f4"):
    item = latest(issue_id)
    if item is None:
        errors.append(f"{issue_id} missing")
        continue
    lineno, row = item
    reason = f"{row.get('close_reason', '')} {row.get('closure_reconciliation_via', '')}"
    if row.get("status") != "closed":
        errors.append(f"{issue_id} latest line {lineno} is not closed")
    if "p2-12-f4" not in reason:
        errors.append(f"{issue_id} latest line {lineno} missing p2-12-f4 reconciliation marker")

if errors:
    raise SystemExit("\n".join(errors))

print("PASS phase2_bead_inventory_parity p2_count=12 alias_count=1 reconciled=3")
PY
pass "phase2_inventory_python_check"

printf 'PASS cases=%s failures=0\n' "$pass_count"
