#!/usr/bin/env bash
# Symmetric permit-gate to the refuse-gate at:
# /Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:32-44

set -euo pipefail

VERSION="2026-05-05.1"
NAME="mission-anchor-dispatch-license"
DEFAULT_LEDGER="$HOME/.local/state/flywheel/mission-anchor-license-ledger.jsonl"
REPO="${PWD:-}"
JSON=0
COMMAND=""
TOPIC=""
WATCH=0
INTERVAL=5
SCOPE="state"
DRY_RUN=0
APPLY=0
EXPLAIN=0
IDEMPOTENCY_KEY=""

usage() {
  cat <<'EOF'
usage: mission-anchor-dispatch-license.sh <command> [options]

Load-bearing:
  --emit-list [--repo PATH] [--json]
  --rank [--repo PATH] [--json]
  --validate [--repo PATH] [--json]

Canonical CLI:
  --info [--json]
  --schema [COMMAND] [--json]
  --examples [--json]
  quickstart [--json]
  help [topic] [--json]
  completion <bash|zsh>
  doctor [--repo PATH] [--json]
  health [--repo PATH] [--json] [--watch -i N]
  repair --scope state --dry-run [--json]
  audit [--json]
  why <id> [--json]

Exit codes: 0=success, 1=domain-fail, 2=usage, 3=transient.
EOF
}

py_json() { python3 - "$@" <<'PY'
import json, os, sys
mode = sys.argv[1]
if mode == "info":
    repo, ledger, version, path = sys.argv[2:]
    dep = lambda n: os.popen(f"command -v {n} 2>/dev/null").read().strip()
    sha = os.popen(f"shasum -a 256 {path!r} 2>/dev/null").read().split()[:1]
    out = {"schema_version":"mission-anchor-dispatch-license.info.v1","command":"info","name":"mission-anchor-dispatch-license","version":version,"repo":repo,"paths":{"mission":f"{repo}/.flywheel/MISSION.md","dispatch_log":f"{repo}/.flywheel/dispatch-log.jsonl","ledger":ledger},"deps":{"jq":dep("jq"),"python3":dep("python3"),"br":dep("br")},"sha256":sha[0] if sha else "","refuse_gate_cite":"/Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:32-44"}
elif mode == "schema":
    out = {"schema_version":"mission-anchor-dispatch-license.emit-list.v1","command":"emit-list","required":["schema_version","ts","repo","mission_anchor_status","current_open_phase","licensed_undispatched_count","licensed_undispatched_top_5_oldest","licensed_undispatched_top_5_highest_downstream_cost","licensed_undispatched_full_list_sorted"],"task_fields":["task_id","source","phase_tag","age_seconds","downstream_dep_count","page_rank_score"],"ranking":{"phase_tag_currency_weight":0.5,"age_seconds_weight":0.2,"downstream_dep_count_weight":0.3,"phase_filter":"current_open_phase or current_open_phase+1"},"ledger_schema_version":"mission-anchor-dispatch-license.ledger.v1"}
elif mode == "examples":
    examples = [
      ("cold-cache L112 probe","bash .flywheel/scripts/mission-anchor-dispatch-license.sh --emit-list --repo /Users/josh/Developer/flywheel --json | jq '.licensed_undispatched_count'"),
      ("rank licensed work","bash .flywheel/scripts/mission-anchor-dispatch-license.sh --rank --repo \"$PWD\" --json"),
      ("validate MISSION Section 3","bash .flywheel/scripts/mission-anchor-dispatch-license.sh --validate --repo \"$PWD\" --json"),
      ("diagnose permit-gate substrate","bash .flywheel/scripts/mission-anchor-dispatch-license.sh doctor --repo \"$PWD\" --json"),
      ("monitor health","bash .flywheel/scripts/mission-anchor-dispatch-license.sh health --repo \"$PWD\" --watch -i 30 --json"),
      ("dry-run repair","bash .flywheel/scripts/mission-anchor-dispatch-license.sh repair --scope state --dry-run --json")]
    out = {"schema_version":"mission-anchor-dispatch-license.examples.v1","command":"examples","examples":[{"name":n,"command":c} for n,c in examples]}
elif mode == "quickstart":
    out = {"schema_version":"mission-anchor-dispatch-license.quickstart.v1","command":"quickstart","status":"ok","steps":["Run --validate --json to check the repo mission anchor.","Run --emit-list --json to append one permit-gate ledger row.","Use licensed_undispatched_full_list_sorted[0] as the next licensed dispatch candidate.","Treat mission_anchor_status=unfilled or missing as exit 3 retryable substrate state.","Use doctor for diagnostics and repair --dry-run for idempotent state previews."]}
elif mode == "help":
    out = {"schema_version":"mission-anchor-dispatch-license.help.v1","command":"help","topic":sys.argv[2],"text":"Topics: emit-list, validate, doctor, repair, ledger. emit-list is the permit-gate surface symmetric to the mission-anchor refuse-gate."}
elif mode == "repair":
    scope, dry, apply, explain, key = sys.argv[2:]
    out = {"schema_version":"mission-anchor-dispatch-license.repair.v1","command":"repair","scope":scope,"dry_run":dry=="1","apply":apply=="1","explain":explain=="1","idempotency_key":key,"status":"dry_run" if dry=="1" else "blocked","planned_actions":["create ledger parent directory if missing","validate ledger JSONL rows"],"would_write":[],"would_delete":[],"would_call_external":[],"blocked_by":[] if dry=="1" else ["repair is report-only for this permit gate"]}
print(json.dumps(out, sort_keys=True))
PY
}

