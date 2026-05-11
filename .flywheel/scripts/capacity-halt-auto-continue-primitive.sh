#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.3)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VERSION="capacity-halt-auto-continue-primitive.v1.1.0"
SCHEMA_VERSION="capacity-halt-auto-continue/v1"
LEASE_BIN="${CAPACITY_HALT_AUTO_CONTINUE_LEASE:-$SCRIPT_DIR/capacity-halt-lease-primitive.sh}"
NTM_BIN="${CAPACITY_HALT_AUTO_CONTINUE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
SUCCESS_BIN="${CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT:-$SCRIPT_DIR/capacity-halt-success-measurement.sh}"
AUTH_BIN="${CAPACITY_HALT_AUTO_CONTINUE_AUTHORIZATION:-$SCRIPT_DIR/capacity-halt-pane-authorization.sh}"
BUDGET_BIN="${CAPACITY_HALT_AUTO_CONTINUE_BUDGET:-$SCRIPT_DIR/capacity-halt-burst-budget.sh}"
NOTIFY_BIN="${CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN:-/Users/josh/.local/bin/notify}"
FALLBACK_LEDGER="${CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER:-$HOME/.local/state/flywheel/capacity-halt-budget-fallback.jsonl}"
TIMEOUT_SECONDS="${CAPACITY_HALT_AUTO_CONTINUE_TIMEOUT_SECONDS:-8}"
MEASUREMENT_DELAYS="${CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_DELAYS:-3,6,10}"

