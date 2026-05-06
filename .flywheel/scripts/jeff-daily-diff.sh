#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export JEFF_DAILY_DIFF_SCRIPT_DIR="$SCRIPT_DIR"

exec python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = "jeff-daily-diff.v1"


def utc_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def day_from_iso(ts):
    return ts[:10]


def default_repo_root():
    env = os.environ.get("JEFF_DAILY_DIFF_REPO_ROOT")
    if env:
        return Path(env).expanduser()
    canonical = Path.home() / "Developer/jeff-corpus"
    legacy = Path.home() / "Developer/dicklesworthstone-stack"
    return canonical if canonical.exists() else legacy


def run(cmd, cwd=None, timeout=300):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired as exc:
        return 124, exc.stdout or "", exc.stderr or "timeout"


def git(repo, *args, timeout=300):
    return run(["git", "-C", str(repo), *args], timeout=timeout)


def load_json(path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def atomic_write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
        fh.write("\n")
        fh.flush()
        os.fsync(fh.fileno())
    Path(tmp).replace(path)


def append_jsonl(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def discover_repos(root, max_repos=None):
    if not root.exists():
        return []
    repos = [
        p for p in sorted(root.iterdir(), key=lambda item: item.name.lower())
        if p.is_dir() and not p.name.startswith(".") and (p / ".git").exists()
    ]
    return repos[:max_repos] if max_repos else repos


def commit_lines(repo, previous, head):
    if not previous or previous == head:
        return []
    rc, out, _ = git(repo, "log", "--oneline", f"{previous}..{head}", "--")
    if rc != 0:
        rc, out, _ = git(repo, "log", "--oneline", "--max-count=20", "--")
    return [line for line in out.splitlines() if line.strip()]


def stat_text(repo, previous, head, since, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{repo.name}.txt"
    if previous and previous != head:
        rc, out, err = git(repo, "log", "--stat", f"{previous}..{head}", "--")
    else:
        rc, out, err = git(repo, "log", "--stat", f"--since={since}", "--")
    path.write_text(out if rc == 0 else err)
    return path


def sha256_text(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def read_text_source(fixture, command, url, timeout=30):
    if fixture:
        path = Path(fixture).expanduser()
        return {"status": "pass", "text": path.read_text() if path.exists() else "", "source": str(path)}
    if command:
        rc, out, err = run(command, timeout=timeout)
        return {"status": "pass" if rc == 0 else "fail", "text": out, "source": " ".join(command), "error": err.strip()}
    if url:
        curl = shutil.which("curl")
        if not curl:
            return {"status": "skipped", "text": "", "source": url, "error": "curl_missing"}
        rc, out, err = run([curl, "-fsSL", "--max-time", str(timeout), url], timeout=timeout + 5)
        return {"status": "pass" if rc == 0 else "fail", "text": out, "source": url, "error": err.strip()}
    return {"status": "skipped", "text": "", "source": "none"}


def rss_titles(text):
    raw_titles = re.findall(r"<title>(.*?)</title>", text, flags=re.I | re.S)
    cleaned = []
    for raw in raw_titles:
        title = re.sub(r"^<!\[CDATA\[|\]\]>$", "", raw.strip())
        title = re.sub(r"\s+", " ", title).strip()
        if title:
            cleaned.append(title)
    return cleaned[:20]


def script_path(name, env_name):
    override = os.environ.get(env_name)
    if override:
        return Path(override).expanduser()
    script_dir = Path(os.environ.get("JEFF_DAILY_DIFF_SCRIPT_DIR", ".")).expanduser()
    return script_dir / name


def diff_shortstat(repo, previous, head):
    if previous and previous != head:
        rc, out, _ = git(repo, "diff", "--shortstat", f"{previous}..{head}", "--")
    else:
        rc, out, _ = git(repo, "show", "--shortstat", "--format=", head, "--")
    if rc != 0:
        return {"files_changed": 0, "insertions": 0, "deletions": 0}
    files = re.search(r"(\d+) files? changed", out)
    insertions = re.search(r"(\d+) insertions?\(\+\)", out)
    deletions = re.search(r"(\d+) deletions?\(-\)", out)
    return {
        "files_changed": int(files.group(1)) if files else 0,
        "insertions": int(insertions.group(1)) if insertions else 0,
        "deletions": int(deletions.group(1)) if deletions else 0,
    }


def verdict_for(repo_name, commits, diff_path):
    verdict_script = script_path("jeff-verdict-heuristic.sh", "JEFF_VERDICT_HEURISTIC_BIN")
    if not verdict_script.exists():
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script missing: {verdict_script}",
            "suggested_action": "monitor",
            "matched": [],
        }
    cmd = [str(verdict_script), "--repo", repo_name, "--diff", str(diff_path), "--json"]
    for commit in commits[:20]:
        cmd.extend(["--commit", commit])
    rc, out, err = run(cmd, timeout=30)
    if rc != 0:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script failed: {err.strip()[:160]}",
            "suggested_action": "monitor",
            "matched": [],
        }
    try:
        payload = json.loads(out)
    except Exception:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": "verdict script returned invalid JSON",
            "suggested_action": "monitor",
            "matched": [],
        }
    return {
        "verdict": payload.get("verdict", "NEED_RESEARCH"),
        "reason": payload.get("reason", "needs human review"),
        "suggested_action": payload.get("suggested_action", "monitor"),
        "matched": payload.get("matched", []),
    }


def verdict_for_text(source_name, text):
    verdict_script = script_path("jeff-verdict-heuristic.sh", "JEFF_VERDICT_HEURISTIC_BIN")
    if not verdict_script.exists():
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script missing: {verdict_script}",
            "suggested_action": "monitor",
            "matched": [],
        }
    rc, out, err = run([str(verdict_script), "--repo", source_name, "--text", text, "--json"], timeout=30)
    if rc != 0:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script failed: {err.strip()[:160]}",
            "suggested_action": "monitor",
            "matched": [],
        }
    try:
        payload = json.loads(out)
    except Exception:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": "verdict script returned invalid JSON",
            "suggested_action": "monitor",
            "matched": [],
        }
    return {
        "verdict": payload.get("verdict", "NEED_RESEARCH"),
        "reason": payload.get("reason", "needs human review"),
        "suggested_action": payload.get("suggested_action", "monitor"),
        "matched": payload.get("matched", []),
    }


