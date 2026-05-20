#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
STATE_FILE="${JOSH_REQUEST_STATE_FILE:-$HOME/.local/state/flywheel/josh-requests.jsonl}"
EVIDENCE_ROOTS="${JOSH_REQUEST_EVIDENCE_ROOTS:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory:$REPO_ROOT/INCIDENTS.md:$REPO_ROOT/.beads/issues.jsonl}"
JSON=0

usage() {
  cat <<'USAGE'
usage: josh-request-tick-promote.sh [--json]

Reads ~/.local/state/flywheel/josh-requests.jsonl and emits a tick prelude
summary for requests with v2 state=needs_triage or legacy v1 status=open.
Open requests with evidence already absorbed in memory, beads, or incidents
are counted as consumed_with_evidence, not unread.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR: unknown arg %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$STATE_FILE" ]]; then
  result="$(jq -nc '{action:"missing_state_file",unread:0,highest_priority:null,ids:[],state_file:env.STATE_FILE}')"
else
  result="$(
    python3 - "$STATE_FILE" "$EVIDENCE_ROOTS" <<'PY'
import json
import re
import sys
from pathlib import Path

state_file = Path(sys.argv[1]).expanduser()
evidence_roots = [Path(p).expanduser() for p in sys.argv[2].split(":") if p]


def normalized_state(row):
    if row.get("state"):
        return row.get("state")
    return "needs_triage" if row.get("status", "open") == "open" else row.get("status", "unknown")


def priority_rank(priority):
    return {"P0": 0, "P1": 1, "P2": 2, "P3": 3}.get(priority or "P1", 9)


def read_rows(path):
    rows = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


def evidence_files(root):
    if root.is_file():
        return [root]
    if not root.is_dir():
        return []
    files = []
    for candidate in root.rglob("*"):
        if candidate.is_file() and candidate.suffix.lower() in {".md", ".json", ".jsonl", ".txt"}:
            files.append(candidate)
    return files


def read_evidence(paths):
    docs = []
    blob_parts = []
    word_paths = {}
    for root in paths:
        for path in evidence_files(root):
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            lower = text.lower()
            path_s = str(path)
            docs.append((path_s, text, lower))
            blob_parts.append(lower)
            for word in set(re.findall(r"[a-zA-Z0-9][a-zA-Z0-9_-]{3,}", lower)):
                paths_for_word = word_paths.setdefault(word, [])
                if len(paths_for_word) < 8:
                    paths_for_word.append(path_s)
    return {"docs": docs, "blob": "\n".join(blob_parts), "word_paths": word_paths}


def excerpt_tokens(text):
    words = re.findall(r"[a-zA-Z0-9][a-zA-Z0-9_-]{3,}", text or "")
    stop = {
        "about",
        "after",
        "again",
        "also",
        "because",
        "been",
        "before",
        "created",
        "done",
        "from",
        "have",
        "into",
        "joshua",
        "more",
        "need",
        "needs",
        "request",
        "requests",
        "should",
        "status",
        "that",
        "then",
        "there",
        "this",
        "until",
        "updated",
        "when",
        "with",
    }
    tokens = []
    for word in words:
        token = word.lower()
        if token in stop or token in tokens:
            continue
        tokens.append(token)
        if len(tokens) >= 8:
            break
    return tokens


def row_tokens(row):
    tokens = []
    for key in ("id", "prompt_hash", "bead"):
        value = row.get(key)
        if isinstance(value, str) and value:
            tokens.append((key, value))
    for bead_id in row.get("linked_bead_ids") or []:
        if isinstance(bead_id, str) and bead_id:
            tokens.append(("linked_bead_id", bead_id))
    return tokens


def evidence_for(row, evidence_index):
    token_matches = []
    docs = evidence_index["docs"]
    blob = evidence_index["blob"]
    word_paths = evidence_index["word_paths"]
    for kind, token in row_tokens(row):
        needle = token.lower()
        if needle not in blob:
            continue
        for path, _text, lower in docs:
            if needle in lower:
                return {
                    "status": "consumed",
                    "match_type": kind,
                    "evidence_refs": [path],
                }
    excerpt = row.get("sanitized_excerpt") or row.get("excerpt") or ""
    wanted = excerpt_tokens(excerpt)
    if len(wanted) < 3:
        return {"status": "unconsumed", "match_type": None, "evidence_refs": []}
    matched = [token for token in wanted if token in word_paths]
    if len(matched) < 3:
        return {"status": "unconsumed", "match_type": None, "evidence_refs": []}
    path_counts = {}
    for token in matched:
        for path in word_paths.get(token, []):
            path_counts[path] = path_counts.get(path, 0) + 1
    for path, matched_token_count in path_counts.items():
        if matched_token_count >= 3:
            token_matches.append({
                "path": path,
                "matched_token_count": matched_token_count,
            })
    if token_matches:
        token_matches.sort(key=lambda item: item["matched_token_count"], reverse=True)
        return {
            "status": "consumed",
            "match_type": "excerpt_tokens",
            "evidence_refs": [token_matches[0]["path"]],
            "matched_token_count": token_matches[0]["matched_token_count"],
        }
    return {"status": "unconsumed", "match_type": None, "evidence_refs": []}


rows = read_rows(state_file)
docs = read_evidence(evidence_roots)
items = []
consumed = []
for row in rows:
    if normalized_state(row) != "needs_triage":
        continue
    item = {
        "id": row.get("id"),
        "priority": row.get("priority") or "P1",
        "captured_at": row.get("captured_at") or row.get("ts"),
        "source_session": row.get("source_session") or row.get("session"),
        "excerpt": row.get("sanitized_excerpt") or row.get("excerpt") or "",
    }
    evidence = evidence_for(row, docs)
    if evidence["status"] == "consumed":
        consumed.append({
            "id": item["id"],
            "priority": item["priority"],
            "captured_at": item["captured_at"],
            "source_session": item["source_session"],
            "match_type": evidence["match_type"],
            "evidence_refs": evidence["evidence_refs"],
        })
    else:
        items.append(item)

items.sort(key=lambda row: (priority_rank(row.get("priority")), row.get("captured_at") or ""))
consumed.sort(key=lambda row: (priority_rank(row.get("priority")), row.get("captured_at") or ""))
highest = items[0]["priority"] if items else None
payload = {
    "action": "surfaced",
    "state_file": str(state_file),
    "evidence_roots": [str(path) for path in evidence_roots],
    "queued_count": len(items) + len(consumed),
    "unread": len(items),
    "consumed_with_evidence_count": len(consumed),
    "highest_priority": highest,
    "ids": [row.get("id") for row in items],
    "requests": items,
    "consumed_requests": consumed[:20],
    "truncated_consumed_requests": len(consumed) > 20,
}
print(json.dumps(payload, separators=(",", ":")))
PY
  )"
fi

if [[ "$JSON" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  printf '## Joshua Requests pre-tick\n'
  jq -c '{action,unread,highest_priority,ids}' <<<"$result"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