# ---------- canonical-cli bash-side emitters (added by flywheel-k8gcv.3) ----------

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["session","pane"],
      properties:{
        session:{type:"string",description:"tmux session (e.g., flywheel)"},
        pane:{type:"string",pattern:"^[0-9]+$",description:"numeric pane id"},
        digest:{type:"string",pattern:"^[0-9a-f]{64}$",description:"sha256 of last 30 scrollback lines"},
        scrollback_file:{type:"string",description:"path to scrollback dump; alternative to --digest"},
        ttl:{type:"integer",minimum:1,description:"lease ttl seconds"},
        timeout_seconds:{type:"integer",minimum:1,description:"transport timeout for ntm send continue"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status","session","pane"],
      properties:{
        schema_version:{type:"string"},
        status:{enum:["dry_run","malformed","authorization_refused","budget_exhausted","lease_held_skipped","transport_timeout","fired_success","fired_failed"]},
        session:{type:"string"},
        pane:{type:"string"},
        digest:{type:"string"},
        fired:{type:"boolean"},
        attempted:{type:"boolean"},
        sent:{type:"boolean"},
        recovered:{type:"boolean"},
        dry_run:{type:"boolean"},
        apply:{type:"boolean"}
      }
    },
    exit_codes:{
      "0":"fired-success-or-dry-run-ok",
      "1":"fired-but-failed-recovery",
      "2":"lease-held-skipped",
      "3":"malformed",
      "4":"transport-timeout",
      "5":"protected-refusal",
      "6":"unknown-pane",
      "7":"topology-stale",
      "8":"budget-exhausted"
    }
  }'
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local lease_status="pass"; [[ -x "$LEASE_BIN" ]] || lease_status="fail"
  local ntm_status="pass"; [[ -x "$NTM_BIN" ]] || ntm_status="warn"
  local success_status="pass"; [[ -x "$SUCCESS_BIN" ]] || success_status="warn"
  local auth_status="pass"; [[ -x "$AUTH_BIN" ]] || auth_status="warn"
  local budget_status="pass"; [[ -x "$BUDGET_BIN" ]] || budget_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$FALLBACK_LEDGER")"
  local ledger_status="pass"
  if [[ -e "$FALLBACK_LEDGER" ]]; then
    [[ -w "$FALLBACK_LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$lease_status" "$ntm_status" "$success_status" "$auth_status" "$budget_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" \
    --arg lease_s "$lease_status" --arg lease_path "$LEASE_BIN" \
    --arg ntm_s "$ntm_status" --arg ntm_path "$NTM_BIN" \
    --arg success_s "$success_status" --arg success_path "$SUCCESS_BIN" \
    --arg auth_s "$auth_status" --arg auth_path "$AUTH_BIN" \
    --arg budget_s "$budget_status" --arg budget_path "$BUDGET_BIN" \
    --arg ledger_s "$ledger_status" --arg ledger_path "$FALLBACK_LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for primary apply path"},
        {name:"lease_bin",status:$lease_s,path:$lease_path,detail:"capacity-halt-lease-primitive.sh — required for apply mode"},
        {name:"ntm_bin",status:$ntm_s,path:$ntm_path,detail:"ntm binary for transport (warn if missing — apply will fail)"},
        {name:"success_bin",status:$success_s,path:$success_path,detail:"capacity-halt-success-measurement.sh — required for verdict capture"},
        {name:"auth_bin",status:$auth_s,path:$auth_path,detail:"capacity-halt-pane-authorization.sh — required for pre-fire authorization"},
        {name:"budget_bin",status:$budget_s,path:$budget_path,detail:"capacity-halt-burst-budget.sh — required for burst-budget check"},
        {name:"fallback_ledger",status:$ledger_s,path:$ledger_path,detail:"budget-exhausted fallback signal ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local row_count=0
  local last_class=""
  if [[ -r "$FALLBACK_LEDGER" ]]; then
    row_count="$(wc -l <"$FALLBACK_LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_class="$(tail -n 1 "$FALLBACK_LEDGER" 2>/dev/null | jq -r '.class // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  [[ "$row_count" -gt 100 ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$FALLBACK_LEDGER" --argjson row_count "${row_count:-0}" --arg last_class "${last_class:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,fallback_ledger:$ledger,fallback_row_count:$row_count,last_signal_class:$last_class}'
}

emit_validate() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local rows=0 invalid=0
  if [[ -r "$FALLBACK_LEDGER" ]]; then
    rows="$(wc -l <"$FALLBACK_LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.class // "") == "" or (.session // "") == "" or (.pane // null) == null)' "$FALLBACK_LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$FALLBACK_LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,fallback_ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has class + session + numeric pane"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$FALLBACK_LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$FALLBACK_LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",fallback_ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$FALLBACK_LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$FALLBACK_LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$FALLBACK_LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,fallback_ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|bounded-auto-continue)
      body='Capacity-halt auto-continue sends a single "continue" to a halted codex pane WITH bounded discipline: pre-fire authorization, burst-budget check, lease acquisition, transport with timeout, and post-fire success measurement. Dry-run is the default to enforce explicit --apply.'
      ;;
    apply-vs-dry-run)
      body='--dry-run is the default and emits status=dry_run with would_send=true. --apply requires --session, numeric --pane, and either --digest <sha256> or --scrollback-file. Without --apply the script never sends transport.'
      ;;
    budget-exhausted)
      body='Burst-budget protects the fleet from runaway continue floods. When budget_outcome=ledger_read_error or count exceeds the window, fallback_signal writes a row to fallback-ledger and notifies the operator. Status=budget_exhausted, exit code 8.'
      ;;
    *)
      body="unknown topic: $topic. known: bounded-auto-continue, apply-vs-dry-run, budget-exhausted"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-bounded-auto-continue}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"capacity-halt-auto-continue-primitive.sh doctor --json"},
      {step:2,action:"compute-digest-from-pane",command:"ntm grep . flywheel --cc -n 30 | shasum -a 256"},
      {step:3,action:"dry-run",command:"capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --dry-run --json"},
      {step:4,action:"apply",command:"capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --apply --json"}
    ],
    next_actions:["measure-success-via-capacity-halt-success-measurement.sh","tail-fallback-ledger"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <fallback-ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (fallback-ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    fallback-ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$FALLBACK_LEDGER")"
      present_before="$([[ -f "$FALLBACK_LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$FALLBACK_LEDGER" ]] || : > "$FALLBACK_LEDGER"
      fi
      present_after="$([[ -f "$FALLBACK_LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$FALLBACK_LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,fallback_ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: fallback-ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE python dispatch.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
  doctor) shift; emit_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

python3 - "$VERSION" "$LEASE_BIN" "$NTM_BIN" "$SUCCESS_BIN" "$AUTH_BIN" "$BUDGET_BIN" "$NOTIFY_BIN" "$FALLBACK_LEDGER" "$TIMEOUT_SECONDS" "$MEASUREMENT_DELAYS" "$@" <<'PY'
import argparse, hashlib, json, os, re, subprocess, sys
from pathlib import Path

VERSION, LEASE_BIN, NTM_BIN, SUCCESS_BIN, AUTH_BIN, BUDGET_BIN, NOTIFY_BIN, FALLBACK_LEDGER, TIMEOUT_RAW, MEASUREMENT_DELAYS = sys.argv[1:11]
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
PANE_RE = re.compile(r"^[0-9]+$")

def parse_args():
    p = argparse.ArgumentParser(description="Bounded capacity-halt auto-continue primitive.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--digest", default="")
    p.add_argument("--scrollback-file", default="")
    p.add_argument("--ttl", type=int, default=90)
    p.add_argument("--timeout-seconds", type=int, default=int(TIMEOUT_RAW))
    p.add_argument("--lease-bin", default=LEASE_BIN)
    p.add_argument("--ntm-bin", default=NTM_BIN)
    p.add_argument("--success-bin", default=SUCCESS_BIN)
    p.add_argument("--auth-bin", default=AUTH_BIN)
    p.add_argument("--budget-bin", default=BUDGET_BIN); p.add_argument("--notify-bin", default=NOTIFY_BIN)
    p.add_argument("--fallback-ledger", default=FALLBACK_LEDGER)
    p.add_argument("--measurement-delays", default=MEASUREMENT_DELAYS)
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    return p.parse_args(sys.argv[11:])

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"capacity-halt-auto-continue status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def digest_from_file(path):
    lines = Path(path).read_text(errors="replace").splitlines()[-30:]
    return hashlib.sha256("\n".join(lines).encode()).hexdigest()

def resolve_digest(args):
    if args.digest:
        return args.digest
    if args.scrollback_file:
        return digest_from_file(args.scrollback_file)
    return ""

def lease_call(args, mode, digest, result="success"):
    cmd = [args.lease_bin, f"--{mode}", "--session", args.session, "--pane", args.pane, "--digest", digest, "--json"]
    if mode == "acquire":
        cmd.extend(["--ttl", str(args.ttl)])
    if mode == "release":
        cmd.extend(["--result", result])
    proc = subprocess.run(cmd, text=True, capture_output=True)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "non_json", "stdout": proc.stdout[-500:], "stderr": proc.stderr[-500:]}
    return {"rc": proc.returncode, "payload": payload}