emit_info() {
  local repo_real ledger
  repo_real="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s' "$REPO")"
  ledger="${MISSION_LICENSE_LEDGER:-$DEFAULT_LEDGER}"
  if [[ "$JSON" -eq 1 ]]; then py_json info "$repo_real" "$ledger" "$VERSION" "$0"; else
    printf '%s version=%s\nrepo=%s\nledger=%s\nrefuse_gate=%s\n' "$NAME" "$VERSION" "$repo_real" "$ledger" "/Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:32-44"
  fi
}

emit_examples() {
  if [[ "$JSON" -eq 1 ]]; then py_json examples; else
    py_json examples | python3 -c 'import json,sys; [print(f"# {e['"'"'name'"'"']}\n{e['"'"'command'"'"']}\n") for e in json.load(sys.stdin)["examples"]]'
  fi
}

emit_completion() {
  case "${1:-}" in
    --help|-h|"") printf 'usage: mission-anchor-dispatch-license.sh completion <bash|zsh>\n' ;;
    bash) printf 'complete -W "--info --schema --examples --emit-list --validate --rank doctor health repair quickstart help completion audit why --json --repo --dry-run --apply --scope" mission-anchor-dispatch-license.sh\n' ;;
    zsh) printf 'compadd -- --info --schema --examples --emit-list --validate --rank doctor health repair quickstart help completion audit why --json --repo --dry-run --apply --scope\n' ;;
    *) printf 'ERROR: unsupported shell: %s\n' "$1" >&2; exit 2 ;;
  esac
}

