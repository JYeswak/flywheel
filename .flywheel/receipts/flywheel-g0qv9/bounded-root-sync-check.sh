#!/usr/bin/env bash
set -euo pipefail

SOURCE="/Users/josh/Developer/flywheel/AGENTS.md"
MODE="check"
JSON_OUT=0
ROOTS=()
BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|--dry-run) MODE="check"; shift ;;
    --apply) MODE="apply"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --source) SOURCE="${2:?}"; shift 2 ;;
    --source=*) SOURCE="${1#*=}"; shift ;;
    --root) ROOTS+=("${2:?}"); shift 2 ;;
    --root=*) ROOTS+=("${1#*=}"); shift ;;
    *) shift ;;
  esac
done

if [[ "${#ROOTS[@]}" -eq 0 ]]; then
  ROOTS=(/Users/josh/Developer)
fi

python3 - "$MODE" "$JSON_OUT" "$SOURCE" "$BEGIN" "$END" "${ROOTS[@]}" <<'PY'
import hashlib
import json
import os
import re
import sys
from pathlib import Path

mode = sys.argv[1]
json_out = sys.argv[2] == "1"
source = Path(sys.argv[3]).expanduser().resolve()
begin = sys.argv[4]
end = sys.argv[5]
roots = [Path(p).expanduser() for p in sys.argv[6:]]

source_text = source.read_text(encoding="utf-8")
source_hash = hashlib.sha256(source_text.encode()).hexdigest()
source_block_text = source_text.rstrip()
source_block_hash = hashlib.sha256(source_block_text.encode()).hexdigest()
source_repo = source.parent.resolve()
rule_re = re.compile(r"^## (L[0-9]+)[\s-].*$", re.M)
source_rules = sorted(set(rule_re.findall(source_text)))

def sha_text(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()

def file_hash(path: Path) -> str:
    if not path.exists():
        return ""
    return hashlib.sha256(path.read_bytes()).hexdigest()

def extract_block(text: str):
    if begin not in text or end not in text:
        return None
    after = text.split(begin, 1)[1]
    block = after.split(end, 1)[0]
    if block.startswith("\n"):
        block = block[1:]
    if block.endswith("\n"):
        block = block[:-1]
    return block

def render_with_block(existing: str) -> str:
    block = f"{begin}\n{source_text.rstrip()}\n{end}"
    if begin in existing and end in existing.split(begin, 1)[1]:
        prefix = existing.split(begin, 1)[0].rstrip()
        suffix = existing.split(end, 1)[1].lstrip("\n")
        return f"{prefix}\n\n{block}\n" + (suffix if suffix else "")
    prefix = existing.rstrip()
    return f"{prefix}\n\n{block}\n" if prefix else f"{block}\n"

targets = []
for root in roots:
    if root.is_file():
        candidates = [root]
    elif (root / ".flywheel" / "AGENTS-CANONICAL.md").is_file():
        candidates = [root / ".flywheel" / "AGENTS-CANONICAL.md"]
    else:
        candidates = sorted(root.glob("**/.flywheel/AGENTS-CANONICAL.md"))
    for candidate in candidates:
        try:
            resolved = candidate.resolve()
        except OSError:
            continue
        if resolved.is_file() and resolved not in targets:
            targets.append(resolved)

details = []
root_details = []
writes = []
errors = []
canonical_drifted = 0
canonical_synced = 0
root_drifted = 0
root_synced = 0
repos = []

for target in targets:
    repo = target.parent.parent.resolve()
    repos.append(str(repo))
    target_hash = file_hash(target)
    if target_hash == source_hash:
        details.append({"repo": str(repo), "target": str(target), "status": "in_sync", "hash": target_hash})
    else:
        canonical_drifted += 1
        if mode == "apply":
            try:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(source_text, encoding="utf-8")
                new_hash = file_hash(target)
                if new_hash == source_hash:
                    canonical_synced += 1
                    details.append({"repo": str(repo), "target": str(target), "status": "synced", "prior_hash": target_hash, "new_hash": new_hash})
                    writes.append({"path": str(target), "action": "copy_canonical_snapshot"})
                else:
                    errors.append({"repo": str(repo), "target": str(target), "status": "error", "code": "canonical_hash_mismatch"})
            except Exception as exc:
                errors.append({"repo": str(repo), "target": str(target), "status": "error", "code": "canonical_write_failed", "message": str(exc)})
        else:
            details.append({"repo": str(repo), "target": str(target), "status": "drifted", "hash": target_hash})

    root_agents = repo / "AGENTS.md"
    if repo == source_repo:
        root_details.append({"repo": str(repo), "target": str(root_agents), "status": "source_root", "drift": False, "block_present": False, "missing_rules": [], "reason": "canonical source repo root is the source AGENTS.md"})
        continue
    existing = root_agents.read_text(encoding="utf-8") if root_agents.exists() else ""
    block = extract_block(existing)
    block_present = block is not None
    target_rules = sorted(set(rule_re.findall(block or "")))
    missing_rules = [rule for rule in source_rules if rule not in target_rules]
    block_hash = sha_text(block or "")
    if block_present and block_hash == source_block_hash:
        root_details.append({"repo": str(repo), "target": str(root_agents), "status": "in_sync", "drift": False, "block_present": True, "block_hash": block_hash, "missing_rules": missing_rules})
        continue
    root_drifted += 1
    if mode == "apply":
        try:
            rendered = render_with_block(existing)
            root_agents.write_text(rendered, encoding="utf-8")
            new_block = extract_block(rendered)
            if new_block is not None and sha_text(new_block) == source_block_hash:
                root_synced += 1
                root_details.append({"repo": str(repo), "target": str(root_agents), "status": "synced", "drift": False, "block_present": True, "prior_block_hash": block_hash, "new_block_hash": source_block_hash, "prior_missing_rules": missing_rules})
                writes.append({"path": str(root_agents), "action": "replace_root_agents_canonical_block"})
            else:
                errors.append({"repo": str(repo), "target": str(root_agents), "status": "error", "code": "root_block_post_write_mismatch"})
        except Exception as exc:
            errors.append({"repo": str(repo), "target": str(root_agents), "status": "error", "code": "root_write_failed", "message": str(exc)})
    else:
        root_details.append({"repo": str(repo), "target": str(root_agents), "status": "drifted", "drift": True, "block_present": block_present, "block_hash": block_hash, "missing_rules": missing_rules})

errors_count = len(errors)
drifted_count = canonical_drifted + root_drifted
synced_count = canonical_synced + root_synced
status = "error" if errors_count else ("drift_detected" if mode == "check" and drifted_count else "ok")
payload = {
    "mode": mode,
    "status": status,
    "source": str(source),
    "source_hash": source_hash,
    "target_count": len(targets),
    "drifted_count": drifted_count,
    "synced_count": synced_count,
    "canonical_drifted_count": canonical_drifted,
    "canonical_synced_count": canonical_synced,
    "root_target_count": len(set(repos)),
    "root_drifted_count": root_drifted,
    "root_synced_count": root_synced,
    "errors_count": errors_count,
    "details": details,
    "root_details": root_details,
    "writes": writes,
    "errors": errors,
}
print(json.dumps(payload, sort_keys=True))
if errors_count:
    sys.exit(2)
if mode == "check" and drifted_count:
    sys.exit(1)
PY
