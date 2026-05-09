#!/usr/bin/env bash
set -euo pipefail

BODY_FILE="${1:-}"
TASK_ID="${2:-unknown}"
REPO_PATH="${3:-${PWD:-}}"
TMP_BODY=""

if [[ "$BODY_FILE" == "--help" || "$BODY_FILE" == "-h" ]]; then
  cat <<'EOF'
Usage: inject-l-rule-hints.sh <task-body-file> [task-id] [repo-path]

Injects up to three relevant canonical L-rule hints into a dispatch body.
Reads .flywheel/rules shards when present, otherwise falls back to AGENTS.md
for the default repo path. Never blocks dispatch; set L_RULE_HINTS_DISABLED=1
to pass through unchanged.
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "--info" ]]; then
  printf 'inject-l-rule-hints: rule hint injector, max_hints=3, dedupe_window_sec=1800\n'
  exit 0
fi

if [[ "$BODY_FILE" == "--schema" ]]; then
  printf '%s\n' '{"schema_version":"inject-l-rule-hints.v1","output":"markdown","max_hints":3,"dedupe_window_sec":1800}'
  exit 0
fi

if [[ "$BODY_FILE" == "--examples" ]]; then
  cat <<'EOF'
inject-l-rule-hints.sh /tmp/task-body.md flywheel-abc /Users/josh/Developer/flywheel
FLYWHEEL_L_RULES_DIR=/tmp/rules inject-l-rule-hints.sh /tmp/body.md fixture
L_RULE_HINTS_DISABLED=1 inject-l-rule-hints.sh /tmp/body.md fixture
EOF
  exit 0
fi

if [[ "$BODY_FILE" == "-" || "$BODY_FILE" == "/dev/stdin" ]]; then
  TMP_BODY="$(mktemp "${TMPDIR:-/tmp}/l-rule-hints-stdin.XXXXXX")"
  trap '[[ -z "$TMP_BODY" ]] || rm -f "$TMP_BODY"' EXIT
  cat >"$TMP_BODY"
  BODY_FILE="$TMP_BODY"
fi

if [[ -z "$BODY_FILE" || ! -r "$BODY_FILE" ]]; then
  echo "usage: inject-l-rule-hints.sh <task-body-file> [task-id] [repo-path]" >&2
  exit 2
fi

if [[ "${L_RULE_HINTS_DISABLED:-0}" == "1" ]]; then
  cat "$BODY_FILE"
  exit 0
fi

python3 - "$BODY_FILE" "$TASK_ID" "$REPO_PATH" <<'PY' || cat "$BODY_FILE"
from __future__ import annotations

import json
import os
import re
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


MAX_HINTS = 3
DEDUP_WINDOW_SEC = 1800
BODY = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
TASK_ID = sys.argv[2] or "unknown"
REPO_PATH = Path(sys.argv[3] or os.getcwd()).expanduser()


@dataclass
class Rule:
    rule_id: str
    title: str
    source: str
    text: str


STOPWORDS = {
    "about",
    "above",
    "after",
    "again",
    "against",
    "agent",
    "agents",
    "also",
    "before",
    "being",
    "block",
    "callback",
    "canonical",
    "code",
    "command",
    "dispatch",
    "done",
    "each",
    "every",
    "file",
    "files",
    "from",
    "have",
    "hint",
    "into",
    "must",
    "packet",
    "repo",
    "rule",
    "rules",
    "script",
    "should",
    "surface",
    "task",
    "that",
    "their",
    "then",
    "this",
    "when",
    "where",
    "with",
    "worker",
    "workers",
}


def token_set(text: str) -> set[str]:
    tokens = {t.lower() for t in re.findall(r"[A-Za-z][A-Za-z0-9_-]{3,}", text)}
    return {t for t in tokens if t not in STOPWORDS and not t.startswith("flywheel-")}


def clean_line(value: str, limit: int = 180) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    if len(value) > limit:
        return value[: limit - 3].rstrip() + "..."
    return value