def text_blocks(text):
    blocks = [part.strip() for part in re.split(r"(?m)^---\s*$", text) if part.strip()]
    if len(blocks) > 1:
        return blocks
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return ["\n".join(lines[idx:idx + 3]) for idx in range(0, len(lines), 3)]


def source_ref(source_name, index, text):
    match = re.search(r"https?://\S+", text)
    if match:
        return match.group(0).rstrip(").,")
    id_match = re.search(r"\bID:\s*`?([0-9]+)`?", text)
    if id_match:
        return f"{source_name}#{id_match.group(1)}"
    return f"{source_name}#{index}"


def signal_class(matched):
    text = " ".join(matched)
    labels = [
        ("agent-mail", r"agent|mail|mcp"),
        ("beads", r"beads?"),
        ("socraticode", r"socraticode"),
        ("dcg", r"dcg"),
        ("cass", r"cass"),
        ("ntm", r"ntm"),
        ("flywheel", r"flywheel"),
        ("skills", r"skills?"),
        ("structured-concurrency", r"structured|quiescence|asupersync"),
        ("callback-contract", r"callback"),
        ("doctor-surface", r"doctor"),
        ("cli-surface", r"\bcli\b"),
    ]
    lowered = text.lower()
    for label, pattern in labels:
        if re.search(pattern, lowered):
            return label
    return "review"


