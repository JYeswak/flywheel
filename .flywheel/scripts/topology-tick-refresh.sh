#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse, fcntl, hashlib, json, os, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA="topology-tick-refresh.result.v1"
LEDGER_SCHEMA="topology-tick-refresh.ledger.v1"
REFUSALS=["extra_agent_pane","malformed_topology_row","missing_live_session","no_topology_row","pane_count_changed","worker_kind_changed","worker_pane_missing"]

def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00","Z")

def parse_ts(value):
    if not value: return None
    try: return datetime.fromisoformat(str(value).replace("Z","+00:00"))
    except ValueError: return None

def age(now_dt, value):
    parsed=parse_ts(value)
    return None if parsed is None else max(0, int((now_dt-parsed).total_seconds()))

def emit(payload, json_mode, rc):
    print(json.dumps(payload, sort_keys=True, separators=(",",":")) if json_mode else f"topology-tick-refresh status={payload.get('status')}")
    raise SystemExit(rc)

def append_jsonl(path, row):
    if not isinstance(row, dict): raise ValueError("row_not_object")
    target=Path(path).expanduser(); target.parent.mkdir(parents=True, exist_ok=True)
    with target.with_suffix(target.suffix+".lock").open("a+") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        data=json.dumps(row, sort_keys=True, separators=(",",":"))+"\n"
        with target.open("a", encoding="utf-8") as handle:
            handle.write(data); handle.flush(); os.fsync(handle.fileno())

def read_latest(path):
    latest={}
    if not Path(path).exists(): return latest
    for line_no,line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(),1):
        if not line.strip(): continue
        try: row=json.loads(line)
        except json.JSONDecodeError as exc: raise ValueError(f"malformed_topology_row line={line_no} {exc}") from exc
        ts=row.get("effective_at") or row.get("ts") if isinstance(row,dict) else None
        if not isinstance(row,dict) or not row.get("session") or not parse_ts(ts): raise ValueError(f"malformed_topology_row line={line_no}")
        session=str(row["session"]); previous=latest.get(session)
        if previous is None or str(ts)>str(previous.get("effective_at") or previous.get("ts")): latest[session]=row
    return latest

def run_ntm(ntm,args):
    proc=subprocess.run([ntm,*args], text=True, capture_output=True)
    if proc.returncode!=0: raise RuntimeError((proc.stderr or proc.stdout or f"ntm rc={proc.returncode}")[-500:])
    return json.loads(proc.stdout or "{}")

def live_sessions(ntm):
    payload=run_ntm(ntm,["list","--json"]); sessions=payload if isinstance(payload,list) else payload.get("sessions",[])
    return {str(i.get("name") or i.get("session")):i for i in sessions if isinstance(i,dict) and (i.get("name") or i.get("session"))}

def kind(value):
    low=str(value or "unknown").lower()
    return {"cc":"claude","cod":"codex"}.get(low,low)

def activity(ntm, session):
    payload=run_ntm(ntm,[f"--robot-activity={session}"]); agents=payload if isinstance(payload,list) else payload.get("agents",[])
    out={}
    for agent in agents or []:
        pane=agent.get("pane_idx", agent.get("pane"))
        if pane is not None: out[str(pane)]=kind(agent.get("agent_type") or agent.get("type"))
    return out

def panes(values):
    return {str(v) for v in (values or []) if v is not None}

def shape_hash(row, live, agents):
    payload={"session":row.get("session"),"expected_pane_count":row.get("expected_pane_count"),"orchestrator_pane":row.get("orchestrator_pane"),"callback_pane":row.get("callback_pane"),"human_pane":row.get("human_pane"),"shell_panes":sorted(panes(row.get("shell_panes"))),"worker_panes":sorted(panes(row.get("worker_panes"))),"worker_kinds":row.get("worker_kinds") or {},"live_pane_count":live.get("pane_count"),"live_agents":agents}
    return hashlib.sha256(json.dumps(payload,sort_keys=True,separators=(",",":")).encode()).hexdigest()

def compare(row, live, agents):
    expected=row.get("expected_pane_count")
    if expected is not None:
        actual=len(agents) if row.get("pane_count_semantics")=="agent_panes_excludes_user_pane0" else live.get("pane_count")
        if actual is not None and int(actual)!=int(expected): return False,"pane_count_changed"
    workers=panes(row.get("worker_panes")); kinds={str(k):kind(v) for k,v in (row.get("worker_kinds") or {}).items()}
    for pane in sorted(workers, key=int):
        if pane not in agents: return False,"worker_pane_missing"
        if kinds.get(pane) and agents[pane]!=kinds[pane]: return False,"worker_kind_changed"
    protected=panes([row.get("orchestrator_pane"),row.get("callback_pane"),row.get("human_pane")]) | panes(row.get("shell_panes"))
    return (False,"extra_agent_pane") if [p for p in agents if p not in (workers|protected)] else (True,None)

def ledger(base, sessions, status, reason, extra=None):
    row=dict(base); row.update(extra or {})
    row.update({"schema_version":LEDGER_SCHEMA,"event":"topology_tick_refresh_fire","status":status,"refusal_reason":reason,"session_statuses":sessions})
    return row

