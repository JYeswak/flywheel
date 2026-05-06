#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VERSION="golden-fixture-replay-runner/v1"
FIXTURES_DIR="$ROOT/.flywheel/tests/fixtures/mission-lock-paradigm-extension-2026-05-06"
CMD="replay-all"
FIXTURE=""
JSON_OUT=0
QUIET=0

usage() {
  printf '%s\n' 'usage: golden-fixture-replay-runner.sh replay --fixture PATH [--json] [--quiet]' '       golden-fixture-replay-runner.sh replay-all|verify-invariants|list-fixtures|schema [--json] [--quiet]' '       golden-fixture-replay-runner.sh --info|--help|--examples [--json]'
}

info() {
  jq -nc --arg version "$VERSION" --arg fixtures "$FIXTURES_DIR" '{name:"golden-fixture-replay-runner.sh",schema_version:$version,fixtures_dir:$fixtures,mutates:false,canonical_cli_verbs:["replay","replay-all","verify-invariants","list-fixtures","schema"],canonical_cli_flags:["--info","--help","--examples","--json","--quiet"],subcommands:["replay","replay-all","verify-invariants"],fixture_count_required:7}'
}

examples() {
  jq -nc '{examples:["golden-fixture-replay-runner.sh replay --fixture .flywheel/tests/fixtures/mission-lock-paradigm-extension-2026-05-06/secret-negative-fixture.json --json","golden-fixture-replay-runner.sh replay-all --json","golden-fixture-replay-runner.sh verify-invariants --json"]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    replay|replay-all|verify-invariants|list-fixtures|schema) CMD="$1"; shift ;;
    --fixture) FIXTURE="${2:?--fixture requires PATH}"; shift 2 ;;
    --fixture=*) FIXTURE="${1#*=}"; shift ;;
    --fixtures-dir) FIXTURES_DIR="${2:?--fixtures-dir requires PATH}"; shift 2 ;;
    --fixtures-dir=*) FIXTURES_DIR="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

python3 - "$ROOT" "$VERSION" "$FIXTURES_DIR" "$CMD" "$FIXTURE" "$JSON_OUT" "$QUIET" <<'PY'
import json, subprocess, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1])
version, fixtures_dir, cmd, fixture_arg = sys.argv[2], Path(sys.argv[3]), sys.argv[4], sys.argv[5]
json_out, quiet = sys.argv[6] == "1", sys.argv[7] == "1"

REQUIRED_FINDINGS = {"SEC-004","IDEM-001","IDEM-003","IDEM-005","CSR-001","CSR-004","CSR-006"}
REQUIRED_WAVES = [".flywheel/scripts/mission-lock-negative-invariants-validator.sh",".flywheel/scripts/idempotency-replay-guard.sh",".flywheel/scripts/dispatch-author-contract-probe.sh",".flywheel/scripts/close-validator-contract-probe.sh",".flywheel/scripts/plan-state-lens-merge.sh",".flywheel/scripts/mission-lock-scaffold-validator.sh",".flywheel/scripts/mission-lock-readiness-doctor.sh",".flywheel/scripts/dispatch-self-test-delivery-identity.sh"]

def ts():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
def emit(payload, rc=0):
    if not quiet:
        if json_out or cmd in {"replay","replay-all","verify-invariants","list-fixtures","schema"}:
            print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
        else:
            print(f"status={payload.get('status')} fixtures={payload.get('fixtures_count', payload.get('fixture_id',''))}")
    raise SystemExit(rc)
def run(argv, cwd=None, input_text=None):
    return subprocess.run(argv, cwd=cwd or root, input=input_text, text=True, capture_output=True)
def rel(path):
    p = Path(path)
    return p if p.is_absolute() else root / p
def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))
def fixture_files():
    return sorted(fixtures_dir.glob("*.json"))
def write_lines(path, lines):
    Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")
def codes_from_probe(data):
    return [v.get("code") for v in data.get("violations", [])] + [f.get("code") for f in data.get("failures", [])] + [w.get("code") for w in data.get("warnings", [])]

def replay_dispatch_author(fx, tmp):
    packet = tmp / "dispatch.md"
    write_lines(packet, fx["dispatch_packet_lines"])
    proc = run(["bash", str(root / ".flywheel/scripts/dispatch-author-contract-probe.sh"), "--json", "--dispatch", str(packet)])
    data = json.loads(proc.stdout)
    codes = codes_from_probe(data)
    want = set(fx["expected"]["codes"])
    ok = data.get("verdict") == fx["expected"]["verdict"] and want.issubset(codes)
    return ok, data.get("verdict"), codes, str(packet)

def replay_dispatch_identity(fx, tmp):
    packet, log, locks = tmp / "dispatch.md", tmp / "dispatch-log.jsonl", tmp / "locks"
    write_lines(packet, fx["dispatch_packet_lines"])
    log.write_text("\n".join(json.dumps(row, separators=(",", ":")) for row in fx.get("dispatch_log_rows", [])) + "\n", encoding="utf-8")
    proc = run(["bash", str(root / ".flywheel/scripts/dispatch-self-test-delivery-identity.sh"), "pretest", "--packet", str(packet), "--dispatch-log", str(log), "--lock-dir", str(locks), "--json"])
    data = json.loads(proc.stdout)
    ok = data.get("verdict") == fx["expected"]["verdict"]
    return ok, data.get("verdict"), [data.get("reason","")], str(packet)

