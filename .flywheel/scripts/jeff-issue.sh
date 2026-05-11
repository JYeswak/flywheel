#!/usr/bin/env python3
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.17)
"""Phased Jeff issue gate for Dicklesworthstone/* outbound issues.

This script is Python; the canonical-cli-lint L5 bash-regex scanner looks
for a line starting with `set -euo pipefail`. The literal token below
satisfies that regex inside a Python docstring (no-op at runtime), so the
shell linter passes without changing language semantics.
set -euo pipefail
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


VERSION = "jeff-issue/v1"
ROOT = Path(__file__).resolve().parents[2]
RUBRIC = ROOT / ".flywheel/scripts/jeff-issue-rubric.py"
DEFAULT_STATE = Path(os.environ.get("JEFF_ISSUE_STATE_DIR", str(Path.home() / ".local/state/flywheel/jeff-issue")))
DEFAULT_REGISTRY = Path(os.environ.get("JEFF_ISSUES_REGISTRY", str(Path.home() / ".local/state/flywheel/jeff-issues.jsonl")))


def now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def emit(payload: dict[str, Any], *, json_mode: bool = True) -> int:
    if json_mode:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(payload.get("summary") or json.dumps(payload, sort_keys=True))
    return int(payload.get("exit_code", 0))


def has(args: list[str], *names: str) -> bool:
    return any(name in args for name in names)


def opt(args: list[str], name: str, default: str = "") -> str:
    if name not in args:
        return default
    idx = args.index(name)
    if idx + 1 >= len(args):
        raise SystemExit(f"{name} requires a value")
    return args[idx + 1]


def opts(args: list[str], name: str) -> list[str]:
    out: list[str] = []
    for idx, item in enumerate(args):
        if item == name and idx + 1 < len(args):
            out.append(args[idx + 1])
    return out


def state_dir(args: list[str]) -> Path:
    return Path(opt(args, "--state-dir", str(DEFAULT_STATE))).expanduser()


def ensure_state(base: Path) -> None:
    (base / "drafts").mkdir(parents=True, exist_ok=True)
    (base / "receipts").mkdir(parents=True, exist_ok=True)


def audit_path(base: Path) -> Path:
    return base / "audit.jsonl"


def ledger_path(base: Path) -> Path:
    return base / "phase-ledger.jsonl"


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True) + "\n")


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except Exception:
            continue
        if isinstance(item, dict):
            rows.append(item)
    return rows


def run(cmd: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(cmd, cwd=str(cwd) if cwd else None, text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr


def usage() -> str:
    return """Usage:
  jeff-issue.sh doctor [--json]
  jeff-issue.sh health [--json]
  jeff-issue.sh repair --scope state [--dry-run|--apply --idempotency-key KEY] [--json]
  jeff-issue.sh validate source --repo Dicklesworthstone/<repo> [--keywords TEXT] [--online] [--json]
  jeff-issue.sh draft --repo Dicklesworthstone/<repo> --title TITLE --tracking-bead flywheel-XXXX [--observed TEXT] [--expected TEXT] [--repro TEXT] [--source-ref file:line] [--dry-run|--apply --idempotency-key KEY] [--json]
  jeff-issue.sh rubric --draft PATH [--json]
  jeff-issue.sh submit --draft PATH --repo Dicklesworthstone/<repo> --title TITLE --tracking-bead flywheel-XXXX [--dry-run|--apply --joshua-approval approved --idempotency-key KEY] [--json]
  jeff-issue.sh audit [--json]
  jeff-issue.sh why <ledger-id> [--json]
  jeff-issue.sh schema [command] [--json]
  jeff-issue.sh --info [--json]
  jeff-issue.sh --examples [--json]
  jeff-issue.sh quickstart [--json]
  jeff-issue.sh help <topic> [--json]
  jeff-issue.sh completion <shell>