def main():
    parser=argparse.ArgumentParser(description="Refresh session topology freshness when live NTM shape is unchanged.")
    parser.add_argument("--topology",default=str(Path.home()/".local/state/flywheel/session-topology.jsonl"))
    parser.add_argument("--ntm-bin",default="/Users/josh/.local/bin/ntm")
    parser.add_argument("--ledger",default=str(Path.home()/".local/state/flywheel/topology-tick-refresh.jsonl"))
    parser.add_argument("--lock",default=""); parser.add_argument("--now",default="")
    parser.add_argument("--fresh-max-age-sec",type=int,default=300)
    parser.add_argument("--apply",action="store_true"); parser.add_argument("--json",action="store_true"); parser.add_argument("--info",action="store_true")
    args=parser.parse_args()
    if args.info: emit({"schema_version":SCHEMA,"primitive_invoked":"topology-tick-refresh","refusal_reasons":REFUSALS},args.json,0)
    stamp=args.now or now_iso(); now_dt=parse_ts(stamp); run_id=hashlib.sha256(f"{stamp}:{os.getpid()}:{time.time_ns()}".encode()).hexdigest()[:24]
    topology=str(Path(args.topology).expanduser()); lock_path=args.lock or f"{topology}.topology-refresh.lock"
    base={"run_id":run_id,"invocation_id":run_id,"ts":stamp,"primitive_invoked":"topology-tick-refresh","topology_path":topology,"source_path":".flywheel/scripts/topology-tick-refresh.sh","profile":"default","idempotency_key":f"topology-tick-refresh:{run_id}","lock_path":lock_path,"ledger_path":str(Path(args.ledger).expanduser()),"apply":args.apply,"dry_run":not args.apply,"timeout_sec":None}
    lock_file=Path(lock_path).expanduser(); lock_file.parent.mkdir(parents=True, exist_ok=True)
    with lock_file.open("a+") as lock:
        try: fcntl.flock(lock.fileno(), fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            append_jsonl(args.ledger, ledger(base, [], "lock_held", "lock_held"))
            emit(dict(base, schema_version=SCHEMA, status="lock_held", refreshed_count=0, refused_count=0, max_age_sec_before=None, max_age_sec_after=None, topology_shape_hash=None, post_check={"ledger_row_written":True,"topology_rows_appended":0}), args.json, 1)
        sessions=[]; appended=refreshed=refused=already=skipped=0; hashes=[]; reason=None
        try:
            latest=read_latest(topology); live=live_sessions(args.ntm_bin)
        except Exception as exc:
            status="malformed"; reason="malformed_topology_row"; sessions.append({"session":None,"status":status,"refusal_reason":reason,"error":str(exc)})
        else:
            for session,row in sorted(latest.items()):
                row_age=age(now_dt,row.get("effective_at") or row.get("ts"))
                if session not in live:
                    sessions.append({"session":session,"status":"refused","refusal_reason":"missing_live_session","age_sec_before":row_age}); refused+=1; continue
                agents=activity(args.ntm_bin,session); ok,bad=compare(row,live[session],agents); h=shape_hash(row,live[session],agents); hashes.append(h)
                if not ok:
                    sessions.append({"session":session,"status":"refused","refusal_reason":bad,"topology_shape_hash":h,"age_sec_before":row_age}); refused+=1; continue
                if row_age is not None and row_age<=args.fresh_max_age_sec:
                    sessions.append({"session":session,"status":"already_fresh","topology_shape_hash":h,"age_sec_before":row_age,"age_sec_after":row_age}); already+=1; continue
                if not args.apply:
                    sessions.append({"session":session,"status":"skipped","refusal_reason":"dry_run","topology_shape_hash":h,"age_sec_before":row_age}); skipped+=1; continue
                new_row=dict(row,effective_at=stamp,registered_by="topology-tick-refresh",refresh_of_effective_at=row.get("effective_at") or row.get("ts"),refresh_reason="pure_freshness",topology_shape_hash=h,run_id=run_id)
                append_jsonl(topology,new_row); appended+=1; refreshed+=1
                sessions.append({"session":session,"status":"refreshed","topology_shape_hash":h,"age_sec_before":row_age,"age_sec_after":0})
            for session in sorted(set(live)-set(latest)):
                sessions.append({"session":session,"status":"refused","refusal_reason":"no_topology_row"}); refused+=1
            status="refreshed" if refreshed else "refused" if refused else "already_fresh" if already else "skipped"
            reason=next((s.get("refusal_reason") for s in sessions if s.get("refusal_reason") and s.get("refusal_reason")!="dry_run"),None)
        before=[s.get("age_sec_before") for s in sessions if isinstance(s.get("age_sec_before"),int)]
        after=[s.get("age_sec_after",s.get("age_sec_before")) for s in sessions if isinstance(s.get("age_sec_after",s.get("age_sec_before")),int)]
        overall=hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest() if hashes else None
        result=dict(base,schema_version=SCHEMA,status=status,refreshed_count=refreshed,refused_count=refused,already_fresh_count=already,skipped_count=skipped,max_age_sec_before=max(before) if before else None,max_age_sec_after=max(after) if after else None,topology_shape_hash=overall,refusal_reason=reason,sessions=sessions,post_check={"ledger_row_written":False,"topology_rows_appended":appended})
        append_jsonl(args.ledger, ledger(base, sessions, status, reason, {"topology_shape_hash":overall,"max_age_sec_before":result["max_age_sec_before"],"max_age_sec_after":result["max_age_sec_after"]}))
        result["post_check"]["ledger_row_written"]=True
        emit(result,args.json,0 if status in {"refreshed","already_fresh","skipped"} else 2)

if __name__=="__main__":
    main()
PY