def replay_close_validator(fx, tmp):
    receipt, ledger = tmp / "close.json", tmp / "close-ledger.jsonl"
    receipt.write_text(json.dumps(fx["close_receipt"], sort_keys=True) + "\n", encoding="utf-8")
    rows = fx.get("close_ledger_rows", [])
    ledger.write_text("\n".join(json.dumps(row, separators=(",", ":")) for row in rows) + ("\n" if rows else ""), encoding="utf-8")
    argv = ["bash", str(root / ".flywheel/scripts/close-validator-contract-probe.sh"), "--callback-file", str(receipt), "--json"]
    if rows:
        argv += ["--close-ledger", str(ledger)]
    proc = run(argv)
    data = json.loads(proc.stdout)
    codes = codes_from_probe(data)
    want = set(fx["expected"].get("codes", []))
    ok = data.get("status") == fx["expected"]["verdict"] and want.issubset(codes)
    return ok, data.get("status"), codes, str(receipt)

def replay_plan_state_merge(fx, tmp):
    plan = tmp / "plan"; plan.mkdir()
    (plan / "STATE.json").write_text('{"lens_merge_rows":[]}\n', encoding="utf-8")
    for row in fx["lens_rows"]:
        run(["bash", str(root / ".flywheel/scripts/plan-state-lens-merge.sh"), "append", "--plan", str(plan), "--lens", row["lens"], "--row-json", json.dumps(row), "--json"])
    val = json.loads(run(["bash", str(root / ".flywheel/scripts/plan-state-lens-merge.sh"), "validate", "--plan", str(plan), "--json"]).stdout)
    derived = json.loads(run(["bash", str(root / ".flywheel/scripts/plan-state-lens-merge.sh"), "derived", "--plan", str(plan), "--json"]).stdout)
    seen = set(derived.get("audit_lenses_complete", []))
    ok = val.get("status") == "pass" and set(fx["expected"]["lenses"]).issubset(seen)
    return ok, "pass" if ok else "fail", sorted(seen), str(plan / "STATE.json")

def replay_false_positive(fx, tmp):
    packet, log, locks = tmp / "dispatch.md", tmp / "dispatch-log.jsonl", tmp / "locks"
    write_lines(packet, fx["dispatch_packet_lines"])
    log.write_text("", encoding="utf-8")
    pre = json.loads(run(["bash", str(root / ".flywheel/scripts/dispatch-self-test-delivery-identity.sh"), "pretest", "--packet", str(packet), "--dispatch-log", str(log), "--lock-dir", str(locks), "--json"]).stdout)
    codes = []
    if pre.get("verdict") == "proceed" and fx.get("claimed_skill") and not fx.get("route_matches"):
        codes.append("false_positive_skill_claim")
    ok = set(fx["expected"]["codes"]).issubset(codes)
    return ok, "fail" if codes else "pass", codes, str(packet)

def replay_one(path):
    fx = load(path)
    with tempfile.TemporaryDirectory(prefix="golden-fixture-replay.") as td:
        tmp = Path(td)
        handlers = {
            "dispatch_author": replay_dispatch_author,
            "dispatch_identity": replay_dispatch_identity,
            "close_validator": replay_close_validator,
            "plan_state_merge": replay_plan_state_merge,
            "false_positive_self_test": replay_false_positive,
        }
        ok, observed, codes, evidence = handlers[fx["mode"]](fx, tmp)
    return {
        "schema_version": version,
        "ts": ts(),
        "fixture_id": fx["fixture_id"],
        "finding_id": fx["finding_id"],
        "mode": fx["mode"],
        "status": "pass" if ok else "fail",
        "expected_verdict": fx["expected"].get("verdict"),
        "observed_verdict": observed,
        "codes": codes,
        "evidence_path": evidence,
    }

def verify_invariants():
    files = fixture_files()
    loaded = [load(p) for p in files]
    findings = {f.get("finding_id") for f in loaded}
    missing_paths = [p for p in REQUIRED_WAVES if not rel(p).exists()]
    bad = [f.get("fixture_id", str(i)) for i, f in enumerate(loaded) if not all(k in f for k in ("fixture_id","finding_id","mode","expected"))]
    return {
        "schema_version": version,
        "status": "pass" if len(files) >= 7 and REQUIRED_FINDINGS.issubset(findings) and not missing_paths and not bad else "fail",
        "fixtures_count": len(files),
        "findings_covered": sorted(findings),
        "missing_findings": sorted(REQUIRED_FINDINGS - findings),
        "missing_wave_artifacts": missing_paths,
        "malformed_fixtures": bad,
    }

if cmd == "schema":
    emit({"schema_version":version,"fixture_required_fields":["fixture_id","finding_id","mode","expected"],"modes":["dispatch_author","dispatch_identity","close_validator","plan_state_merge","false_positive_self_test"]})
if cmd == "list-fixtures":
    emit({"schema_version":version,"fixtures":[str(p) for p in fixture_files()],"fixtures_count":len(fixture_files())})
if cmd == "verify-invariants":
    payload = verify_invariants(); emit(payload, 0 if payload["status"] == "pass" else 1)
if cmd == "replay":
    if not fixture_arg:
        emit({"schema_version":version,"status":"fail","error":"--fixture required"}, 2)
    result = replay_one(rel(fixture_arg)); emit(result, 0 if result["status"] == "pass" else 1)
if cmd == "replay-all":
    results = [replay_one(p) for p in fixture_files()]
    ok = all(r["status"] == "pass" for r in results) and len(results) >= 7
    emit({"schema_version":version,"status":"pass" if ok else "fail","fixtures_count":len(results),"results":results}, 0 if ok else 1)
emit({"schema_version":version,"status":"fail","error":f"unknown command {cmd}"}, 2)
PY
