#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
import argparse
import json
import sys
from pathlib import Path

VERSION = "jeff-report-template.v1"
SECTIONS = [
    "Run metadata",
    "New Commits (by repo)",
    "New Releases",
    "New Tweets (doodlestein)",
    "Actionable Signals",
    "New Blog Posts",
    "Re-indexed (socraticode)",
    "Aggregate \"What can we learn\" digest",
    "Errors",
]
VERDICTS = ("YES_ADOPT", "YES_ADAPT", "NO_NOT_OUR_DOMAIN", "NEED_RESEARCH")


def example_payload():
    return {
        "schema_version": "jeff-daily-report/input/v1",
        "report_date": "2026-05-05",
        "run_metadata": {
            "run_ts": "2026-05-05T07:00:00Z",
            "duration_sec": 1.234,
            "repos_checked": 3,
            "repos_with_changes": 2,
            "new_commits_total": 4,
            "new_tweets": 2,
            "new_blog_posts": 1,
            "re_indexed_repos": 2,
        },
        "repo_root": "/Users/josh/Developer/jeff-corpus",
        "changed": [
            {
                "repo": "mcp_agent_mail",
                "path": "/Users/josh/Developer/jeff-corpus/mcp_agent_mail",
                "previous_sha": "abc123",
                "head_sha": "def456",
                "commit_count": 2,
                "commits": ["def4567 fix JSONL append gate", "c0ffee1 add beads callback fixture"],
                "files_changed": 3,
                "insertions": 91,
                "deletions": 12,
                "diff_path": "/tmp/jeff-diff/mcp_agent_mail.txt",
                "verdict": "YES_ADOPT",
                "reason": "matches Flywheel substrate primitives we already operate",
                "suggested_action": "adopt-jeff-pattern-mcp_agent_mail",
            },
            {
                "repo": "agent-cli",
                "path": "/Users/josh/Developer/jeff-corpus/agent-cli",
                "previous_sha": "111aaa",
                "head_sha": "222bbb",
                "commit_count": 2,
                "commits": ["222bbb add callback schema", "111aaa tighten sqlite doctor tests"],
                "files_changed": 5,
                "insertions": 104,
                "deletions": 8,
                "diff_path": "/tmp/jeff-diff/agent-cli.txt",
                "verdict": "YES_ADAPT",
                "reason": "portable infra pattern likely useful with local adaptation",
                "suggested_action": "adapt-jeff-pattern-agent-cli",
            },
        ],
        "releases": ["mcp_agent_mail: v0.3.0"],
        "tweets": ["tweet one", "https://x.com/doodlestein/status/1"],
        "actionable_signals": [
            {
                "source": "x:doodlestein",
                "source_ref": "https://x.com/doodlestein/status/1",
                "signal_class": "agent-mail",
                "verdict": "YES_ADOPT",
                "reason": "matches Flywheel substrate primitives we already operate",
                "apply_to_flywheel": "adopt-jeff-pattern-agent-mail-reservations",
                "evidence": "Agent Mail file reservations are critical for coordinating multiple agents.",
            },
            {
                "source": "x:doodlestein",
                "source_ref": "https://x.com/doodlestein/status/2",
                "signal_class": "beads",
                "verdict": "YES_ADOPT",
                "reason": "matches Flywheel substrate primitives we already operate",
                "apply_to_flywheel": "adopt-jeff-pattern-beads-work-chunking",
                "evidence": "Break work into chunks using beads.",
            },
            {
                "source": "x:doodlestein",
                "source_ref": "https://x.com/doodlestein/status/3",
                "signal_class": "ntm",
                "verdict": "YES_ADAPT",
                "reason": "portable infra pattern likely useful with local adaptation",
                "apply_to_flywheel": "adapt-jeff-pattern-ntm-parallelism",
                "evidence": "NTM is powerful because of parallelism and mixed harnesses.",
            },
        ],
        "blog_titles": ["New post"],
        "reindexed": [
            {"repo": "mcp_agent_mail", "new_chunks_indexed": "queued"},
            {"repo": "agent-cli", "new_chunks_indexed": "queued"},
        ],
        "errors": [],
        "dry_run": False,
    }


