#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.4)
set -euo pipefail

VERSION="capacity-halt-lease-primitive.v1.1.0"
SCHEMA_VERSION="capacity-halt-lease/v1"
LEDGER="${CAPACITY_HALT_LEASE_LEDGER:-$HOME/.local/state/flywheel/capacity-halt-lease.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_LEASE_NOW_EPOCH:-}"

# ---------- canonical-cli bash-side emitters (added by flywheel-k8gcv.4) ----------

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["session","pane","digest"],
      properties:{
        session:{type:"string",description:"tmux session"},
        pane:{type:"string",description:"pane id"},
        digest:{type:"string",pattern:"^[0-9a-f]{64}$",description:"sha256 over last 30 scrollback lines"},
        scrollback_file:{type:"string",description:"path to scrollback dump (alternative to --digest)"},
        ttl:{type:"integer",minimum:1,description:"acquire lease ttl seconds"},
        result:{enum:["success","failure","skipped"],description:"release outcome"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status"],
      properties:{
        schema_version:{type:"string"},
        status:{enum:["acquired","released","already_held","malformed","read_error","ok"]},
        session:{type:"string"},
        pane:{type:"string"},
        digest:{type:"string"},
        ledger_written:{type:"boolean"},
        expires_ts:{type:"string"},
        active_until:{type:"string"},
        active_count:{type:"integer"},
        leases:{type:"array"}
      }
    },
    exit_codes:{
      "0":"acquired-or-query-ok",
      "1":"already-held",
      "2":"malformed",
      "3":"read-error"
    }
  }'
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local py_status="pass"; command -v python3 >/dev/null 2>&1 || py_status="fail"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$py_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg py_s "$py_status" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"python3",status:$py_s,detail:"python3 required for acquire/release/list dispatch"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only lease ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local row_count=0
  local active_count=0
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      # active = acquire events with no matching release after them — coarse count via python
      active_count="$(python3 - "$LEDGER" <<'PY' 2>/dev/null || printf 0
import json, sys, time
from pathlib import Path
now = int(time.time())
rows = []
for line in Path(sys.argv[1]).read_text().splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        rows.append(json.loads(line))
    except Exception:
        pass
active = {}
for r in rows:
    key = (r.get("session"), str(r.get("pane")), r.get("digest"))
    ev = r.get("event")
    if ev == "acquire" and int(r.get("expires_epoch") or 0) > now:
        active[key] = r
    elif ev == "release":
        active.pop(key, None)
print(len(active))
PY
)"
      [[ -z "$active_count" ]] && active_count=0
    fi
  fi
  local status="pass"
  [[ "$active_count" -gt 20 ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --argjson active "${active_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger:$ledger,ledger_row_count:$row_count,active_lease_count:$active}'
}

emit_validate() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "capacity-halt-lease.row.v1" or ((.event // "") | test("^(acquire|release)$") | not))' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has schema_version=capacity-halt-lease.row.v1 and event=acquire|release"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|lease-semantics)
      body='Per-(session,pane,digest) idempotency lease. acquire writes an acquire row with expires_epoch=now+ttl; release writes a release row with result=success|failure|skipped. active_lease scan ignores stale acquire rows where epoch >= last release. Default ttl=90s.'
      ;;
    digest-keying)
      body='Digest is sha256 over the last 30 scrollback lines, allowing the same lease to be re-acquired safely if pane state has changed. Different digest = different lease keyspace.'
      ;;
    already-held)
      body='acquire returns status=already_held + exit code 1 when an active acquire row exists for the same (session, pane, digest) and has not expired. Caller MUST treat 1 as a soft refusal — already in flight — not a crash.'
      ;;
    *)
      body="unknown topic: $topic. known: lease-semantics, digest-keying, already-held"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-lease-semantics}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"capacity-halt-lease-primitive.sh doctor --json"},
      {step:2,action:"acquire-lease",command:"capacity-halt-lease-primitive.sh --acquire --session flywheel --pane 3 --digest <sha256> --ttl 90 --json"},
      {step:3,action:"list-active",command:"capacity-halt-lease-primitive.sh --list --json"},
      {step:4,action:"release-lease",command:"capacity-halt-lease-primitive.sh --release --session flywheel --pane 3 --digest <sha256> --result success --json"}
    ],
    next_actions:["dispatch-capacity-halt-auto-continue-primitive","tail-ledger-via-audit"]
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
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
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

python3 - "$VERSION" "$LEDGER" "$NOW_EPOCH" "$@" <<'PY'
import argparse, hashlib, json, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

VERSION, LEDGER_RAW, NOW_RAW = sys.argv[1:4]
SHA_RE = re.compile(r"^[0-9a-f]{64}$")

def now_epoch():
    return int(NOW_RAW or time.time())

