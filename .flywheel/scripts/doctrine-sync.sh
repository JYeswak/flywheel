#!/usr/bin/env bash
set -euo pipefail

FLYWHEEL_ROOT="${FLYWHEEL_ROOT:-/Users/josh/Developer/flywheel}"
CANONICAL_SOURCE="${FLYWHEEL_DOCTRINE_CANONICAL_SOURCE:-$FLYWHEEL_ROOT/templates/flywheel-install/AGENTS.md}"
TARGET_REPO="${TARGET_REPO:-$PWD}"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY=""
L_RULES=""

usage() {
  cat <<'USAGE'
usage: doctrine-sync.sh --target-repo PATH [--dry-run|--apply] [--idempotency-key KEY] [--l-rules L29,L35] [--json]

Diffs one flywheel-installed repo against the canonical flywheel AGENTS template.
Default is dry-run. Apply mode appends missing L-rules only and stamps
.flywheel/STATE.json with the current doctrine_version.

Safety:
  - refuses targets without .flywheel/
  - --apply requires --idempotency-key
  - --l-rules limits append/apply to reviewed L-rule ids for wave applies
  - never rewrites existing L-rules
  - one target repo per run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-repo|--repo)
      [[ -n "${2:-}" ]] || { echo "ERR: $1 requires PATH" >&2; exit 2; }
      TARGET_REPO="$2"; shift 2 ;;
    --source)
      [[ -n "${2:-}" ]] || { echo "ERR: --source requires PATH" >&2; exit 2; }
      CANONICAL_SOURCE="$2"; shift 2 ;;
    --dry-run)
      APPLY=0; shift ;;
    --apply)
      APPLY=1; shift ;;
    --idempotency-key)
      [[ -n "${2:-}" ]] || { echo "ERR: --idempotency-key requires KEY" >&2; exit 2; }
      IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --l-rules|--rules)
      [[ -n "${2:-}" ]] || { echo "ERR: $1 requires comma-separated L-rule ids" >&2; exit 2; }
      L_RULES="$2"; shift 2 ;;
    --json)
      JSON_OUT=1; shift ;;
    --version-stamp|--print-version)
      python3 - "$CANONICAL_SOURCE" "$FLYWHEEL_ROOT" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

source = Path(sys.argv[1]).expanduser()
root = Path(sys.argv[2]).expanduser()
text = source.read_text(encoding="utf-8")
rules = []
for match in re.finditer(r"(?m)^## (L(\d+))\b.*$", text):
    start = match.start()
    nxt = re.search(r"(?m)^## L\d+\b.*$", text[match.end():])
    end = match.end() + nxt.start() if nxt else len(text)
    body = text[start:end]
    shipped = re.search(r"(?m)^shipped:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", body)
    rules.append((int(match.group(2)), match.group(1), shipped.group(1) if shipped else "unknown"))
highest = max(rules, default=(0, "L0", "unknown"))
try:
    sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], text=True).strip()
except Exception:
    sha = "unknown"
print(json.dumps({"doctrine_version": f"{highest[2]}.{highest[1]}", "highest_l_rule": highest[1], "shipped": highest[2], "canonical_source": str(source), "canonical_sha": sha}, sort_keys=True))
PY
      exit 0 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  echo "ERR: --apply requires --idempotency-key" >&2
  exit 3
fi

if [[ ! -f "$CANONICAL_SOURCE" ]]; then
  echo "ERR: canonical source not found: $CANONICAL_SOURCE" >&2
  exit 2
fi

if ! TARGET_ABS="$(cd "$TARGET_REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: target repo not found: $TARGET_REPO" >&2
  exit 2
fi

if [[ ! -d "$TARGET_ABS/.flywheel" ]]; then
  echo "ERR: target repo is not flywheel-initialized: $TARGET_ABS" >&2
  exit 2
fi

python3 - "$FLYWHEEL_ROOT" "$CANONICAL_SOURCE" "$TARGET_ABS" "$APPLY" "$IDEMPOTENCY_KEY" "$JSON_OUT" "$L_RULES" <<'PY'
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1]).expanduser()
canonical_source = Path(sys.argv[2]).expanduser()
target = Path(sys.argv[3]).expanduser()
apply = sys.argv[4] == "1"
key = sys.argv[5]
json_out = sys.argv[6] == "1"
allowlist_raw = sys.argv[7].strip()

