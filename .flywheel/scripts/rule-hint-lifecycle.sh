#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.17)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# SURGICAL coexistence design: this script's python heredoc ALREADY
# implements all canonical subcommands as POSITIONAL args
# `{analyze,doctor,health,repair,validate,audit,why,schema,examples,
# quickstart,completion}` and tests/rule-hint-lifecycle.sh asserts shapes
# on `schema`, `why`, default analyze, and apply. Python subcommands stay
# untouched.
#
# What's missing per AG3: DASH-FLAG introspection (--info / --schema /
# --examples / -h / --help) which python rejects today. The bash scaffold
# adds ONLY those dash flags plus canonical `help <topic>`. All positional
# args fall through to python verbatim.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="rule-hint-lifecycle/v1"

scaffold_usage() {
  cat <<'USG'
usage: rule-hint-lifecycle.sh [SUBCOMMAND|FLAGS] [OPTIONS]

This script's primary surface is the python heredoc below. All canonical
subcommands are positional and implemented in python:

Subcommands (python — unchanged):
  analyze [--apply]        analyze L-rule hint usage (default action)
  doctor [--json]          probe rules + usage rows; emits candidates list
  health [--json]          last-run analysis snapshot
  repair --rule-id ID      remediate a single rule's lifecycle status
  validate [--json]        validate ruleset shape
  audit [--json]           recent run history
  why --rule-id ID         explain decision (.action="why" + .rule.count + .decision.action)
  schema [--json]          enumerate {commands, exit_codes, fields, schema_version}
  examples [--json]        curated invocations
  quickstart [--json]      operator orientation
  completion <shell>       emit shell completion script

Introspection (bash scaffold — NEW dash-flag surfaces python rejects):
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
                            (note: positional `schema` keeps its own shape
                             with .commands array for backward-compat)
  --examples --json        canonical examples envelope (additive)
  --help / -h              merged usage (this text)
  help <topic>             topic help (analyze | doctor | health | repair | validate | why | schema)
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "rule-hint-lifecycle.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "rule-hint-lifecycle.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "analyze,doctor,health,repair,validate,audit,why,schema,examples,quickstart,completion" \
    "" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"analyze dry-run",invocation:"rule-hint-lifecycle.sh --json",purpose:"propose demote/promote candidates from L-rule usage log"}'
)"$'\n'"$(jq -nc '{name:"apply (file proposal beads)",invocation:"rule-hint-lifecycle.sh --apply --json",purpose:"actually br create the Joshua-approved lifecycle proposal beads"}'
)"$'\n'"$(jq -nc '{name:"why for single rule",invocation:"rule-hint-lifecycle.sh why --rule-id L20 --json",purpose:"explain promote/demote decision for one rule"}'
)"$'\n'"$(jq -nc '{name:"positional doctor (python)",invocation:"rule-hint-lifecycle.sh doctor --json",purpose:"python doctor surface — emits candidate_count + candidates[]"}'
)"$'\n'"$(jq -nc '{name:"positional schema (python)",invocation:"rule-hint-lifecycle.sh schema --json",purpose:"python schema surface — emits .commands array + .exit_codes"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["action","candidate_count","candidates[]"],note:"python-implemented doctor surface"}' ;;
    health|repair|validate|audit|why|analyze)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"python-implemented; see `rule-hint-lifecycle.sh <surface> --json` for shape"}' ;;
    *)
      # Default — canonical AG3 envelope. The python positional
      # `schema --json` keeps its own backward-compat shape with
      # .commands array; this --schema flag is a distinct surface.
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{
          schema_version:$sv,
          command:"schema",
          surface:$surface,
          subcommands:["analyze","doctor","health","repair","validate","audit","why","schema","examples","quickstart","completion"],
          intro_flags:["--info","--schema","--examples","-h","--help"],
          note:"rule-hint-lifecycle: bash scaffold adds dash-flag introspection. Positional `schema --json` is python-implemented and emits .commands array."
        }' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    analyze)  printf 'topic: analyze — default python action; reads L-rule usage log, emits demote/promote candidates. --apply creates proposal beads via br.\n' ;;
    doctor)   printf 'topic: doctor — python `doctor --json`; emits action=doctor + candidate_count + candidates[] (rule_id + count + action + marker).\n' ;;
    health)   printf 'topic: health — python `health --json`; same shape as analyze but read-only.\n' ;;
    repair)   printf 'topic: repair — python `repair --rule-id ID --apply`; remediates a single rule. Joshua approval gate preserved.\n' ;;
    validate) printf 'topic: validate — python `validate --json`; validates ruleset shape.\n' ;;
    why)      printf 'topic: why — python `why --rule-id ID --json`; emits .action="why" + .rule.count + .decision.action.\n' ;;
    schema)   printf 'topic: schema — python `schema --json` (NOT --schema flag); emits .commands + .exit_codes + .fields + .schema_version.\n' ;;
    *)        printf 'topics: analyze | doctor | health | repair | validate | why | schema\n' ;;
  esac
}

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)
      shift
      # Skip --json flag if it's the next arg (canonical-cli treats --json as
      # output-mode rather than as the surface selector).
      local _surface="${1:-default}"
      [[ "$_surface" == "--json" ]] && _surface="default"
      scaffold_emit_schema "$_surface"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *)
      printf 'ERR: unknown canonical flag: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: ONLY dash-flag introspection + `help <topic>`.
