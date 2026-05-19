#!/usr/bin/env bash
set -euo pipefail

JSON_OUT=0
PACK_PATH=""

usage() {
  cat <<'EOF'
usage:
  evidence-pack-resolve.sh <evidence-pack-file> [--json]

Validates evidence_pack_version: 2 packs. Legacy packs without
evidence_pack_version: 2 are skipped with exit 0.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "ERR: unknown flag: $1" >&2; exit 2 ;;
    *) PACK_PATH="$1"; shift ;;
  esac
done

if [[ -z "$PACK_PATH" ]]; then
  usage >&2
  exit 2
fi

python3 - "$PACK_PATH" "$JSON_OUT" <<'PY'
import json
import re
import sys
from pathlib import Path

pack_path = Path(sys.argv[1]).expanduser()
json_out = sys.argv[2] == "1"


def emit(payload, rc):
    text = json.dumps(payload, sort_keys=True)
    if json_out:
        print(text)
    else:
        status = payload.get("status", "unknown")
        errors = payload.get("errors") or []
        if errors:
            print(f"{status}: " + "; ".join(errors))
        else:
            print(status)
    sys.exit(rc)


def strip_frontmatter(text):
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for idx in range(1, len(lines)):
            if lines[idx].strip() == "---":
                return "\n".join(lines[1:idx])
    return text


def parse_scalar(value):
    value = value.strip()
    if value in {"", "null"}:
        return None if value == "null" else ""
    if value == "[]":
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(part.strip()) for part in inner.split(",")]
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    if value == "true":
        return True
    if value == "false":
        return False
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    return value


def split_key_value(text):
    if ":" not in text:
        return None, None
    key, value = text.split(":", 1)
    return key.strip(), parse_scalar(value.strip())


def parse_minimal_yaml(text):
    data = {}
    top = None
    current = None
    current_edge = None
    for raw in strip_frontmatter(text).splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()
        if indent == 0 and line.endswith(":"):
            top = line[:-1]
            data.setdefault(top, [])
            current = None
            current_edge = None
            continue
        if indent == 0 and ":" in line:
            key, value = split_key_value(line)
            data[key] = value
            top = None
            current = None
            current_edge = None
            continue
        if top not in {"items", "claims"}:
            continue
        if indent == 2 and line.startswith("- "):
            current = {}
            data.setdefault(top, []).append(current)
            current_edge = None
            rest = line[2:].strip()
            if rest:
                key, value = split_key_value(rest)
                if key:
                    current[key] = value
            continue
        if current is None:
            continue
        if indent == 4 and line.endswith(":"):
            key = line[:-1]
            current[key] = []
            current_edge = None
            continue
        if indent == 4 and ":" in line:
            key, value = split_key_value(line)
            current[key] = value
            continue
        if indent == 6 and line.startswith("- "):
            current_edge = {}
            current.setdefault("edges", []).append(current_edge)
            rest = line[2:].strip()
            if rest:
                key, value = split_key_value(rest)
                if key:
                    current_edge[key] = value
            continue
        if indent >= 8 and current_edge is not None and ":" in line:
            key, value = split_key_value(line)
            current_edge[key] = value
    return data


def load_pack(path):
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as exc:
        emit({
            "status": "fail",
            "pack_path": str(path),
            "errors": [f"pack_read_failed:{type(exc).__name__}:{exc}"],
        }, 1)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    try:
        import yaml  # type: ignore
        loaded = yaml.safe_load(strip_frontmatter(text))
        if isinstance(loaded, dict):
            return loaded
    except Exception:
        pass
    return parse_minimal_yaml(text)


def resolve_anchor(anchor, base_dir):
    match = re.fullmatch(r"(.+):(\d+)-(\d+)", anchor or "")
    if not match:
        return None, "anchor_not_file_line_range"
    raw_file, start_raw, end_raw = match.groups()
    start, end = int(start_raw), int(end_raw)
    if start < 1 or end < start:
        return None, "anchor_invalid_range"
    candidates = [Path(raw_file).expanduser()]
    if not candidates[0].is_absolute():
        candidates = [base_dir / raw_file, Path.cwd() / raw_file]
    resolved = None
    for candidate in candidates:
        if candidate.is_file():
            resolved = candidate
            break
    if resolved is None:
        return None, "anchor_file_missing"
    try:
        line_count = sum(1 for _ in resolved.open("r", encoding="utf-8", errors="replace"))
    except Exception as exc:
        return None, f"anchor_file_unreadable:{type(exc).__name__}"
    if end > line_count:
        return None, f"anchor_range_out_of_bounds:{line_count}"
    return str(resolved), None


