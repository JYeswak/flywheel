#!/usr/bin/env bash
set -u -o pipefail

usage() {
  cat <<'EOF'
usage:
  three-judges-rework-bead-opener.sh --repo PATH --parent-bead ID --facet-id F1 --facet NAME --score N --reason TEXT [--json]
  three-judges-rework-bead-opener.sh --info|--help
EOF
}

info() {
  jq -nc '{name:"three-judges-rework-bead-opener.sh",schema_version:"three-judges-rework-bead/v1",purpose:"idempotent JSONL fallback rework bead opener"}'
}

case "${1:-}" in
  --help|-h|help|"") usage; exit 0 ;;
  --info|info) info; exit 0 ;;
esac

python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

def safe(text):
    out = "".join(ch.lower() if ch.isalnum() else "-" for ch in text)
    while "--" in out: out = out.replace("--", "-")
    return out.strip("-") or "unknown"

def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

parser = argparse.ArgumentParser()
parser.add_argument("--repo", required=True)
parser.add_argument("--parent-bead", required=True)
parser.add_argument("--facet-id", required=True)
parser.add_argument("--facet", required=True)
parser.add_argument("--score", required=True)
parser.add_argument("--reason", required=True)
parser.add_argument("--json", action="store_true")
args = parser.parse_args()

repo = Path(args.repo).expanduser().resolve()
issues = repo / ".beads/issues.jsonl"
issues.parent.mkdir(parents=True, exist_ok=True)
key = f"{args.parent_bead}:{args.facet_id}:{args.facet}"
digest = hashlib.sha256(key.encode()).hexdigest()[:10]
bead_id = f"flywheel-three-judges-{digest}"
title = f"rework-publishability-{safe(args.facet_id)}-{safe(args.facet)}"

existing = None
if issues.exists():
    for line in issues.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if row.get("title") == title and row.get("parent_bead") == args.parent_bead:
            existing = row.get("id")

if existing:
    payload = {"schema_version":"three-judges-rework-bead/v1","status":"pass","action":"reused","fix_bead_id":existing,"title":title,"facet_id":args.facet_id}
else:
    ts = now()
    desc = (
        f"Three-judges publishability close gate refused parent bead {args.parent_bead}.\n\n"
        f"facet_id={args.facet_id}\nfacet={args.facet}\nscore={args.score}\nreason={args.reason}\n\n"
        "Acceptance: improve the facet evidence, rerun three-judges-publishability-validator.sh in strict mode, and close only when composite >=7 with no REFUSE decision."
    )
    row = {
        "id": bead_id,
        "title": title,
        "description": desc,
        "status": "open",
        "priority": 1,
        "issue_type": "bug",
        "created_at": ts,
        "created_by": "three-judges-publishability-validator",
        "updated_at": ts,
        "source_repo": str(repo),
        "parent_bead": args.parent_bead,
        "labels": ["three-judges", "publishability", "auto-rework"],
        "compaction_level": 0,
        "original_size": 0,
    }
    with issues.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    payload = {"schema_version":"three-judges-rework-bead/v1","status":"pass","action":"jsonl_fallback","fix_bead_id":bead_id,"title":title,"facet_id":args.facet_id}

print(json.dumps(payload, sort_keys=True) if args.json else f"action={payload['action']} fix_bead_id={payload['fix_bead_id']}")
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