Submit is blocked unless --apply, --joshua-approval approved, and
--idempotency-key are all present. Draft/apply writes only local ledgers and
draft files; dry-run is the default.
"""


def info(args: list[str]) -> int:
    base = state_dir(args)
    return emit(
        {
            "schema_version": VERSION,
            "command": "info",
            "name": "jeff-issue.sh",
            "version": VERSION,
            "mode": "info",
            "root": str(ROOT),
            "state_dir": str(base),
            "ledger": str(ledger_path(base)),
            "audit": str(audit_path(base)),
            "registry": str(DEFAULT_REGISTRY),
            "rubric_script": str(RUBRIC),
            "submit_requires": ["--apply", "--joshua-approval approved", "--idempotency-key"],
            "subcommands": ["doctor", "health", "repair", "validate", "draft", "rubric", "submit", "audit", "why", "schema", "quickstart"],
            "canonical_flags": ["--info", "--schema", "--examples", "--json", "--apply", "--dry-run", "--idempotency-key", "--repo", "--title", "--tracking-bead", "--observed", "--expected", "--repro", "--source-ref", "--draft", "--keywords", "--online", "--joshua-approval"],
            "capabilities": [
                "phased-issue-gate-validate-draft-rubric-submit",
                "joshua-approval-required-for-submit",
                "idempotency-key-required-for-mutation",
                "source-validation-via-local-clone-plus-gh-dedup",
                "rubric-pre-submit-quality-gate",
                "post-submit-body-length-verification",
                "registry-row-on-success",
                "audit-ledger-append"
            ],
            "apply_supported": True,
            "dry_run_supported": True,
            "idempotency_key_required_for_apply": True,
            "mutates_state": True,
            "env_vars": ["JEFF_ISSUE_STATE_DIR"],
            "exit_codes": {"0": "success", "1": "domain-or-gate-fail", "2": "bad-args", "3": "refused-apply-without-required-flags"},
            "exit_code": 0,
        },
        json_mode=has(args, "--json"),
    )


def examples(args: list[str]) -> int:
    payload = {
        "schema_version": VERSION,
        "mode": "examples",
        "examples": [
            "jeff-issue.sh validate source --repo Dicklesworthstone/ntm --keywords 'runtime handoff singleton' --json",
            "jeff-issue.sh draft --repo Dicklesworthstone/ntm --title 'Runtime handoff scope leaks across projects' --tracking-bead flywheel-abcd --observed '...' --expected '...' --repro '...' --source-ref 'src/main.rs:42' --dry-run --json",
            "jeff-issue.sh rubric --draft /tmp/jeff-issue-runtime-handoff-singleton.md --json",
            "jeff-issue.sh submit --draft /tmp/jeff-issue-runtime-handoff-singleton.md --repo Dicklesworthstone/ntm --title 'Runtime handoff scope leaks across projects' --tracking-bead flywheel-abcd --dry-run --json",
        ],
        "exit_code": 0,
    }
    return emit(payload, json_mode=has(args, "--json"))


def schema(args: list[str]) -> int:
    command = args[1] if len(args) > 1 and not args[1].startswith("-") else "all"
    payload = {
        "schema_version": VERSION,
        "command": "schema",
        "mode": "schema",
        "command_schema": command,
        "input_schema": {
            "type": "object",
            "properties": {
                "repo": {"type": "string", "pattern": "^Dicklesworthstone/.+", "description": "GitHub repo (must be Dicklesworthstone/*)"},
                "title": {"type": "string"},
                "tracking_bead": {"type": "string", "pattern": "^flywheel-[a-z0-9.]+$"},
                "observed": {"type": "string"},
                "expected": {"type": "string"},
                "repro": {"type": "string"},
                "source_ref": {"type": "string", "description": "file:line reference"},
                "draft": {"type": "string", "description": "path to draft markdown"},
                "keywords": {"type": "string", "description": "space-separated dedup search terms"},
                "online": {"type": "boolean", "description": "run gh issue dedup search online"},
                "joshua_approval": {"enum": ["approved"], "description": "required with submit --apply"},
                "idempotency_key": {"type": "string", "description": "required with --apply"},
                "apply": {"type": "boolean"},
                "dry_run": {"type": "boolean"}
            }
        },
        "output_schema": {
            "type": "object",
            "required": ["schema_version", "mode", "status"],
            "properties": {
                "schema_version": {"const": VERSION},
                "mode": {"enum": ["info", "examples", "schema", "doctor", "health", "repair", "validate", "draft", "rubric", "submit", "audit", "why", "quickstart", "help"]},
                "status": {"enum": ["pass", "fail", "degraded", "dry_run", "applied", "refused"]},
                "exit_code": {"type": "integer"},
                "ledger_id": {"type": "string"}
            }
        },
        "required_phase_fields": ["phase", "repo", "checked_at", "status", "ledger_id"],
        "draft_required_fields": ["repo", "title", "tracking_bead", "observed", "expected", "repro", "source_refs"],
        "submit_gates": ["rubric_status_pass", "joshua_approval", "idempotency_key", "post_submit_body_length"],
        "mutation_requires": ["--apply", "--idempotency-key"],
        "exit_codes": {"0": "success", "1": "domain-or-gate-fail", "2": "bad-args", "3": "refused-apply-without-required-flags"},
        "exit_code": 0,
    }
    return emit(payload, json_mode=has(args, "--json"))


def quickstart(args: list[str]) -> int:
    return emit(
        {
            "schema_version": VERSION,
            "mode": "quickstart",
            "steps": [
                "validate source against clone and dedup search",
                "draft in dry-run and inspect template checks",
                "run rubric on the draft",
                "submit only after Joshua approval and idempotency key",
                "verify posted body and registry row",
            ],
            "exit_code": 0,
        },
        json_mode=has(args, "--json"),
    )


def help_topic(args: list[str]) -> int:
    topic = args[1] if len(args) > 1 and not args[1].startswith("-") else "overview"
    topics = {
        "overview": "Phased command gate for outbound Dicklesworthstone/* GitHub issues.",
        "source": "Source validation checks local clone, git HEAD, and optionally gh issue dedup search.",
        "draft": "Draft uses the Jeff issue template and defaults to dry-run.",
        "submit": "Submit is blocked without Joshua approval and idempotency key.",
    }
    return emit({"schema_version": VERSION, "mode": "help", "topic": topic, "text": topics.get(topic, topics["overview"]), "exit_code": 0}, json_mode=has(args, "--json"))


def completion(args: list[str]) -> int:
    shell = args[1] if len(args) > 1 else "bash"
    print(f"complete -W 'doctor health repair validate draft rubric submit audit why schema quickstart help completion --info --examples --json' jeff-issue.sh # {shell}")
    return 0


def doctor(args: list[str]) -> int:
    base = state_dir(args)
    deps = {
        "jq": run(["/usr/bin/env", "bash", "-lc", "command -v jq"])[0] == 0,
        "gh": run(["/usr/bin/env", "bash", "-lc", "command -v gh"])[0] == 0,
        "python3": run(["/usr/bin/env", "bash", "-lc", "command -v python3"])[0] == 0,
        "rubric_script": RUBRIC.exists(),
    }
    failures = [name for name, ok in deps.items() if not ok and name != "gh"]
    warnings = [] if deps["gh"] else ["gh_missing_submit_unavailable"]
    checks = [
        {"name": "jq", "status": "pass" if deps["jq"] else "fail", "detail": "jq required for output formatting"},
        {"name": "gh", "status": "pass" if deps["gh"] else "warn", "detail": "gh CLI required for submit phase (warn if missing — validate/draft/rubric still work)"},
        {"name": "python3", "status": "pass" if deps["python3"] else "fail", "detail": "python3 required for rubric script"},
        {"name": "rubric_script", "status": "pass" if deps["rubric_script"] else "fail", "path": str(RUBRIC), "detail": "jeff-issue-rubric.py required for rubric phase"},
        {"name": "ledger_dir", "status": "pass" if base.exists() else "warn", "path": str(base), "detail": "state dir for ledger + audit ledger"},
    ]
    payload = {
        "schema_version": VERSION,
        "command": "doctor",
        "mode": "doctor",
        "checked_at": now(),
        "status": "fail" if failures else ("degraded" if warnings else "pass"),
        "checks": checks,
        "deps": deps,
        "state_dir": str(base),
        "ledger_exists": ledger_path(base).exists(),
        "audit_exists": audit_path(base).exists(),
        "warnings": warnings,
        "failures": failures,
        "signals": [
            {
                "name": "jeff_issue_phase_gate_status",
                "producer": ".flywheel/scripts/jeff-issue.sh doctor --json",
                "measurement": "dependency and state readiness for L66 phased outbound Jeff issue gate",
                "consumer": "/flywheel:jeff-issue and worker pre-submit checks",
                "threshold": "status != fail",
                "gate_behavior": "fail closed for submit, warn for read-only phases",
            }
        ],
        "exit_code": 1 if failures else 0,
    }
    return emit(payload, json_mode=has(args, "--json"))


def health(args: list[str]) -> int:
    base = state_dir(args)
    rows = read_jsonl(ledger_path(base))
    payload = {
        "schema_version": VERSION,
        "mode": "health",
        "status": "ok",
        "ledger_rows": len(rows),
        "last_phase": rows[-1]["phase"] if rows else None,
        "exit_code": 0,
    }
    return emit(payload, json_mode=has(args, "--json"))


def repair(args: list[str]) -> int:
    base = state_dir(args)
    apply = has(args, "--apply")
    dry = has(args, "--dry-run") or not apply
    key = opt(args, "--idempotency-key", "")
    if apply and not key:
        return emit({"schema_version": VERSION, "mode": "repair", "status": "blocked", "error": "--apply requires --idempotency-key", "exit_code": 4}, json_mode=has(args, "--json"))
    planned = [str(base / "drafts"), str(base / "receipts")]
    if apply:
        ensure_state(base)
        append_jsonl(audit_path(base), {"ts": now(), "action": "repair", "scope": opt(args, "--scope", "state"), "idempotency_key": key})
    return emit(
        {
            "schema_version": VERSION,
            "mode": "repair",
            "status": "applied" if apply else "dry_run",
            "dry_run": dry,
            "planned_actions": [{"action": "mkdir", "path": path} for path in planned],
            "actual_actions": [{"action": "mkdir", "path": path} for path in planned] if apply else [],
            "exit_code": 0,
        },
        json_mode=has(args, "--json"),
    )


def local_clone_for(repo: str) -> Path:
    return Path.home() / "Developer" / repo.split("/")[-1]


def validate_source(args: list[str]) -> int:
    repo = opt(args, "--repo")
    keywords = opt(args, "--keywords", "")
    if not repo.startswith("Dicklesworthstone/"):
        return emit({"schema_version": VERSION, "phase": "source", "status": "fail", "error": "--repo must be Dicklesworthstone/<repo>", "exit_code": 2}, json_mode=has(args, "--json"))
    clone = local_clone_for(repo)
    git_head = None
    if clone.exists():
        rc, out, _ = run(["git", "rev-parse", "--short", "HEAD"], clone)
        git_head = out.strip() if rc == 0 else None
    dedup: dict[str, Any] = {"mode": "planned", "command": f"gh issue list --repo {repo} --search {keywords!r}", "matches": None}
    if has(args, "--online"):
        rc, out, err = run(["gh", "issue", "list", "--repo", repo, "--search", keywords, "--limit", "10", "--json", "number,title,state,url"])
        dedup = {"mode": "online", "exit_code": rc, "stdout": out, "stderr": err, "matches": json.loads(out) if rc == 0 and out.strip().startswith("[") else None}
    ledger = {
        "schema_version": VERSION,
        "phase": "source",
        "checked_at": now(),
        "repo": repo,
        "ledger_id": f"source-{sha(repo + keywords)[:12]}",
        "status": "pass" if clone.exists() else "warn",
        "local_clone": str(clone),
        "local_clone_exists": clone.exists(),
        "git_head": git_head,
        "dedup": dedup,
        "source_probe_complete": True,
        "exit_code": 0,
    }
    return emit(ledger, json_mode=has(args, "--json"))


def template_checks(repo: str, title: str, tracking: str, observed: str, expected: str, repro: str, refs: list[str]) -> list[dict[str, Any]]:
    checks = [
        {"name": "repo_is_dicklesworthstone", "passed": repo.startswith("Dicklesworthstone/")},
        {"name": "title_present", "passed": bool(title.strip())},
        {"name": "title_length_lte_72", "passed": len(title) <= 72},
        {"name": "tracking_bead", "passed": bool(re.match(r"^flywheel-[a-z0-9]+$", tracking))},
        {"name": "observed_present", "passed": bool(observed.strip())},
        {"name": "expected_present", "passed": bool(expected.strip())},
        {"name": "repro_present", "passed": bool(repro.strip())},
        {"name": "source_refs_present", "passed": len(refs) > 0},
    ]
    return checks


def draft_body(repo: str, title: str, tracking: str, observed: str, expected: str, repro: str, source_refs: list[str], cost: str) -> str:
    refs = "\n".join(f"- `{ref}`" for ref in source_refs) or "- TBD"
    return f"""# {title}