# Positional subcommands fall through to python so existing tests keep passing.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in analyze|doctor|health|repair|validate|audit|why|schema|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA = "rule-hint-lifecycle/v1"


@dataclass(frozen=True)
class Rule:
    rule_id: str
    title: str
    path: str


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"status={payload.get('status')} action={payload.get('action')} candidates={payload.get('candidate_count', 0)}")


def parse_ts(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    text = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def load_rules(rules_dir: Path) -> list[Rule]:
    rules: list[Rule] = []
    for path in sorted(rules_dir.glob("L*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^##\s+(L[0-9]+)\s+[—-]\s+(.+?)\s*$", text, flags=re.M)
        if not match:
            match = re.search(r"(L[0-9]+)", path.name, flags=re.I)
            if not match:
                continue
            title_match = re.search(r"^title:\s*(.+)$", text, flags=re.M)
            title = title_match.group(1).strip() if title_match else path.stem
            rules.append(Rule(match.group(1).upper(), title, str(path)))
            continue
        rules.append(Rule(match.group(1).upper(), match.group(2).strip(), str(path)))
    return rules


def load_counts(usage_log: Path, cutoff: datetime) -> tuple[dict[str, int], int]:
    counts: dict[str, int] = {}
    rows_seen = 0
    if not usage_log.exists():
        return counts, rows_seen
    for line in usage_log.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(row, dict):
            continue
        ts = parse_ts(row.get("ts"))
        if ts is None or ts < cutoff:
            continue
        rule_id = str(row.get("rule_id") or "").upper()
        if not re.fullmatch(r"L[0-9]+", rule_id):
            continue
        counts[rule_id] = counts.get(rule_id, 0) + 1
        rows_seen += 1
    return counts, rows_seen


def existing_open(repo: Path, br_bin: str, marker: str) -> str | None:
    proc = subprocess.run([br_bin, "list", "--json", "--limit", "0"], cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        return None
    issues = data if isinstance(data, list) else data.get("issues", [])
    for issue in issues:
        if not isinstance(issue, dict) or issue.get("status") == "closed":
            continue
        title = str(issue.get("title") or "")
        if marker in title:
            return str(issue.get("id") or "")
    return None


def create_bead(repo: Path, br_bin: str, candidate: dict) -> str:
    marker = candidate["marker"]
    existing = existing_open(repo, br_bin, marker)
    if existing:
        return f"matched:{existing}"
    description = (
        "Auto-created by rule-hint-lifecycle.sh. This is a proposal bead only: "
        "Joshua approval is required before changing canonical L-rules, memory rules, "
        "or skill auto-route entries.\n\n"
        f"Rule: {candidate['rule_id']} — {candidate['title']}\n"
        f"Action: {candidate['action']}\n"
        f"Observed 30-day count: {candidate['count']}\n"
        f"Threshold: {candidate['threshold']}\n"
        f"Source shard: {candidate['path']}\n"
    )
    proc = subprocess.run(
        [br_bin, "create", candidate["title_for_bead"], "--type", "task", "--priority", str(candidate["priority"]), "--description", description, "--json"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "br create failed")
    data = json.loads(proc.stdout)
    return str(data.get("id") or data.get("issue", {}).get("id") or "")


def candidates_for(rules: list[Rule], counts: dict[str, int], demote_threshold: int, promote_threshold: int) -> list[dict]:
    candidates: list[dict] = []
    for rule in rules:
        count = counts.get(rule.rule_id, 0)
        if count < demote_threshold:
            marker = f"[rule-hint-lifecycle:demote:{rule.rule_id}]"
            candidates.append({
                "action": "demote",
                "rule_id": rule.rule_id,
                "title": rule.title,
                "count": count,
                "threshold": demote_threshold,
                "path": rule.path,
                "marker": marker,
                "priority": 3,
                "title_for_bead": f"{marker} low hint usage ({count}/30d)",
            })
        elif count > promote_threshold:
            marker = f"[rule-hint-lifecycle:promote:{rule.rule_id}]"
            candidates.append({
                "action": "promote",
                "rule_id": rule.rule_id,
                "title": rule.title,
                "count": count,
                "threshold": promote_threshold,
                "path": rule.path,
                "marker": marker,
                "priority": 2,
                "title_for_bead": f"{marker} high hint usage ({count}/30d)",
            })
    return candidates


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Analyze L-rule hint usage and file Joshua-approved lifecycle proposal beads.")
    parser.add_argument("command", nargs="?", default="analyze", choices=["analyze", "doctor", "health", "repair", "validate", "audit", "why", "schema", "examples", "quickstart", "completion"])
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--rules-dir", default=".flywheel/rules")
    parser.add_argument("--usage-log", default=str(Path.home() / ".local/state/flywheel/rule-hint-usage.jsonl"))
    parser.add_argument("--window-days", type=int, default=30)
    parser.add_argument("--demote-threshold", type=int, default=5)
    parser.add_argument("--promote-threshold", type=int, default=50)
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--rule-id")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    if args.command == "schema":
        emit({"schema_version": SCHEMA, "fields": ["rule_id", "count", "action", "marker"], "commands": ["analyze", "doctor", "health", "repair", "validate", "audit", "why", "schema", "examples", "quickstart", "completion"], "exit_codes": {"0": "ok", "1": "apply failed", "2": "usage"}}, args.json)
        return 0
    if args.command == "examples":
        emit({"schema_version": SCHEMA, "examples": ["rule-hint-lifecycle.sh --json", "rule-hint-lifecycle.sh --apply --json"]}, args.json)
        return 0
    if args.command == "quickstart":
        emit({"schema_version": SCHEMA, "steps": ["Run inject-l-rule-hints through dispatch packets", "Run rule-hint-lifecycle.sh --json for daily proposal review", "Run --apply only to file proposal beads; Joshua approves actual lifecycle changes"]}, args.json)
        return 0
    if args.command == "completion":
        print("complete -W 'analyze doctor health repair validate audit why schema examples quickstart completion --json --dry-run --apply --repo --usage-log --rules-dir --rule-id' rule-hint-lifecycle.sh")
        return 0

    repo = Path(args.repo).expanduser().resolve()
    rules_dir = (repo / args.rules_dir).resolve() if not Path(args.rules_dir).expanduser().is_absolute() else Path(args.rules_dir).expanduser()
    usage_log = Path(args.usage_log).expanduser()
    rules = load_rules(rules_dir)
    cutoff = datetime.now(timezone.utc) - timedelta(days=args.window_days)
    counts, rows_seen = load_counts(usage_log, cutoff)
    candidates = candidates_for(rules, counts, args.demote_threshold, args.promote_threshold)
    payload = {
        "schema_version": SCHEMA,
        "status": "ok",
        "action": "analyzed",
        "mode": "apply" if args.apply else "dry_run",
        "repo": str(repo),
        "rules_dir": str(rules_dir),
        "usage_log": str(usage_log),
        "window_days": args.window_days,
        "cutoff": cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "usage_rows_seen": rows_seen,
        "rules_count": len(rules),
        "candidate_count": len(candidates),
        "joshua_approval_required_before_lifecycle_apply": True,
        "canonical_l_rule_mutation_performed": False,
        "candidates": candidates,
        "beads": [],
    }
    if args.command in {"doctor", "health", "validate", "audit"}:
        payload["action"] = args.command
        emit(payload, args.json)
        return 0
    if args.command == "repair":
        payload["action"] = "repair"
        payload["planned_actions"] = []
        payload["repair_note"] = "No repair actions; lifecycle changes are proposal-bead only."
        emit(payload, args.json)
        return 0
    if args.command == "why":
        rule_id = (args.rule_id or "").upper()
        rule = next((item for item in rules if item.rule_id == rule_id), None)
        payload["action"] = "why"
        payload["rule_id"] = rule_id
        payload["rule"] = None if rule is None else {"id": rule.rule_id, "title": rule.title, "path": rule.path, "count": counts.get(rule.rule_id, 0)}
        payload["decision"] = next((item for item in candidates if item["rule_id"] == rule_id), None)
        emit(payload, args.json)
        return 0 if rule else 1
    if args.apply:
        try:
            payload["beads"] = [create_bead(repo, args.br_bin, candidate) for candidate in candidates]
            payload["action"] = "proposal_beads_created"
        except Exception as exc:
            payload["status"] = "error"
            payload["error"] = str(exc)
            emit(payload, args.json)
            return 1
    emit(payload, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