def actionable_signals(source_name, text, limit=12):
    rows = []
    for index, block in enumerate(text_blocks(text), start=1):
        verdict = verdict_for_text(source_name, block)
        if verdict["verdict"] not in {"YES_ADOPT", "YES_ADAPT", "NEED_RESEARCH"}:
            continue
        if verdict["verdict"] == "NEED_RESEARCH" and not verdict.get("matched"):
            continue
        rows.append({
            "source": source_name,
            "source_ref": source_ref(source_name, index, block),
            "signal_class": signal_class(verdict.get("matched", [])),
            "verdict": verdict["verdict"],
            "reason": verdict["reason"],
            "apply_to_flywheel": verdict["suggested_action"],
            "matched": verdict.get("matched", []),
            "evidence": re.sub(r"\s+", " ", block).strip()[:240],
        })
        if len(rows) >= limit:
            break
    return rows


def write_report(path, tmp_path, payload, dry_run):
    template_script = script_path("jeff-report-template.sh", "JEFF_REPORT_TEMPLATE_BIN")
    if not template_script.exists():
        raise RuntimeError(f"report template missing: {template_script}")
    payload_path = tmp_path.with_suffix(".input.json")
    payload_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    rc, out, err = run([str(template_script), "--input", str(payload_path), "--output", str(tmp_path), "--json"], timeout=60)
    if rc != 0:
        raise RuntimeError(f"report template failed rc={rc}: {err.strip() or out.strip()}")
    if not dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(tmp_path.read_text())


def info(args):
    return {
        "schema_version": "jeff-daily-diff/info/v1",
        "version": VERSION,
        "status": "pass",
        "repo_root": str(args.repo_root),
        "state_file": str(args.state_file),
        "reports_dir": str(args.reports_dir),
        "runs_ledger": str(args.runs_ledger),
        "reindex_queue": str(args.reindex_queue),
        "dry_run_supported": True,
    }


def schema():
    return {
        "schema_version": "jeff-daily-diff/schema/v1",
        "status": "pass",
        "receipt_required": ["status", "changed_repo_count", "reindex_queued_count", "report_path", "state_file"],
        "state_file": "jeff-daily-diff-state/v1",
        "report_sections": [
            "Run metadata",
            "New Commits (by repo)",
            "New Releases",
            "New Tweets (doodlestein)",
            "New Blog Posts",
            "Re-indexed (socraticode)",
            "Aggregate \"What can we learn\" digest",
        ],
        "verdict_enum": ["YES_ADOPT", "YES_ADAPT", "NO_NOT_OUR_DOMAIN", "NEED_RESEARCH"],
    }