def utc_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def git_sha():
    try:
        return subprocess.check_output(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"

def parse_rules(path):
    if not path.exists():
        return {}, ""
    text = path.read_text(encoding="utf-8", errors="ignore")
    matches = list(re.finditer(r"(?m)^## (L(\d+))\b.*$", text))
    rules = {}
    for idx, match in enumerate(matches):
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[match.start():end].rstrip() + "\n"
        heading = match.group(0)
        shipped = re.search(r"(?m)^shipped:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", body)
        rules[match.group(1)] = {
            "id": match.group(1),
            "number": int(match.group(2)),
            "heading": heading,
            "title": re.sub(r"^##\s+", "", heading),
            "shipped": shipped.group(1) if shipped else None,
            "body": body,
        }
    return rules, text

canonical_rules, _ = parse_rules(canonical_source)
if not canonical_rules:
    raise SystemExit("ERR: canonical source has no L-rule headings")

errors = []
requested_l_rules = []
if allowlist_raw:
    seen = set()
    for token in re.split(r"[,\s]+", allowlist_raw):
        if not token:
            continue
        match = re.fullmatch(r"[Ll](\d+)", token.strip())
        if not match:
            errors.append(f"invalid_l_rule_id:{token}")
            continue
        rid = f"L{int(match.group(1))}"
        if rid not in seen:
            requested_l_rules.append(rid)
            seen.add(rid)
    if not requested_l_rules:
        errors.append("l_rules_allowlist_empty")
    for rid in requested_l_rules:
        if rid not in canonical_rules:
            errors.append(f"l_rule_not_in_canonical:{rid}")

allowed_rule_ids = {rid for rid in requested_l_rules if rid in canonical_rules} if requested_l_rules else set(canonical_rules)

highest = max(canonical_rules.values(), key=lambda row: row["number"])
version_date = highest["shipped"] or datetime.now(timezone.utc).strftime("%Y-%m-%d")
doctrine_version = f"{version_date}.{highest['id']}"
sha = git_sha()
ts = utc_now()
provenance = f"# Pulled from flywheel/templates/flywheel-install/AGENTS.md@{sha}"

surfaces = [
    ("agents_md", target / "AGENTS.md"),
    ("agents_canonical", target / ".flywheel" / "AGENTS-CANONICAL.md"),
]

surface_rows = {}
union_missing = set()
union_missing_all = set()
union_unselected_missing = set()
for name, path in surfaces:
    rules, _ = parse_rules(path)
    missing_all = sorted(set(canonical_rules) - set(rules), key=lambda rid: canonical_rules[rid]["number"])
    missing = sorted(set(allowed_rule_ids) - set(rules), key=lambda rid: canonical_rules[rid]["number"])
    unselected_missing = sorted(set(missing_all) - set(missing), key=lambda rid: canonical_rules[rid]["number"])
    union_missing.update(missing)
    union_missing_all.update(missing_all)
    union_unselected_missing.update(unselected_missing)
    surface_rows[name] = {
        "path": str(path),
        "exists": path.exists(),
        "l_rule_count": len(rules),
        "missing_count": len(missing),
        "missing_l_rules": missing,
        "missing_l_rules_all_count": len(missing_all),
        "missing_l_rules_all": missing_all,
        "unselected_missing_l_rules": unselected_missing,
        "will_append": bool(apply and path.exists() and missing),
    }

state_path = target / ".flywheel" / "STATE.json"
state_exists = state_path.exists()
current_doctrine_version = None
state_error = None
state_payload = {}
if state_exists:
    try:
        state_payload = json.loads(state_path.read_text(encoding="utf-8"))
        if not isinstance(state_payload, dict):
            state_error = "state_json_not_object"
            state_payload = {}
        else:
            current_doctrine_version = state_payload.get("doctrine_version")
    except Exception as exc:
        state_error = f"state_json_parse_failed:{exc}"

receipt_dir = target / ".flywheel" / "receipts" / "doctrine-sync"
receipt_path = receipt_dir / f"{key}.json" if key else None

if apply:
    if receipt_path and receipt_path.exists():
        errors.append(f"idempotency_key_replay:{receipt_path}")
    for name, row in surface_rows.items():
        if not row["exists"]:
            errors.append(f"surface_missing:{name}:{row['path']}")
    if state_error:
        errors.append(state_error)

appended = {}
state_updated = False
state_should_update = current_doctrine_version != doctrine_version and (
    not requested_l_rules or not union_unselected_missing
)
if apply and not errors:
    for name, path in surfaces:
        missing = surface_rows[name]["missing_l_rules"]
        appended[name] = len(missing)
        if not missing:
            continue
        with path.open("a", encoding="utf-8") as fh:
            fh.write("\n\n")
            for rid in missing:
                fh.write(canonical_rules[rid]["body"].rstrip())
                fh.write("\n\n")
            fh.write(provenance)
            fh.write("\n")
    receipt_dir.mkdir(parents=True, exist_ok=True)
    if state_should_update:
        state_payload["doctrine_version"] = doctrine_version
        state_payload["doctrine_version_source"] = "flywheel/templates/flywheel-install/AGENTS.md"
        state_payload["doctrine_version_sha"] = sha
        state_payload["doctrine_version_updated_at"] = ts
        tmp_state = state_path.with_suffix(state_path.suffix + ".tmp")
        tmp_state.write_text(json.dumps(state_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        tmp_state.replace(state_path)
        state_updated = True

missing_bodies = [
    {
        "id": rid,
        "heading": canonical_rules[rid]["heading"],
        "body": canonical_rules[rid]["body"],
    }
    for rid in sorted(union_missing, key=lambda rid: canonical_rules[rid]["number"])
]

status = "ERROR" if errors else (
    "APPLIED" if apply and (union_missing or state_should_update)
    else ("DRIFT" if union_missing or (not requested_l_rules and current_doctrine_version != doctrine_version) else "CURRENT")
)
payload = {
    "schema_version": "flywheel.doctrine_sync.v1",
    "generated_at": ts,
    "mode": "apply" if apply else "dry-run",
    "apply": apply,
    "target_repo": str(target),
    "canonical_source": str(canonical_source),
    "canonical_sha": sha,
    "highest_l_rule": highest["id"],
    "proposed_doctrine_version": doctrine_version,
    "current_doctrine_version": current_doctrine_version,
    "status": status,
    "soft_violation": (
        "doctrine_behind_canonical_outside_allowlist" if requested_l_rules and union_unselected_missing
        else ("doctrine_behind_canonical" if current_doctrine_version != doctrine_version else None)
    ),
    "l_rules_allowlist": requested_l_rules,
    "l_rules_allowlist_active": bool(requested_l_rules),
    "surfaces": surface_rows,
    "missing_l_rules": sorted(union_missing, key=lambda rid: canonical_rules[rid]["number"]),
    "missing_l_rules_count": len(union_missing),
    "missing_l_rules_all": sorted(union_missing_all, key=lambda rid: canonical_rules[rid]["number"]),
    "missing_l_rules_all_count": len(union_missing_all),
    "unselected_missing_l_rules": sorted(union_unselected_missing, key=lambda rid: canonical_rules[rid]["number"]),
    "unselected_missing_l_rules_count": len(union_unselected_missing),
    "missing_l_rule_bodies": missing_bodies,
    "state_json": {
        "path": str(state_path),
        "exists": state_exists,
        "current_doctrine_version": current_doctrine_version,
        "proposed_doctrine_version": doctrine_version,
        "will_update": bool(apply and state_should_update),
        "updated": state_updated,
        "error": state_error,
    },
    "provenance_footer": provenance,
    "receipt_path": str(receipt_path) if receipt_path else None,
    "errors": errors,
    "appended": appended,
}

if apply and not errors and receipt_path:
    receipt_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    scope = ",".join(requested_l_rules) if requested_l_rules else "all"
    print(f"doctrine-sync target={target} status={status} scope={scope} missing_l_rules={len(union_missing)} current={current_doctrine_version or 'null'} proposed={doctrine_version}")
    if union_missing:
        print("missing: " + ",".join(payload["missing_l_rules"]))
    if not apply:
        print("dry-run; pass --apply --idempotency-key <key> to append missing rules and stamp STATE.json")

if errors:
    raise SystemExit(4)
PY