def lease_release(args, digest, result):
    release = lease_call(args, "release", digest, result)
    if result == "timeout" and release["rc"] != 0:
        fallback = lease_call(args, "release", digest, "failure")
        return {"requested_result": "timeout", "primary": release, "fallback": fallback}
    return {"requested_result": result, "primary": release}

def tail_text(value):
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode(errors="replace")[-500:]
    return str(value)[-500:]

def send_continue(args):
    return subprocess.run(
        [args.ntm_bin, "send", args.session, f"--pane={args.pane}", "--no-cass-check", "continue"],
        input="y\n",
        text=True,
        capture_output=True,
        timeout=args.timeout_seconds,
    )

def authorize(args):
    proc = subprocess.run([args.auth_bin, "--session", args.session, "--pane", args.pane, "--json"], text=True, capture_output=True)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "non_json", "role": "unknown", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def authorization_fields(auth):
    payload = auth.get("payload") or {}
    return {
        "authorization": auth,
        "pane_role": payload.get("role") or "unknown",
        "authorization_outcome": payload.get("authorization_outcome") or payload.get("status"),
        "topology_source_ts": payload.get("topology_source_ts"),
        "topology_age_sec": payload.get("topology_age_sec"),
    }

def budget_check(args):
    proc = subprocess.run([args.budget_bin, "--session", args.session, "--pane", args.pane, "--json"], text=True, capture_output=True)
    try: payload = json.loads(proc.stdout)
    except json.JSONDecodeError: payload = {"status": "non_json", "budget_outcome": "ledger_read_error", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def budget_fields(budget):
    payload = budget.get("payload") or {}
    return {"budget": {**payload, "rc": budget.get("rc"), "payload": payload}, "per_pane_count_window": payload.get("per_pane_count_window"), "fleet_count_window": payload.get("fleet_count_window"), "budget_outcome": payload.get("budget_outcome") or payload.get("status")}

def fallback_signal(args, digest, budget, authz):
    payload = budget.get("payload") or {}
    row = {"ts": payload.get("checked_at"), "class": "capacity-halt-budget-exhausted", "session": args.session, "pane": int(args.pane), "digest": digest, "budget_rc": budget["rc"], "budget_outcome": payload.get("budget_outcome") or payload.get("status"), "per_pane_count_window": payload.get("per_pane_count_window"), "fleet_count_window": payload.get("fleet_count_window"), "pane_role": authz.get("pane_role")}
    path = Path(args.fallback_ledger); path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle: handle.write(json.dumps(row, sort_keys=True) + "\n")
    notify = subprocess.run([args.notify_bin, "Capacity halt budget exhausted", f"{args.session}:{args.pane} {row['budget_outcome']}"], text=True, capture_output=True)
    return {"ledger": str(path), "row": row, "notify": {"rc": notify.returncode, "stdout": tail_text(notify.stdout), "stderr": tail_text(notify.stderr)}}

def measure_success(args, digest):
    env = os.environ.copy()
    env["CAPACITY_HALT_SUCCESS_NTM_BIN"] = args.ntm_bin
    proc = subprocess.run(
        [args.success_bin, "--session", args.session, "--pane", args.pane, "--pre-digest", digest, "--sample-delays", args.measurement_delays, "--json"],
        text=True,
        capture_output=True,
        env=env,
    )
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "inconclusive", "verdict": "inconclusive", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-auto-continue.info.v1",
        "command": "info",
        "name": "capacity-halt-auto-continue-primitive",
        "version": VERSION,
        "lease_bin": args.lease_bin,
        "ntm_bin": args.ntm_bin,
        "success_bin": args.success_bin,
        "auth_bin": args.auth_bin,
        "budget_bin": args.budget_bin,
        "notify_bin": args.notify_bin,
        "fallback_ledger": args.fallback_ledger,
        "default_timeout_seconds": int(TIMEOUT_RAW),
        "verbs": ["--info", "--schema", "--help", "--examples", "--json", "--session", "--pane", "--dry-run", "--apply"],
        "subcommands": ["doctor", "health", "validate", "audit", "why", "repair", "quickstart"],
        "capabilities": [
            "bounded-auto-continue",
            "pre-fire-authorization",
            "burst-budget-gate",
            "lease-acquire-release",
            "transport-with-timeout",
            "post-fire-success-measurement",
            "budget-exhausted-fallback-signal"
        ],
        "apply_supported": True,
        "dry_run_supported": True,
        "idempotency_key_required_for_apply": False,
        "mutates_state": True,
        "env_vars": [
            "CAPACITY_HALT_AUTO_CONTINUE_LEASE",
            "CAPACITY_HALT_AUTO_CONTINUE_NTM_BIN",
            "CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT",
            "CAPACITY_HALT_AUTO_CONTINUE_AUTHORIZATION",
            "CAPACITY_HALT_AUTO_CONTINUE_BUDGET",
            "CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN",
            "CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER",
            "CAPACITY_HALT_AUTO_CONTINUE_TIMEOUT_SECONDS",
            "CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_DELAYS",
        ],
        "exit_codes": {"0": "fired-success-or-dry-run-ok", "1": "fired-but-failed-recovery", "2": "lease-held-skipped", "3": "malformed", "4": "transport-timeout", "5": "protected-refusal", "6": "unknown-pane", "7": "topology-stale", "8": "budget-exhausted"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-auto-continue.examples.v1",
        "command": "examples",
        "examples": [
            {"name": "dry_run", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --dry-run --json", "purpose": "default dry-run probe; emits would_send=true without transport"},
            {"name": "apply", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --apply --json", "purpose": "fire bounded auto-continue: authorize, budget, lease, transport, measure"},
            {"name": "scrollback_file", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --scrollback-file /tmp/pane.txt --apply --json", "purpose": "compute digest from a saved scrollback dump instead of --digest"},
            {"name": "doctor", "command": "capacity-halt-auto-continue-primitive.sh doctor --json", "purpose": "verify jq, python3, lease/ntm/success/auth/budget binaries, fallback ledger writable"},
            {"name": "audit", "command": "capacity-halt-auto-continue-primitive.sh audit --json", "purpose": "tail recent budget-exhausted fallback signals"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    dry_run = not args.apply
    if not args.session or not PANE_RE.match(args.pane) or args.ttl <= 0 or args.timeout_seconds <= 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": "session_numeric_pane_ttl_timeout_required", "fired": False}, 3)
    try:
        digest = resolve_digest(args)
    except OSError as exc:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": str(exc), "fired": False}, 3)
    if dry_run:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "dry_run", "session": args.session, "pane": args.pane, "would_send": True, "dry_run": True, "apply": False, "lease_required_for_apply": True, "transport_timeout_seconds": args.timeout_seconds}, 0)
    if not SHA_RE.match(digest):
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": "digest_or_scrollback_file_required_for_apply", "fired": False}, 3)
    auth = authorize(args)
    authz = authorization_fields(auth)
    if auth["rc"] != 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": authz.get("authorization_outcome") or "authorization_refused", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": False, "sent": False, "recovered": False, "reason": (auth.get("payload") or {}).get("refusal_reason"), **authz}, auth["rc"])
    budget = budget_check(args)
    budgetz = budget_fields(budget)
    if budget["rc"] != 0:
        signal = fallback_signal(args, digest, budget, authz)
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "budget_exhausted", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": False, "sent": False, "recovered": False, "reason": budgetz.get("budget_outcome"), "fallback_signal": signal, **authz, **budgetz}, 8)
    lease = lease_call(args, "acquire", digest)
    if lease["rc"] == 1:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "lease_held_skipped", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "lease": lease, **authz, **budgetz}, 2)
    if lease["rc"] != 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "digest": digest, "reason": "lease_acquire_failed", "fired": False, "lease": lease, **authz, **budgetz}, 3)
    try:
        proc = send_continue(args)
    except subprocess.TimeoutExpired as exc:
        release = lease_release(args, digest, "timeout")
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "transport_timeout", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": True, "sent": True, "recovered": False, "transport_timeout_seconds": args.timeout_seconds, "stdout": tail_text(exc.stdout), "stderr": tail_text(exc.stderr), "lease": lease, "release": release, **authz, **budgetz}, 4)
    result = "success" if proc.returncode == 0 else "failure"
    measurement = None
    recovered = False
    if proc.returncode == 0:
        measurement = measure_success(args, digest)
        recovered = measurement["rc"] == 0 and measurement["payload"].get("verdict") == "success"
    release = lease_release(args, digest, "success" if recovered else "failure")
    status = "fired_success" if recovered else "fired_failed"
    emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": status, "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": True, "attempted": True, "sent": proc.returncode == 0, "recovered": recovered, "transport_rc": proc.returncode, "transport_timeout_seconds": args.timeout_seconds, "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr), "lease": lease, "release": release, "success_measurement": measurement, **authz, **budgetz}, 0 if recovered else 1)

if __name__ == "__main__":
    main()
PY