def run_daily(args):
    start = time.time()
    now = args.now or utc_now()
    state = load_json(args.state_file, {"schema_version": "jeff-daily-diff-state/v1", "repos": {}, "blog": {}, "x": {}})
    state.setdefault("repos", {})
    repos = discover_repos(args.repo_root, args.max_repos)
    tmp_diff = Path(tempfile.mkdtemp(prefix="jeff-diff-", dir=args.tmp_dir))
    changed, queued, errors, processed, releases = [], [], [], [], []

    for repo in repos:
        name = repo.name
        prev = state["repos"].get(name, {}).get("last_seen_sha")
        fetch_rc = 0
        if not args.dry_run and not args.skip_fetch:
            fetch_rc, _, fetch_err = git(repo, "fetch", "--all", "--tags", "--prune", timeout=args.fetch_timeout)
            if fetch_rc != 0:
                errors.append({"repo": name, "code": "git_fetch_failed", "detail": fetch_err.strip()[:300]})
        rc, head, err = git(repo, "rev-parse", "HEAD")
        if rc != 0:
            errors.append({"repo": name, "code": "git_head_failed", "detail": err.strip()[:300]})
            continue
        head = head.strip()
        rc, tag_out, _ = git(repo, "tag", "--list")
        tags = sorted([line for line in tag_out.splitlines() if line.strip()]) if rc == 0 else []
        prior_tags = set(state["repos"].get(name, {}).get("last_seen_tags", []))
        new_tags = [tag for tag in tags if tag not in prior_tags]
        commits = commit_lines(repo, prev, head)
        if commits:
            diff_path = stat_text(repo, prev, head, state.get("last_run_ts", "1970-01-01T00:00:00Z"), tmp_diff)
            stats = diff_shortstat(repo, prev, head)
            verdict = verdict_for(name, commits, diff_path)
            changed.append({
                "repo": name,
                "path": str(repo),
                "previous_sha": prev or "",
                "head_sha": head,
                "commit_count": len(commits),
                "commits": commits,
                "diff_path": str(diff_path),
                **stats,
                **verdict,
            })
            queued.append(name)
            if not args.dry_run:
                append_jsonl(args.reindex_queue, {"schema_version": "jeff-daily-reindex-queue/v1", "ts": now, "repo": name, "path": str(repo), "old_sha": prev, "new_sha": head, "reason": "new_commits"})
        for tag in new_tags:
            releases.append(f"{name}: {tag}")
        processed.append(name)
        if not args.dry_run and fetch_rc == 0:
            state["repos"][name] = {"path": str(repo), "last_seen_sha": head, "last_seen_tags": tags, "last_success_ts": now}

    x_result = read_text_source(args.x_fixture, args.x_command, None)
    if x_result["status"] == "fail":
        errors.append({"repo": "x:doodlestein", "code": "x_capture_failed"})
    rss_result = read_text_source(args.rss_fixture, None, args.rss_url)
    blog_hash = sha256_text(rss_result["text"])
    previous_blog_hash = state.get("blog", {}).get("last_hash")
    blog_titles = rss_titles(rss_result["text"]) if rss_result["status"] == "pass" and blog_hash != previous_blog_hash else []
    if rss_result["status"] == "fail":
        errors.append({"repo": "jeffreyemanuel.com", "code": "rss_capture_failed"})

    report_name = f"jeff-report-{day_from_iso(now)}.md"
    report_path = args.reports_dir / report_name
    tmp_report = Path(args.tmp_dir) / report_name
    duration_sec = max(0, round(time.time() - start, 3))
    tweet_lines = [line for line in x_result["text"].splitlines() if line.strip()]
    signals = actionable_signals("x:doodlestein", x_result["text"])
    if blog_titles:
        signals.extend(actionable_signals("jeffreyemanuel.com", "\n".join(blog_titles)))
    report_payload = {
        "schema_version": "jeff-daily-report/input/v1",
        "report_date": day_from_iso(now),
        "run_metadata": {
            "run_ts": now,
            "duration_sec": duration_sec,
            "repos_checked": len(repos),
            "repos_with_changes": len(changed),
            "new_commits_total": sum(item["commit_count"] for item in changed),
            "new_tweets": len(tweet_lines),
            "new_blog_posts": len(blog_titles),
            "re_indexed_repos": len(queued),
        },
        "repo_root": str(args.repo_root),
        "changed": changed,
        "releases": releases,
        "tweets": tweet_lines,
        "actionable_signals": signals,
        "blog_titles": blog_titles,
        "reindexed": [{"repo": repo, "new_chunks_indexed": "queued"} for repo in queued],
        "errors": errors,
        "dry_run": args.dry_run,
        "skip_fetch": args.skip_fetch,
    }
    write_report(report_path, tmp_report, report_payload, args.dry_run)

    if not args.dry_run:
        state["schema_version"] = "jeff-daily-diff-state/v1"
        state["last_run_ts"] = now
        state["blog"] = {"last_hash": blog_hash, "last_checked_ts": now}
        state["x"] = {"last_hash": sha256_text(x_result["text"]), "last_checked_ts": now}
        atomic_write_json(args.state_file, state)

    receipt = {
        "schema_version": "jeff-daily-diff-run/v1",
        "version": VERSION,
        "status": "pass" if repos else "fail",
        "ts": now,
        "dry_run": args.dry_run,
        "skip_fetch": args.skip_fetch,
        "repo_root": str(args.repo_root),
        "repo_count": len(repos),
        "processed_repo_count": len(processed),
        "changed_repo_count": len(changed),
        "actionable_signal_count": len(signals),
        "reindex_queued_count": len(queued),
        "new_release_count": len(releases),
        "sources_failed": len(errors),
        "report_path": str(report_path if not args.dry_run else tmp_report),
        "tmp_report_path": str(tmp_report),
        "state_file": str(args.state_file),
        "runs_ledger": str(args.runs_ledger),
        "reindex_queue": str(args.reindex_queue),
        "errors": errors,
    }
    if not args.dry_run:
        append_jsonl(args.runs_ledger, receipt)
    return receipt