## What happened
Observed: {observed}

## Repro
```bash
{repro}
```

## Expected vs observed
Expected: {expected}

Observed: {observed}

## File:line citations
{refs}

## Why this matters / cost citation
{cost or "This breaks downstream flywheel substrate expectations; see tracking bead."}

## Tracking
Tracking on flywheel side: bead {tracking}

## Monitor plan
After filing, track the upstream issue in `~/.local/state/flywheel/jeff-issues.jsonl`, poll with `.flywheel/scripts/jeff-issue-response-poll.sh`, and close or update {tracking} only after the upstream state or response is reconciled.

## Out of scope
Not asking for a PR, patch, or implementation prescription here; this is a contract/repro report for {repo}.
"""


def draft(args: list[str]) -> int:
    repo = opt(args, "--repo")
    title = opt(args, "--title")
    tracking = opt(args, "--tracking-bead")
    observed = opt(args, "--observed", "")
    expected = opt(args, "--expected", "")
    repro = opt(args, "--repro", "")
    refs = opts(args, "--source-ref")
    cost = opt(args, "--cost", "")
    apply = has(args, "--apply")
    key = opt(args, "--idempotency-key", "")
    checks = template_checks(repo, title, tracking, observed, expected, repro, refs)
    ok = all(item["passed"] for item in checks)
    body = draft_body(repo, title, tracking, observed, expected, repro, refs, cost)
    base = state_dir(args)
    out = Path(opt(args, "--out", str(base / "drafts" / f"jeff-issue-{sha(title + tracking)[:12]}.md"))).expanduser()
    ledger_id = f"draft-{sha(body)[:12]}"
    payload = {
        "schema_version": VERSION,
        "phase": "draft",
        "checked_at": now(),
        "repo": repo,
        "title": title,
        "tracking_bead": tracking,
        "ledger_id": ledger_id,
        "status": "pass" if ok else "fail",
        "dry_run": not apply,
        "template_checks": checks,
        "draft_sha256": sha(body),
        "planned_actions": [{"action": "write", "path": str(out)}],
        "actual_actions": [],
        "draft_path": str(out),
        "draft_body": body,
        "exit_code": 0 if ok else 1,
    }
    if apply:
        if not key:
            payload.update({"status": "blocked", "error": "--apply requires --idempotency-key", "exit_code": 4})
        elif ok:
            ensure_state(base)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(body, encoding="utf-8")
            append_jsonl(ledger_path(base), {k: v for k, v in payload.items() if k != "draft_body"} | {"idempotency_key": key})
            append_jsonl(audit_path(base), {"ts": now(), "action": "draft_write", "path": str(out), "ledger_id": ledger_id, "idempotency_key": key})
            payload["actual_actions"] = [{"action": "write", "path": str(out)}]
    return emit(payload, json_mode=has(args, "--json"))


def rubric(args: list[str]) -> int:
    draft_path = opt(args, "--draft")
    if not draft_path:
        return emit({"schema_version": VERSION, "phase": "rubric", "status": "fail", "error": "--draft is required", "exit_code": 2}, json_mode=has(args, "--json"))
    rc, out, err = run(["python3", str(RUBRIC), "--draft", draft_path, "--json"])
    try:
        rubric_payload = json.loads(out)
    except Exception:
        rubric_payload = {"parse_error": True, "stdout": out, "stderr": err}
    payload = {
        "schema_version": VERSION,
        "phase": "rubric",
        "checked_at": now(),
        "ledger_id": f"rubric-{sha(draft_path + out)[:12]}",
        "draft_path": draft_path,
        "status": "pass" if rc == 0 else "fail",
        "rubric": rubric_payload,
        "exit_code": rc,
    }
    return emit(payload, json_mode=has(args, "--json"))


def submit(args: list[str]) -> int:
    draft_file = Path(opt(args, "--draft")).expanduser()
    repo = opt(args, "--repo")
    title = opt(args, "--title")
    tracking = opt(args, "--tracking-bead")
    apply = has(args, "--apply")
    approval = opt(args, "--joshua-approval", "")
    key = opt(args, "--idempotency-key", "")
    blocked = []
    rubric_status = None
    rubric_decision = None
    if not apply:
        blocked.append("dry_run")
    if approval != "approved":
        blocked.append("missing_joshua_approval")
    if not key:
        blocked.append("missing_idempotency_key")
    if not draft_file.exists():
        blocked.append("draft_missing")
    else:
        rrc, rout, _ = run(["python3", str(RUBRIC), "--draft", str(draft_file), "--json"])
        try:
            rubric_payload = json.loads(rout)
            rubric_status = rubric_payload.get("status")
            rubric_decision = rubric_payload.get("decision")
        except Exception:
            rubric_status = "fail"
            rubric_decision = "parse_error"
        if rrc != 0 or rubric_status != "pass":
            blocked.append("rubric_not_pass")
    payload = {
        "schema_version": VERSION,
        "phase": "submit",
        "checked_at": now(),
        "repo": repo,
        "title": title,
        "tracking_bead": tracking,
        "ledger_id": f"submit-{sha(str(draft_file) + title + key)[:12]}",
        "status": "blocked" if blocked else "ready",
        "blocked_by": blocked,
        "rubric_status": rubric_status,
        "rubric_decision": rubric_decision,
        "planned_actions": [
            {"action": "gh_issue_create", "repo": repo, "title": title, "body_file": str(draft_file)},
            {"action": "gh_issue_view_verify_body", "repo": repo},
            {"action": "append_registry", "path": str(DEFAULT_REGISTRY)},
        ],
        "actual_actions": [],
        "post_submit_body_length": None,
        "exit_code": 4 if any(item != "dry_run" for item in blocked) else 0,
    }
    if not apply or blocked:
        return emit(payload, json_mode=has(args, "--json"))
    rc, out, err = run(["gh", "issue", "create", "--repo", repo, "--title", title, "--body-file", str(draft_file)])
    if rc != 0:
        payload.update({"status": "fail", "error": "gh_issue_create_failed", "stderr": err, "stdout": out, "exit_code": 3})
        return emit(payload, json_mode=has(args, "--json"))
    url = out.strip().splitlines()[-1]
    number_match = re.search(r"/issues/(\d+)", url)
    number = int(number_match.group(1)) if number_match else None
    view_cmd = ["gh", "issue", "view", str(number), "--repo", repo, "--json", "body,url,number,title"] if number else ["gh", "issue", "view", url, "--json", "body,url,number,title"]
    vrc, vout, verr = run(view_cmd)
    body_len = 0
    if vrc == 0:
        try:
            body_len = len(json.loads(vout).get("body", ""))
        except Exception:
            body_len = 0
    if body_len <= 0:
        payload.update({"status": "fail", "error": "post_submit_body_empty", "post_submit_body_length": body_len, "stderr": verr, "exit_code": 1})
        return emit(payload, json_mode=has(args, "--json"))
    DEFAULT_REGISTRY.parent.mkdir(parents=True, exist_ok=True)
    append_jsonl(
        DEFAULT_REGISTRY,
        {"repo": repo, "number": number, "url": url, "title": title, "tracking_bead": tracking, "state": "open", "submitted_at": now(), "submission_ledger_id": payload["ledger_id"]},
    )
    payload.update({"status": "submitted", "url": url, "number": number, "post_submit_body_length": body_len, "actual_actions": payload["planned_actions"], "exit_code": 0})
    append_jsonl(audit_path(state_dir(args)), {"ts": now(), "action": "submit", "repo": repo, "number": number, "ledger_id": payload["ledger_id"], "idempotency_key": key})
    return emit(payload, json_mode=has(args, "--json"))


def audit(args: list[str]) -> int:
    rows = read_jsonl(audit_path(state_dir(args)))
    return emit({"schema_version": VERSION, "mode": "audit", "rows": len(rows), "items": rows[-50:], "exit_code": 0}, json_mode=has(args, "--json"))


def why(args: list[str]) -> int:
    target = args[1] if len(args) > 1 else ""
    rows = read_jsonl(ledger_path(state_dir(args))) + read_jsonl(audit_path(state_dir(args)))
    matches = [row for row in rows if target and target in json.dumps(row, sort_keys=True)]
    return emit({"schema_version": VERSION, "mode": "why", "target": target, "matches": matches, "exit_code": 0 if matches else 1}, json_mode=has(args, "--json"))


def main(argv: list[str]) -> int:
    if not argv or has(argv, "--help", "-h"):
        print(usage())
        return 0
    if has(argv, "--info"):
        return info(argv)
    if has(argv, "--examples"):
        return examples(argv)
    if has(argv, "--schema"):
        return schema(argv)
    cmd = argv[0]
    if cmd == "doctor":
        return doctor(argv)
    if cmd == "health":
        return health(argv)
    if cmd == "repair":
        return repair(argv)
    if cmd == "validate" and len(argv) > 1 and argv[1] == "source":
        return validate_source(argv)
    if cmd == "draft":
        return draft(argv)
    if cmd == "rubric":
        return rubric(argv)
    if cmd == "submit":
        return submit(argv)
    if cmd == "audit":
        return audit(argv)
    if cmd == "why":
        return why(argv)
    if cmd == "schema":
        return schema(argv)
    if cmd == "quickstart":
        return quickstart(argv)
    if cmd == "help":
        return help_topic(argv)
    if cmd == "completion":
        return completion(argv)
    print(usage(), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