def iso(epoch):
    return datetime.fromtimestamp(int(epoch), timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def digest_from_file(path):
    lines = Path(path).read_text(errors="replace").splitlines()[-30:]
    return hashlib.sha256("\n".join(lines).encode()).hexdigest()

def rows(path):
    out = []
    try:
        for line in path.read_text().splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                out.append(row)
    except FileNotFoundError:
        pass
    return out

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"capacity-halt-lease status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def active_lease(all_rows, session, pane, digest, now):
    active = None
    for row in all_rows:
        if row.get("session") != session or str(row.get("pane")) != str(pane) or row.get("digest") != digest:
            continue
        if row.get("event") == "acquire" and int(row.get("expires_epoch") or 0) > now:
            active = row
        elif row.get("event") == "release" and active and int(row.get("epoch") or 0) >= int(active.get("epoch") or 0):
            active = None
    return active

def append_row(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")

def examples(args):
    data = [
        {"name": "acquire", "command": "capacity-halt-lease-primitive.sh --acquire --session flywheel --pane 3 --digest <sha256> --ttl 90 --json", "purpose": "acquire per-(session,pane,digest) lease for ttl seconds"},
        {"name": "release", "command": "capacity-halt-lease-primitive.sh --release --session flywheel --pane 3 --digest <sha256> --result success --json", "purpose": "release lease with success|failure|skipped result"},
        {"name": "list", "command": "capacity-halt-lease-primitive.sh --list --json", "purpose": "list active leases (acquire rows whose expires_epoch is in the future)"},
        {"name": "doctor", "command": "capacity-halt-lease-primitive.sh doctor --json", "purpose": "verify jq, python3, ledger writable"},
        {"name": "audit", "command": "capacity-halt-lease-primitive.sh audit --json", "purpose": "tail recent ledger rows"},
    ]
    emit(args, {"schema_version": "capacity-halt-lease.examples.v1", "command": "examples", "examples": data}, 0)

def info_envelope(args, ledger):
    emit(args, {
        "schema_version": "capacity-halt-lease.info.v1",
        "command": "info",
        "name": "capacity-halt-lease-primitive",
        "version": VERSION,
        "ledger": str(ledger),
        "default_ttl_seconds": 90,
        "verbs": ["--info", "--schema", "--help", "--examples", "--json", "--acquire", "--release", "--list"],
        "subcommands": ["doctor", "health", "validate", "audit", "why", "repair", "quickstart"],
        "capabilities": [
            "per-pane-digest-idempotency",
            "ttl-bound-lease",
            "acquire-release-list",
            "stale-lease-skip",
            "result-tagged-release"
        ],
        "apply_supported": False,
        "dry_run_supported": False,
        "idempotency_key_required_for_apply": False,
        "mutates_state": True,
        "env_vars": ["CAPACITY_HALT_LEASE_LEDGER", "CAPACITY_HALT_LEASE_NOW_EPOCH"],
        "exit_codes": {"0": "acquired-or-query-ok", "1": "already-held", "2": "malformed", "3": "read-error"},
    }, 0)

def main():
    p = argparse.ArgumentParser(description="Per-pane/digest capacity-halt idempotency lease.")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--info", action="store_true")
    mode.add_argument("--examples", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--acquire", action="store_true")
    mode.add_argument("--release", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--ledger", default=LEDGER_RAW)
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--digest", default="")
    p.add_argument("--scrollback-file", default="")
    p.add_argument("--ttl", type=int, default=90)
    p.add_argument("--result", choices=["success", "failure", "skipped"], default="success")
    args = p.parse_args(sys.argv[4:])
    ledger = Path(args.ledger).expanduser()
    now = now_epoch()
    if args.examples:
        examples(args)
    if args.info:
        info_envelope(args, ledger)
    if args.list:
        current = [r for r in rows(ledger) if r.get("event") == "acquire" and active_lease(rows(ledger), r.get("session"), str(r.get("pane")), r.get("digest"), now) == r]
        emit(args, {"schema_version": "capacity-halt-lease.list.v1", "status": "ok", "ledger": str(ledger), "active_count": len(current), "leases": current}, 0)
    try:
        digest = args.digest or (digest_from_file(args.scrollback_file) if args.scrollback_file else "")
    except OSError as exc:
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "read_error", "ledger_written": False, "reason": str(exc)}, 3)
    if not args.session or not args.pane or not SHA_RE.match(digest) or args.ttl <= 0:
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "malformed", "ledger_written": False, "reason": "session_pane_digest_ttl_required"}, 2)
    if args.acquire:
        all_rows = rows(ledger)
        active = active_lease(all_rows, args.session, args.pane, digest, now)
        if active:
            emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "already_held", "session": args.session, "pane": args.pane, "digest": digest, "ledger_written": False, "active_until": active.get("expires_ts")}, 1)
        row = {"schema_version": "capacity-halt-lease.row.v1", "event": "acquire", "ts": iso(now), "epoch": now, "session": args.session, "pane": int(args.pane) if args.pane.isdigit() else args.pane, "digest": digest, "ttl_seconds": args.ttl, "expires_epoch": now + args.ttl, "expires_ts": iso(now + args.ttl), "source": "capacity-halt-lease-primitive"}
        append_row(ledger, row)
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "acquired", "session": args.session, "pane": args.pane, "digest": digest, "ledger_written": True, "expires_ts": row["expires_ts"]}, 0)
    if args.release:
        row = {"schema_version": "capacity-halt-lease.row.v1", "event": "release", "ts": iso(now), "epoch": now, "session": args.session, "pane": int(args.pane) if args.pane.isdigit() else args.pane, "digest": digest, "result": args.result, "source": "capacity-halt-lease-primitive"}
        append_row(ledger, row)
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "released", "session": args.session, "pane": args.pane, "digest": digest, "result": args.result, "ledger_written": True}, 0)
    p.print_help()

if __name__ == "__main__":
    main()
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-60-measured-performance-budget-loop.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-87-binding-constraint-capacity-score.md`