def parse_args():
    parser = argparse.ArgumentParser(description="Build daily Jeff corpus diffs and report.")
    parser.add_argument("--repo-root", type=Path, default=default_repo_root())
    parser.add_argument("--state-dir", type=Path, default=Path(os.environ.get("JEFF_INTEL_STATE_DIR", str(Path.home() / ".local/state/jeff-intel"))).expanduser())
    parser.add_argument("--state-file", type=Path)
    parser.add_argument("--reports-dir", type=Path)
    parser.add_argument("--runs-ledger", type=Path)
    parser.add_argument("--reindex-queue", type=Path)
    parser.add_argument("--tmp-dir", type=Path, default=Path(os.environ.get("JEFF_DAILY_DIFF_TMP_DIR", "/tmp")))
    parser.add_argument("--x-fixture")
    parser.add_argument("--rss-fixture")
    parser.add_argument("--rss-url", default=os.environ.get("JEFF_DAILY_DIFF_RSS_URL", "https://jeffreyemanuel.com/rss.xml"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-fetch", action="store_true", default=os.environ.get("JEFF_DAILY_DIFF_SKIP_FETCH", "") == "1")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--now", default=os.environ.get("JEFF_DAILY_DIFF_NOW", ""))
    parser.add_argument("--max-repos", type=int)
    parser.add_argument("--fetch-timeout", type=int, default=30)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    args = parser.parse_args()
    args.repo_root = args.repo_root.expanduser()
    args.state_file = args.state_file or args.state_dir / "last-diff-run.json"
    args.reports_dir = args.reports_dir or args.state_dir / "reports"
    args.runs_ledger = args.runs_ledger or args.state_dir / "daily-runs.jsonl"
    args.reindex_queue = args.reindex_queue or args.state_dir / "reindex-queue.jsonl"
    x_cmd = os.environ.get("JEFF_DAILY_DIFF_X_COMMAND")
    args.x_command = x_cmd.split() if x_cmd else (["x-cli", "-md", "user", "timeline", "doodlestein", "--max", "20"] if shutil.which("x-cli") else None)
    return args


args = parse_args()
if args.examples:
    print("jeff-daily-diff.sh --dry-run --json")
    print("JEFF_INTEL_STATE_DIR=/tmp/jeff-state jeff-daily-diff.sh --repo-root /Users/josh/Developer/jeff-corpus --json")
    sys.exit(0)
if args.info:
    payload = info(args)
elif args.schema:
    payload = schema()
elif args.doctor:
    payload = info(args) | {"mode": "doctor", "status": "pass" if args.repo_root.exists() else "fail", "repo_root_exists": args.repo_root.exists()}
else:
    payload = run_daily(args)

if args.json or args.info or args.schema or args.doctor:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(f"{payload['status']} changed={payload.get('changed_repo_count', 0)} report={payload.get('report_path', 'none')}")
sys.exit(0 if payload.get("status") == "pass" else 1)
PY