def source_candidates(repo: Path) -> tuple[list[Path], str]:
    explicit = os.environ.get("FLYWHEEL_L_RULES_DIR")
    if explicit:
        rules_dir = Path(explicit).expanduser()
        if not rules_dir.is_dir():
            return [], f"missing_explicit_rules_dir:{rules_dir}"
        return sorted(p for p in rules_dir.rglob("*.md") if p.is_file()), str(rules_dir)

    rules_dir = repo / ".flywheel" / "rules"
    if rules_dir.is_dir():
        return sorted(p for p in rules_dir.rglob("*.md") if p.is_file()), str(rules_dir)

    for fallback in (repo / "AGENTS.md", repo / ".flywheel" / "AGENTS-CANONICAL.md"):
        if fallback.is_file():
            return [fallback], f"fallback:{fallback}"
    return [], f"missing_default_rules_dir:{rules_dir}"


def parse_rule_file(path: Path) -> list[Rule]:
    text = path.read_text(encoding="utf-8", errors="replace")
    matches = list(re.finditer(r"^##\s+(L[0-9]+)\s+[—-]\s+(.+?)\s*$", text, flags=re.M))
    if not matches:
        stem = path.stem
        m = re.search(r"(L[0-9]+)", stem, flags=re.I)
        if not m:
            return []
        title_match = re.search(r"^title:\s*(.+)$", text, flags=re.M)
        title = title_match.group(1).strip() if title_match else stem
        return [Rule(m.group(1).upper(), clean_line(title, 80), str(path), text)]

    rules: list[Rule] = []
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        chunk = text[start:end]
        rules.append(Rule(match.group(1).upper(), clean_line(match.group(2), 80), str(path), chunk))
    return rules


def load_rules(repo: Path) -> tuple[list[Rule], str]:
    paths, source = source_candidates(repo)
    rules: list[Rule] = []
    for path in paths:
        try:
            rules.extend(parse_rule_file(path))
        except OSError:
            continue
    return rules, source


def score_rule(rule: Rule, body_tokens: set[str], body_lc: str) -> tuple[int, list[str]]:
    title_tokens = token_set(rule.title)
    frontmatter_tokens = token_set("\n".join(re.findall(r"^(?:title|trauma_class):\s*(.+)$", rule.text, flags=re.M)))
    rule_tokens = token_set(rule.text)
    shared_title = body_tokens & title_tokens
    shared_frontmatter = body_tokens & frontmatter_tokens
    shared_rule = body_tokens & rule_tokens

    score = len(shared_title) * 8 + len(shared_frontmatter) * 6 + len(shared_rule)
    reasons = sorted(shared_title | shared_frontmatter | set(list(shared_rule)[:5]))

    if re.search(rf"\b{re.escape(rule.rule_id.lower())}\b", body_lc):
        score += 50
        reasons.insert(0, rule.rule_id)

    trauma = re.search(r"^trauma_class:\s*(.+)$", rule.text, flags=re.M)
    if trauma:
        trauma_value = trauma.group(1).strip().lower()
        trauma_tokens = token_set(trauma_value)
        if trauma_value and trauma_value in body_lc:
            score += 25
            reasons.insert(0, trauma_value)
        elif body_tokens & trauma_tokens:
            score += 10

    return score, reasons[:6]


def dedupe_log_path() -> Path:
    raw = os.environ.get("FLYWHEEL_L_RULE_HINTS_LOG")
    if raw:
        return Path(raw).expanduser()
    return Path.home() / ".cache" / "flywheel-l-rule-hints-emitted.jsonl"


def usage_log_path() -> Path:
    raw = os.environ.get("FLYWHEEL_RULE_HINT_USAGE_LOG")
    if raw:
        return Path(raw).expanduser()
    return Path.home() / ".local" / "state" / "flywheel" / "rule-hint-usage.jsonl"