run_core() {
  MISSION_LICENSE_COMMAND="$1" MISSION_LICENSE_REPO="$REPO" MISSION_LICENSE_JSON="$JSON" \
  MISSION_LICENSE_LEDGER="${MISSION_LICENSE_LEDGER:-$DEFAULT_LEDGER}" \
  MISSION_LICENSE_SCRIPT="$0" python3 - <<'PY'
import hashlib, json, os, re, shutil, subprocess, sys, tempfile, time
from datetime import datetime, timezone
cmd=os.environ["MISSION_LICENSE_COMMAND"]; repo=os.path.realpath(os.environ["MISSION_LICENSE_REPO"])
json_mode=os.environ.get("MISSION_LICENSE_JSON")=="1"; ledger=os.environ["MISSION_LICENSE_LEDGER"]; script=os.environ["MISSION_LICENSE_SCRIPT"]
iso=lambda: datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
mission=lambda r: os.path.join(r,".flywheel","MISSION.md")
def read(p): return open(p,encoding="utf-8").read()
def state(m):
    if not os.path.exists(m): return "missing"
    t=read(m); s=""
    for line in t.splitlines()[:120]:
        x=re.match(r"\s*status\s*:\s*['\"]?([^'\"]+?)['\"]?\s*$", line)
        if x: s=x.group(1).strip(); break
    todo=re.search(r"^- (North-star|Primary|Explicit non-goals|Safety|Evidence|Owner-review|Current lock)[^:]*: TODO\s*$",t,re.M)
    return "unfilled" if s=="needs_owner_review" or todo else "filled"
def cells(line): return [p.strip() for p in line.strip().strip("|").split("|")]
def ladder(m):
    if not os.path.exists(m): return [], False
    rows=[]; in_sec=False; lvl=0; header=None
    for line in read(m).splitlines():
        h=re.match(r"^(#{1,6})\s+(?:Section\s+3\b|3[.)]\s+)", line, re.I)
        if h: in_sec=True; lvl=len(h.group(1)); continue
        if not in_sec: continue
        h2=re.match(r"^(#{1,6})\s+", line)
        if h2 and len(h2.group(1))<=lvl: break
        if not line.lstrip().startswith("|"): continue
        c=cells(line); low=[x.lower().replace(" ","_") for x in c]
        if header is None and "phase" in low and any(x.startswith("status_as_of") or x=="status" for x in low): header=low; continue
        if header is None or all(re.fullmatch(r":?-{3,}:?", x or "") for x in c): continue
        pi=header.index("phase"); gi=header.index("gate_criterion") if "gate_criterion" in header else None
        si=next((i for i,x in enumerate(header) if x.startswith("status_as_of") or x=="status"),None)
        if si is None or pi>=len(c) or si>=len(c) or not c[pi] or set(c[pi])<=set("-:"): continue
        rows.append({"index":len(rows),"phase":c[pi],"gate_criterion":c[gi] if gi is not None and gi<len(c) else "","status":c[si]})
    return rows, header is not None
def current(phases):
    for r in phases:
        s=r.get("status","").strip().upper()
        if not s.startswith(("COMPLETE","DONE")): return r["phase"]
    return None
def epoch(v, now):
    if not v: return now
    try: return datetime.fromisoformat(str(v).replace("Z","+00:00")).timestamp()
    except Exception: return now
def num(v):
    try: return int(v)
    except Exception:
        try: return int(float(v))
        except Exception: return 0
def tid(o):
    for k in ("task_id","dispatch_id","id","bead"):
        if o.get(k): return str(o[k])
    b=o.get("beads"); return str(b[0]) if isinstance(b,list) and b else "unknown"
def phase(o):
    x=o.get("phase_tag")
    if isinstance(x,str) and x: return x
    ml=o.get("mission_license")
    if isinstance(ml,dict) and isinstance(ml.get("phase_tag"),str): return ml["phase_tag"]
    m=re.search(r"\bphase_tag[=:]([A-Za-z0-9_.-]+)", f"{o.get('title','')} {o.get('description','')}")
    return m.group(1) if m else ""
def dispatch_items(r, now, warn):
    p=os.path.join(r,".flywheel","dispatch-log.jsonl"); out=[]
    if not os.path.exists(p): warn.append("dispatch_log_missing"); return out
    for n,line in enumerate(open(p,encoding="utf-8"),1):
        if not line.strip(): continue
        try: o=json.loads(line)
        except Exception: warn.append(f"dispatch_log_invalid_json_line_{n}"); continue
        if o.get("callback_received_at") not in (None,""): continue
        ph=phase(o)
        if not ph: continue
        cr=o.get("ts") or o.get("created_at") or o.get("sent_at")
        out.append({"source":"dispatch-log","task_id":tid(o),"phase_tag":ph,"created_at":cr,"age_seconds":max(0,int(now-epoch(cr,now))),"downstream_dep_count":num(o.get("downstream_dep_count",o.get("dependents_count",0)))})
    return out
def ready_raw(r,warn):
    if os.environ.get("MISSION_LICENSE_BR_READY_JSON"): return json.loads(os.environ["MISSION_LICENSE_BR_READY_JSON"])
    if os.environ.get("MISSION_LICENSE_BR_READY_FILE"): return json.load(open(os.environ["MISSION_LICENSE_BR_READY_FILE"],encoding="utf-8"))
    try: pr=subprocess.run([os.environ.get("MISSION_LICENSE_BR_BIN","br"),"ready","--json"],cwd=r,text=True,capture_output=True,timeout=20)
    except Exception as e: warn.append(f"br_ready_unavailable:{e.__class__.__name__}"); return []
    if pr.returncode: warn.append("br_ready_nonzero"); return []
    try: return json.loads(pr.stdout or "[]")
    except Exception: warn.append("br_ready_invalid_json"); return []
def ready_iter(raw):
    if isinstance(raw,list): return raw
    if isinstance(raw,dict):
        for k in ("issues","items","ready"):
            if isinstance(raw.get(k),list): return raw[k]
        return [raw]
    return []
def br_items(r, now, warn):
    out=[]
    for o in ready_iter(ready_raw(r,warn)):
        if not isinstance(o,dict): continue
        ph=phase(o)
        if not ph: continue
        cr=o.get("created_at") or o.get("created") or o.get("updated_at")
        deps=o.get("downstream_dep_count",o.get("dependents_count",0))
        if not deps and isinstance(o.get("dependents"),list): deps=len(o["dependents"])
        out.append({"source":"br-ready","task_id":tid(o),"phase_tag":ph,"created_at":cr,"age_seconds":max(0,int(now-epoch(cr,now))),"downstream_dep_count":num(deps)})
    return out
def ranked(items, phases, cur):
    idx={r["phase"]:r["index"] for r in phases}; ci=idx.get(cur)
    if ci is None: return []
    dedup={}
    for it in items:
        pi=idx.get(it["phase_tag"])
        if pi not in (ci,ci+1): continue
        it=dict(it,phase_index=pi); old=dedup.get(it["task_id"])
        if old is None or (it["downstream_dep_count"],it["age_seconds"])>(old["downstream_dep_count"],old["age_seconds"]): dedup[it["task_id"]]=it
    arr=list(dedup.values()); ma=max([i["age_seconds"] for i in arr] or [0]); md=max([i["downstream_dep_count"] for i in arr] or [0]); out=[]
    for it in arr:
        pw=1.0 if it["phase_index"]==ci else 0.5; aw=it["age_seconds"]/ma if ma else 0; dw=it["downstream_dep_count"]/md if md else 0
        it.update({"phase_tag_currency_weight":pw,"age_seconds_weight":round(aw,6),"downstream_dep_count_weight":round(dw,6),"page_rank_score":round(pw*.5+aw*.2+dw*.3,6)}); out.append(it)
    return sorted(out,key=lambda i:(-i["page_rank_score"],-i["downstream_dep_count"],-i["age_seconds"],i["task_id"]))
def append(path,row):
    os.makedirs(os.path.dirname(path),exist_ok=True); lock=path+".lock"
    for _ in range(100):
        try: os.mkdir(lock); break
        except FileExistsError: time.sleep(.05)
    else: raise RuntimeError(f"could not acquire ledger lock: {lock}")
    try:
        fd,tmp=tempfile.mkstemp(prefix="."+os.path.basename(path)+".",dir=os.path.dirname(path),text=True)
        with os.fdopen(fd,"w",encoding="utf-8") as out:
            if os.path.exists(path): shutil.copyfileobj(open(path,encoding="utf-8"),out)
            out.write(json.dumps(row,sort_keys=True)+"\n"); out.flush(); os.fsync(out.fileno())
        os.replace(tmp,path); os.chmod(path,0o600); d=os.open(os.path.dirname(path),os.O_RDONLY); os.fsync(d); os.close(d)
    finally:
        try: os.rmdir(lock)
        except FileNotFoundError: pass
def err(st,msg): return {"schema_version":"mission-anchor-dispatch-license.error.v1","command":cmd,"status":"transient","repo":repo,"mission_anchor_status":st,"message":msg}
def build(write=False):
    m=mission(repo); st=state(m)
    if st=="missing": return None,3,err(st,f"mission anchor missing: {m}")
    if st=="unfilled": return None,3,err(st,f"mission anchor unfilled: {m}")
    phases,seen=ladder(m); cur=current(phases); warn=[] if seen else ["mission_section_3_phase_ladder_missing"]
    now=time.time(); arr=ranked(dispatch_items(repo,now,warn)+br_items(repo,now,warn),phases,cur); ts=iso()
    payload={"schema_version":"mission-anchor-dispatch-license.emit-list.v1","ts":ts,"repo":repo,"mission_anchor_status":st,"current_open_phase":cur,"phase_ladder":phases,"phase_ladder_source":m,"licensed_undispatched_count":len(arr),"licensed_undispatched_top_5_oldest":sorted(arr,key=lambda i:(-i["age_seconds"],i["task_id"]))[:5],"licensed_undispatched_top_5_highest_downstream_cost":sorted(arr,key=lambda i:(-i["downstream_dep_count"],-i["page_rank_score"],i["task_id"]))[:5],"licensed_undispatched_full_list_sorted":arr,"warnings":warn}
    if write:
        dg=hashlib.sha256(json.dumps(payload,sort_keys=True).encode()).hexdigest()[:12]; ids=[i["task_id"] for i in arr]
        row={"schema_version":"mission-anchor-dispatch-license.ledger.v1","ts":ts,"artifact_id":f"{repo}:license-emit:{dg}","artifact_class":"substrate_primitive","stock":str(len(arr)),"consumer":"dispatch-template+dispatch-decide-loop","owner":"flywheel:1","deferral_until":None,"deferred_reason":None,"verification_probe":f"bash {script} --emit-list --repo {repo} --json | jq '.licensed_undispatched_count'","tick_consequence":"error","drain_receipt":{"licensed_undispatched_count":0,"dispatched_task_ids":ids},"dedup_key":f"mission-license:{repo}:{dg}"}
        append(ledger,row); payload.update({"ledger_appended":True,"ledger_path":ledger,"ledger_dedup_key":row["dedup_key"]})
    return payload,0,None
if cmd in ("emit-list","rank"):
    p,rc,e=build(True)
    if rc: print(json.dumps(e,sort_keys=True) if json_mode else e["message"], file=sys.stdout if json_mode else sys.stderr); sys.exit(rc)
    print(json.dumps(p,sort_keys=True)); sys.exit(0)
if cmd=="validate":
    p,rc,e=build(False)
    if rc: print(json.dumps(e,sort_keys=True) if json_mode else e["message"], file=sys.stdout if json_mode else sys.stderr); sys.exit(rc)
    out={k:p[k] for k in ("schema_version","ts","repo","mission_anchor_status","current_open_phase","phase_ladder","warnings")}; out.update({"command":"validate","status":"pass","phase_count":len(p["phase_ladder"])})
    print(json.dumps(out,sort_keys=True) if json_mode else f"status=pass phase_count={out['phase_count']} current_open_phase={out['current_open_phase']}"); sys.exit(0)
if cmd in ("doctor","health"):
    p,rc,e=build(False)
    if rc:
        out={"schema_version":f"mission-anchor-dispatch-license.{cmd}.v1","command":cmd,"status":"critical","repo":repo,"exit_code":rc,"subsystems":{"mission_anchor":{"status":"fail","message":e["message"]}}}
        print(json.dumps(out,sort_keys=True) if json_mode else e["message"]); sys.exit(3 if cmd=="health" else 1)
    warn=p["warnings"]; out={"schema_version":f"mission-anchor-dispatch-license.{cmd}.v1","command":cmd,"status":"warn" if warn else "pass","repo":repo,"licensed_undispatched_count":p["licensed_undispatched_count"],"current_open_phase":p["current_open_phase"],"subsystems":{"mission_anchor":{"status":"ok"},"section_3":{"status":"warn" if warn else "ok","warnings":warn},"ledger":{"status":"ok","path":ledger}}}
    print(json.dumps(out,sort_keys=True) if json_mode else f"status={out['status']} licensed_undispatched_count={out['licensed_undispatched_count']}"); sys.exit(0)
if cmd=="audit":
    rows=[]
    if os.path.exists(ledger): rows=[json.loads(x) for x in open(ledger,encoding="utf-8") if x.strip()][-10:]
    print(json.dumps({"schema_version":"mission-anchor-dispatch-license.audit.v1","command":"audit","ledger":ledger,"rows":rows},sort_keys=True)); sys.exit(0)
if cmd=="why":
    print(json.dumps({"schema_version":"mission-anchor-dispatch-license.why.v1","command":"why","id":os.environ.get("MISSION_LICENSE_WHY_ID",""),"refuse_gate_cite":"/Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh:32-44","permit_gate":"--emit-list ranks already licensed dispatch work"},sort_keys=True)); sys.exit(0)
sys.exit(2)
PY
}