pack = load_pack(pack_path)
if not isinstance(pack, dict):
    emit({
        "status": "fail",
        "pack_path": str(pack_path),
        "errors": ["pack_not_object"],
    }, 1)

version = pack.get("evidence_pack_version")
if version != 2:
    emit({
        "status": "skipped",
        "pack_path": str(pack_path),
        "reason": "legacy_or_unversioned_pack",
        "evidence_pack_version": version,
        "errors": [],
    }, 0)

errors = []
items = pack.get("items")
claims = pack.get("claims")
if not isinstance(items, list) or not items:
    errors.append("items_missing_or_empty")
    items = []
if not isinstance(claims, list) or not claims:
    errors.append("claims_missing_or_empty")
    claims = []

item_ids = []
claim_ids = []
for item in items:
    if not isinstance(item, dict):
        errors.append("item_not_object")
        continue
    ev_id = item.get("id")
    if not isinstance(ev_id, str) or not re.fullmatch(r"EV-\d{3}", ev_id):
        errors.append(f"item_id_invalid:{ev_id}")
    else:
        item_ids.append(ev_id)
    anchor = item.get("excerpt_anchor")
    if not isinstance(anchor, str):
        errors.append(f"excerpt_anchor_missing:{ev_id}")
    else:
        _, anchor_error = resolve_anchor(anchor, pack_path.parent)
        if anchor_error:
            errors.append(f"excerpt_anchor_unresolved:{ev_id}:{anchor_error}:{anchor}")
    edges = item.get("edges")
    if not isinstance(edges, list) or not edges:
        errors.append(f"edges_missing_or_empty:{ev_id}")
        continue
    for edge in edges:
        if not isinstance(edge, dict):
            errors.append(f"edge_not_object:{ev_id}")
            continue
        relation = edge.get("relation")
        claim_id = edge.get("claim_id")
        confidence = edge.get("confidence")
        if relation not in {"supports", "refutes", "informs"}:
            errors.append(f"edge_relation_invalid:{ev_id}:{relation}")
        if not isinstance(claim_id, str) or not re.fullmatch(r"C-\d{3}", claim_id):
            errors.append(f"edge_claim_id_invalid:{ev_id}:{claim_id}")
        if confidence not in {"high", "medium", "low"}:
            errors.append(f"edge_confidence_invalid:{ev_id}:{confidence}")

for claim in claims:
    if not isinstance(claim, dict):
        errors.append("claim_not_object")
        continue
    claim_id = claim.get("id")
    if not isinstance(claim_id, str) or not re.fullmatch(r"C-\d{3}", claim_id):
        errors.append(f"claim_id_invalid:{claim_id}")
    else:
        claim_ids.append(claim_id)
    if claim.get("status") not in {"confirmed", "refuted", "partial", "unverified"}:
        errors.append(f"claim_status_invalid:{claim_id}:{claim.get('status')}")

duplicate_items = sorted({ev_id for ev_id in item_ids if item_ids.count(ev_id) > 1})
duplicate_claims = sorted({claim_id for claim_id in claim_ids if claim_ids.count(claim_id) > 1})
errors.extend(f"duplicate_item_id:{ev_id}" for ev_id in duplicate_items)
errors.extend(f"duplicate_claim_id:{claim_id}" for claim_id in duplicate_claims)

item_id_set = set(item_ids)
claim_id_set = set(claim_ids)
for item in items:
    if not isinstance(item, dict):
        continue
    ev_id = item.get("id")
    for edge in item.get("edges") if isinstance(item.get("edges"), list) else []:
        if isinstance(edge, dict) and edge.get("claim_id") not in claim_id_set:
            errors.append(f"edge_claim_missing:{ev_id}:{edge.get('claim_id')}")

for claim in claims:
    if not isinstance(claim, dict):
        continue
    claim_id = claim.get("id")
    for field in ("evidence_supporting", "evidence_refuting"):
        refs = claim.get(field, [])
        if not isinstance(refs, list):
            errors.append(f"claim_{field}_not_array:{claim_id}")
            continue
        for ev_id in refs:
            if ev_id not in item_id_set:
                errors.append(f"claim_evidence_missing:{claim_id}:{field}:{ev_id}")

payload = {
    "status": "fail" if errors else "pass",
    "pack_path": str(pack_path),
    "evidence_pack_version": 2,
    "items": len(items),
    "claims": len(claims),
    "errors": errors,
}
emit(payload, 1 if errors else 0)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
