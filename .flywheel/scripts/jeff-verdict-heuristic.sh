#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
import argparse
import json
import re
import sys
from pathlib import Path

VERSION = "jeff-verdict-heuristic.v1"
VERDICTS = ("YES_ADOPT", "YES_ADAPT", "NO_NOT_OUR_DOMAIN", "NEED_RESEARCH")

RULES = [
    (
        "YES_ADOPT",
        "matches Flywheel substrate primitives we already operate",
        "adopt-jeff-pattern-{repo}",
        [
            r"\bmcp[_ -]?agent[_ -]?mail\b",
            r"\bagent mail\b",
            r"\bbeads?\b",
            r"\bsocraticode\b",
            r"\bdcg\b",
            r"\bcass\b",
            r"\bntm\b",
            r"\bflywheel\b",
            r"\bskills?\b",
            r"\bfuckup[-_ ]?log\b",
            r"\bjsonl\b.*\bappend\b",
        ],
    ),
    (
        "NO_NOT_OUR_DOMAIN",
        "appears centered on model/ML workload specifics rather than Joshua's agentic infra",
        "monitor",
        [
            r"\bcuda\b",
            r"\bpytorch\b",
            r"\btensor\b",
            r"\btraining\b",
            r"\bcheckpoint\b",
            r"\bllama\b",
            r"\bgpu kernel\b",
            r"\bdiffusion\b",
            r"\bembedding model\b",
        ],
    ),
    (
        "YES_ADAPT",
        "portable infra pattern likely useful with local adaptation",
        "adapt-jeff-pattern-{repo}",
        [
            r"\bschema\b",
            r"\bcallback\b",
            r"\bidempot",
            r"\bdoctor\b",
            r"\btelemetry\b",
            r"\blaunchd\b",
            r"\bcli\b",
            r"\btest(s|ing)?\b",
            r"\bfastmcp\b",
            r"\bsqlite\b",
            r"\brust\b",
            r"\basupersync\b",
            r"\bstructured concurrency\b",
            r"\bquiescence\b",
        ],
    ),
]


def read_text(path_text):
    if not path_text:
        return ""
    path = Path(path_text).expanduser()
    try:
        return path.read_text(errors="ignore")
    except Exception:
        return ""


def classify(repo, text):
    lowered = text.lower()
    for verdict, reason, action_template, patterns in RULES:
        matched = [pattern for pattern in patterns if re.search(pattern, lowered)]
        if matched:
            return {
                "schema_version": "jeff-verdict-heuristic/v1",
                "version": VERSION,
                "repo": repo,
                "verdict": verdict,
                "reason": reason,
                "suggested_action": action_template.format(repo=re.sub(r"[^A-Za-z0-9_.-]+", "-", repo).strip("-").lower() or "unknown"),
                "matched": matched,
            }
    return {
        "schema_version": "jeff-verdict-heuristic/v1",
        "version": VERSION,
        "repo": repo,
        "verdict": "NEED_RESEARCH",
        "reason": "no v1 keyword matched; review artifact before filing or ignoring",
        "suggested_action": "monitor",
        "matched": [],
    }


def info():
    return {
        "schema_version": "jeff-verdict-heuristic/info/v1",
        "version": VERSION,
        "status": "pass",
        "verdict_enum": list(VERDICTS),
    }


parser = argparse.ArgumentParser(description="Heuristic Jeff artifact verdict classifier.")
parser.add_argument("--repo", default="unknown")
parser.add_argument("--commit", action="append", default=[])
parser.add_argument("--path", action="append", default=[])
parser.add_argument("--diff")
parser.add_argument("--text", default="")
parser.add_argument("--info", action="store_true")
parser.add_argument("--examples", action="store_true")
parser.add_argument("--json", action="store_true")
args = parser.parse_args()

if args.info:
    payload = info()
elif args.examples:
    payload = {
        "examples": [
            "jeff-verdict-heuristic.sh --repo mcp_agent_mail --commit 'fix JSONL append gate' --json",
            "jeff-verdict-heuristic.sh --repo model-lab --commit 'train pytorch checkpoint' --json",
        ]
    }
else:
    text = "\n".join(args.commit + args.path + [args.text, read_text(args.diff)])
    payload = classify(args.repo, text)

if args.json or args.info:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(payload.get("verdict", "NEED_RESEARCH"))
sys.exit(0 if payload.get("verdict") in VERDICTS or payload.get("status") == "pass" or args.examples else 1)
PY