def load_payload(path_text, use_example):
    if use_example:
        return example_payload()
    if not path_text:
        raise SystemExit("--input or --example is required")
    return json.loads(Path(path_text).expanduser().read_text())


def bullet(text):
    return f"- {text}"


def fmt_value(value):
    if value is None or value == "":
        return "none"
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def render_metadata(payload):
    metadata = payload.get("run_metadata", {})
    keys = [
        "run_ts",
        "duration_sec",
        "repos_checked",
        "repos_with_changes",
        "new_commits_total",
        "new_tweets",
        "new_blog_posts",
        "re_indexed_repos",
    ]
    lines = ["## Run metadata"]
    lines.extend(bullet(f"{key}: {fmt_value(metadata.get(key))}") for key in keys)
    lines.append(bullet(f"repo_root: {fmt_value(payload.get('repo_root'))}"))
    lines.append(bullet(f"dry_run: {fmt_value(payload.get('dry_run', False))}"))
    lines.append(bullet(f"skip_fetch: {fmt_value(payload.get('skip_fetch', False))}"))
    return lines


def render_commits(payload):
    lines = ["## New Commits (by repo)"]
    changed = payload.get("changed") or []
    if not changed:
        lines.append("No new commits detected.")
        return lines
    for item in changed:
        repo = item.get("repo", "unknown")
        commits = item.get("commits") or []
        verdict = item.get("verdict", "NEED_RESEARCH")
        if verdict not in VERDICTS:
            verdict = "NEED_RESEARCH"
        lines.extend([
            f"### {repo}",
            bullet(f"Commits: {fmt_value(item.get('commit_count', len(commits)))}"),
            bullet(f"Files changed: {fmt_value(item.get('files_changed', 0))}"),
            bullet(f"Net lines: +{fmt_value(item.get('insertions', 0))}/-{fmt_value(item.get('deletions', 0))}"),
            bullet(f"Verdict: {verdict}"),
            bullet(f"Reason: {fmt_value(item.get('reason'))}"),
            bullet(f"Suggested action: {fmt_value(item.get('suggested_action', 'monitor'))}"),
            bullet(f"Diff: `{fmt_value(item.get('diff_path'))}`"),
            bullet("Highlights:"),
        ])
        if commits:
            lines.extend(f"  - {line}" for line in commits[:5])
        else:
            lines.append("  - none")
    return lines


def render_simple_list(title, values, empty_text):
    lines = [f"## {title}"]
    if not values:
        lines.append(empty_text)
        return lines
    lines.extend(bullet(value) for value in values)
    return lines


def render_reindexed(payload):
    lines = ["## Re-indexed (socraticode)"]
    reindexed = payload.get("reindexed") or []
    if not reindexed:
        lines.append("No repositories queued for re-indexing.")
        return lines
    for item in reindexed:
        repo = item.get("repo", "unknown")
        chunks = item.get("new_chunks_indexed", "queued")
        lines.append(bullet(f"{repo}: {chunks}"))
        if chunks == "queued":
            lines.append(bullet(f"queued `{repo}`"))
    return lines


def render_actionable_signals(payload):
    lines = ["## Actionable Signals"]
    signals = payload.get("actionable_signals") or []
    if not signals:
        lines.append("No actionable signals detected.")
        return lines
    for item in signals:
        source_ref = fmt_value(item.get("source_ref"))
        signal_class = fmt_value(item.get("signal_class"))
        verdict = item.get("verdict", "NEED_RESEARCH")
        if verdict not in VERDICTS:
            verdict = "NEED_RESEARCH"
        lines.extend([
            f"### {signal_class}",
            bullet(f"Source: `{source_ref}`"),
            bullet(f"Signal class: {signal_class}"),
            bullet(f"Verdict: {verdict}"),
            bullet(f"Reason: {fmt_value(item.get('reason'))}"),
            bullet(f"Apply-to-flywheel hypothesis: {fmt_value(item.get('apply_to_flywheel', 'monitor'))}"),
            bullet(f"Evidence: {fmt_value(item.get('evidence'))}"),
        ])
    return lines