def extract_bead_id() -> str | None:
    for pattern in (
        r"(?m)^#\s*Bead:\s*([A-Za-z0-9._-]+)",
        r"(?m)^#\s*Task ID:\s*([A-Za-z0-9]+-[A-Za-z0-9]+)",
        r"(?m)^bead=([A-Za-z0-9._-]+)",
    ):
        match = re.search(pattern, BODY)
        if match:
            return match.group(1)
    match = re.match(r"([A-Za-z0-9]+-[A-Za-z0-9]+)", TASK_ID)
    return match.group(1) if match else None


def recently_emitted(log_path: Path, rule_id: str, now: int) -> bool:
    try:
        rows = log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-500:]
    except OSError:
        return False
    for line in reversed(rows):
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get("task_id") != TASK_ID or row.get("rule_id") != rule_id:
            continue
        try:
            ts = int(row.get("ts", 0))
        except (TypeError, ValueError):
            ts = 0
        return ts > 0 and now - ts < DEDUP_WINDOW_SEC
    return False


def record_emits(log_path: Path, rule_ids: list[str], now: int) -> None:
    if not rule_ids:
        return
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        prior = []
        if log_path.is_file():
            prior = log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-500:]
        rows = [*prior]
        rows.extend(json.dumps({"task_id": TASK_ID, "rule_id": rule_id, "ts": now}, separators=(",", ":")) for rule_id in rule_ids)
        tmp = log_path.with_suffix(log_path.suffix + ".tmp")
        tmp.write_text("\n".join(rows) + "\n", encoding="utf-8")
        tmp.replace(log_path)
    except OSError:
        return


def record_usage(rule_ids: list[str], source: str) -> None:
    if not rule_ids:
        return
    path = usage_log_path()
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    bead_id = extract_bead_id()
    rows = [
        {
            "schema_version": "rule-hint-usage/v1",
            "ts": ts,
            "rule_id": rule_id,
            "dispatch_id": TASK_ID,
            "task_id": TASK_ID,
            "bead_id": bead_id,
            "repo_path": str(REPO_PATH),
            "source": source,
        }
        for rule_id in rule_ids
    ]
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as handle:
            for row in rows:
                handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    except OSError:
        return


def build_section(matches: list[tuple[Rule, int, list[str]]], source: str) -> str:
    if not matches:
        return ""
    lines = [
        "## L-RULE HINTS",
        "",
        f"l_rule_hints={len(matches)}",
        f"l_rule_hints_task_id={TASK_ID}",
        f"l_rule_hints_source={source}",
        "l_rule_hints_matched=" + ",".join(rule.rule_id for rule, _, _ in matches),
        "",
        "Relevant canonical doctrine hints for this dispatch. Treat these as pointers, not new acceptance gates.",
    ]
    for rule, score, reasons in matches:
        why = ",".join(reasons) if reasons else "content-overlap"
        lines.extend(
            [
                "",
                f"### {rule.rule_id} — {rule.title}",
                f"source={rule.source}",
                f"score={score}",
                f"why={clean_line(why, 120)}",
            ]
        )
    return "\n".join(lines) + "\n"


def inject(section: str) -> str:
    if not section or re.search(r"^## L-RULE HINTS\s*$", BODY, flags=re.M):
        return BODY if BODY.endswith("\n") else BODY + "\n"
    marker = "\n## BEAD-ANATOMY"
    if marker in BODY:
        return BODY.replace(marker, f"\n{section}{marker}", 1)
    return BODY.rstrip() + "\n\n" + section


body_tokens = token_set(BODY)
body_lc = BODY.lower()
rules, source = load_rules(REPO_PATH)
now = int(time.time())
log_path = dedupe_log_path()

scored: list[tuple[Rule, int, list[str]]] = []
for rule in rules:
    score, reasons = score_rule(rule, body_tokens, body_lc)
    if score <= 0:
        continue
    if recently_emitted(log_path, rule.rule_id, now):
        continue
    scored.append((rule, score, reasons))

scored.sort(key=lambda item: (-item[1], item[0].rule_id))
selected = scored[:MAX_HINTS]
selected_rule_ids = [rule.rule_id for rule, _, _ in selected]
record_emits(log_path, selected_rule_ids, now)
record_usage(selected_rule_ids, source)
print(inject(build_section(selected, source)), end="")
PY
