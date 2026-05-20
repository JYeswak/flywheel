#!/usr/bin/env bash
set -euo pipefail

TOPOLOGY="${CODEX_GOAL_FORMAT_TOPOLOGY:-${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}}"
ROSTER="${CODEX_GOAL_FORMAT_TEAM_ROSTER:-${FLYWHEEL_TEAM_ROSTER:-$HOME/.local/state/flywheel/team-roster.jsonl}}"
TMP_GLOB="${CODEX_GOAL_FORMAT_DISPATCH_GLOB:-/tmp/*dispatch*.md}"
json=0

usage() {
  cat <<'EOF'
usage: codex-dispatch-format-audit.sh [--json]

Audits recent dispatch packet files and reports /goal first-line compliance per
active orchestrator session from team-roster/session-topology.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

python3 - "$TOPOLOGY" "$ROSTER" "$TMP_GLOB" "$json" <<'PY'
import glob
import json
import re
import sys
from pathlib import Path

topology = Path(sys.argv[1]).expanduser()
roster = Path(sys.argv[2]).expanduser()
pattern = sys.argv[3]
as_json = sys.argv[4] == "1"


def load_jsonl(path):
    rows = []
    if not path.is_file():
        return rows
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return rows


topology_rows = load_jsonl(topology)
latest = {}
for row in topology_rows:
    session = row.get("session")
    if not session:
        continue
    if session not in latest or (row.get("effective_at") or "") > (latest[session].get("effective_at") or ""):
        latest[session] = row

roster_rows = load_jsonl(roster)
active = []
for row in roster_rows:
    session = row.get("session")
    event = row.get("event", "")
    if session and event != "session_dormant" and session not in active:
        active.append(session)
if not active:
    active = sorted(latest)

files = [Path(p) for p in glob.glob(pattern)]
rows = []
for session in active:
    session_files = [p for p in files if session in p.name]
    if not session_files:
        session_files = files
    total = 0
    compliant = 0
    examples = []
    for path in session_files:
        try:
            first = path.read_text(encoding="utf-8", errors="replace").splitlines()[0]
        except Exception:
            first = ""
        if re.match(r"^/goal\s+", first):
            compliant += 1
        elif len(examples) < 5:
            examples.append(str(path))
        total += 1
    rate = None if total == 0 else round((compliant / total) * 100, 2)
    rows.append({
        "session": session,
        "orchestrator_pane": latest.get(session, {}).get("orchestrator_pane"),
        "packet_count": total,
        "goal_prefixed_count": compliant,
        "compliance_rate": rate,
        "noncompliant_examples": examples,
    })

out = {
    "schema_version": "codex-dispatch-format-audit/v0.1",
    "topology": str(topology),
    "team_roster": str(roster),
    "dispatch_glob": pattern,
    "session_count": len(rows),
    "sessions": rows,
}
if as_json:
    print(json.dumps(out, sort_keys=True))
else:
    for row in rows:
        rate = "n/a" if row["compliance_rate"] is None else f"{row['compliance_rate']:.2f}%"
        print(f"{row['session']} packets={row['packet_count']} goal={row['goal_prefixed_count']} compliance={rate}")
PY