def render_digest(payload):
    changed = payload.get("changed") or []
    signals = payload.get("actionable_signals") or []
    verdict_counts = {verdict: 0 for verdict in VERDICTS}
    for item in changed:
        verdict = item.get("verdict", "NEED_RESEARCH")
        verdict_counts[verdict if verdict in verdict_counts else "NEED_RESEARCH"] += 1
    for item in signals:
        verdict = item.get("verdict", "NEED_RESEARCH")
        verdict_counts[verdict if verdict in verdict_counts else "NEED_RESEARCH"] += 1
    candidates = [
        f"{item.get('repo', 'unknown')}: {item.get('suggested_action', 'monitor')}"
        for item in changed
        if item.get("verdict") in {"YES_ADOPT", "YES_ADAPT"}
    ]
    candidates.extend(
        f"{item.get('source_ref', item.get('source', 'unknown'))}: {item.get('apply_to_flywheel', 'monitor')}"
        for item in signals
        if item.get("verdict") in {"YES_ADOPT", "YES_ADAPT"}
    )
    lines = [
        "## Aggregate \"What can we learn\" digest",
        bullet("Top 3 patterns from today:"),
    ]
    patterns = []
    if verdict_counts["YES_ADOPT"]:
        patterns.append("directly adoptable substrate primitives")
    if verdict_counts["YES_ADAPT"]:
        patterns.append("portable infrastructure patterns needing local fit checks")
    if verdict_counts["NO_NOT_OUR_DOMAIN"]:
        patterns.append("domain-specific ML work to watch without adopting")
    if not patterns:
        patterns.append("insufficient signal; review needed")
    lines.extend(f"  - {pattern}" for pattern in patterns[:3])
    lines.append(bullet("Cross-repo themes: " + ", ".join(f"{k}={v}" for k, v in verdict_counts.items())))
    lines.append(bullet("Candidate adopt-jeff-pattern beads:"))
    if candidates:
        lines.extend(f"  - {candidate}" for candidate in candidates)
    else:
        lines.append("  - none")
    return lines


def render_errors(payload):
    lines = ["## Errors"]
    errors = payload.get("errors") or []
    if not errors:
        lines.append("No capture errors.")
        return lines
    for item in errors:
        lines.append(bullet(f"{item.get('repo', 'unknown')}: {item.get('code', 'unknown_error')}"))
    return lines


def render_report(payload):
    date = payload.get("report_date", "unknown-date")
    lines = [f"# Jeff Daily Report — {date}", ""]
    blocks = [
        render_metadata(payload),
        render_commits(payload),
        render_simple_list("New Releases", payload.get("releases") or [], "No new releases detected."),
        render_simple_list("New Tweets (doodlestein)", payload.get("tweets") or [], "No new tweets captured."),
        render_actionable_signals(payload),
        render_simple_list("New Blog Posts", payload.get("blog_titles") or [], "No new blog posts detected."),
        render_reindexed(payload),
        render_digest(payload),
        render_errors(payload),
    ]
    for block in blocks:
        lines.extend(block)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def schema():
    return {
        "schema_version": "jeff-report-template/schema/v1",
        "version": VERSION,
        "status": "pass",
        "input_schema": "jeff-daily-report/input/v1",
        "sections": SECTIONS,
        "verdict_enum": list(VERDICTS),
    }


parser = argparse.ArgumentParser(description="Render the L64 Jeff daily report schema.")
parser.add_argument("--input")
parser.add_argument("--output")
parser.add_argument("--example", action="store_true")
parser.add_argument("--info", action="store_true")
parser.add_argument("--schema", action="store_true")
parser.add_argument("--json", action="store_true")
args = parser.parse_args()

if args.info or args.schema:
    payload = schema()
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")) if args.json else "\n".join(SECTIONS))
    sys.exit(0)

input_payload = load_payload(args.input, args.example)
report = render_report(input_payload)
if args.output:
    output = Path(args.output).expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(report)
else:
    sys.stdout.write(report)

receipt = {
    "schema_version": "jeff-report-template/run/v1",
    "version": VERSION,
    "status": "pass",
    "output": args.output or "stdout",
    "sections": SECTIONS,
    "verdict_enum": list(VERDICTS),
}
if args.json:
    print(json.dumps(receipt, sort_keys=True, separators=(",", ":")))
sys.exit(0)
PY