emit_repair() {
  py_json repair "$SCOPE" "$DRY_RUN" "$APPLY" "$EXPLAIN" "$IDEMPOTENCY_KEY"
  [[ "$APPLY" -eq 1 ]] && exit 1 || exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --info) COMMAND="info"; shift ;;
    --schema) COMMAND="schema"; [[ "${2:-}" != "" && "${2:-}" != --* ]] && { TOPIC="$2"; shift; }; shift ;;
    schema) COMMAND="schema"; TOPIC="${2:-emit-list}"; if [[ $# -gt 1 ]]; then shift 2; else shift; fi ;;
    --examples|examples) COMMAND="examples"; shift ;;
    --emit-list) COMMAND="emit-list"; shift ;;
    --rank) COMMAND="rank"; shift ;;
    --validate|validate) COMMAND="validate"; shift ;;
    doctor) COMMAND="doctor"; [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]] && { usage; exit 0; }; shift ;;
    health) COMMAND="health"; [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]] && { usage; exit 0; }; shift ;;
    repair) COMMAND="repair"; shift ;;
    audit) COMMAND="audit"; shift ;;
    why) COMMAND="why"; TOPIC="${2:-}"; export MISSION_LICENSE_WHY_ID="$TOPIC"; if [[ $# -gt 1 ]]; then shift 2; else shift; fi ;;
    quickstart) COMMAND="quickstart"; shift ;;
    help) COMMAND="help"; TOPIC="${2:-overview}"; if [[ $# -gt 1 ]]; then shift 2; else shift; fi ;;
    completion) COMMAND="completion"; TOPIC="${2:-}"; if [[ $# -gt 1 ]]; then shift 2; else shift; fi ;;
    --scope) SCOPE="${2:-state}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --explain) EXPLAIN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --watch) WATCH=1; shift ;;
    -i|--interval) INTERVAL="${2:-5}"; shift 2 ;;
    --no-color|--no-emoji) shift ;;
    --width) shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "${COMMAND:-help}" in
  info) emit_info ;;
  schema) py_json schema ;;
  examples) emit_examples ;;
  quickstart) py_json quickstart ;;
  help) if [[ "$JSON" -eq 1 ]]; then py_json help "$TOPIC"; else printf 'Topics: emit-list, validate, doctor, repair, ledger.\n'; printf 'emit-list is the permit-gate surface symmetric to the mission-anchor refuse-gate.\n'; fi ;;
  completion) emit_completion "$TOPIC" ;;
  emit-list|rank|validate|doctor|health|audit|why)
    run_core "$COMMAND"
    if [[ "$COMMAND" == "health" && "$WATCH" -eq 1 ]]; then sleep "$INTERVAL"; fi ;;
  repair) emit_repair ;;
  *) usage ;;
esac
