#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
LEDGER_DEFAULT="$HOME/.local/state/flywheel/three-judges-publishability-validator-ledger.jsonl"
OPENER_DEFAULT="$SCRIPT_DIR/three-judges-rework-bead-opener.sh"
VERSION="three-judges-publishability-validator.v1.0.0"

usage() {
  cat <<'EOF'
usage:
  three-judges-publishability-validator.sh check --repo PATH --bead-id ID [--mode strict|advisory] [--json]
  three-judges-publishability-validator.sh --info|--help|--examples

Scores the seven-facet publishability bar and emits a close-time decision.
Advisory mode records REFUSE without blocking. Strict mode blocks REFUSE.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/three-judges-publishability-validator.sh check --repo . --bead-id flywheel-demo --json
  .flywheel/scripts/three-judges-publishability-validator.sh check --repo /tmp/repo --bead-id flywheel-demo --mode strict --json
  THREE_JUDGES_PUBLISHABILITY_LEDGER=/tmp/three-judges.jsonl .flywheel/scripts/three-judges-publishability-validator.sh check --repo . --bead-id flywheel-demo --json
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg ledger "${THREE_JUDGES_PUBLISHABILITY_LEDGER:-$LEDGER_DEFAULT}" \
    --arg opener "${THREE_JUDGES_REWORK_OPENER:-$OPENER_DEFAULT}" \
    '{name:"three-judges-publishability-validator.sh",version:$version,
      schema_version:"three-judges-publishability/v1",ledger_path:$ledger,
      rework_bead_opener:$opener,default_mode:"advisory",
      exits:{"0":"PASS/WARN or advisory REFUSE","1":"strict REFUSE","2":"usage error"}}'
}

case "${1:-}" in
  --help|-h|help|"") usage; exit 0 ;;
  --examples|examples) examples; exit 0 ;;
  --info|info) info; exit 0 ;;
esac

: "${THREE_JUDGES_REWORK_OPENER:=$OPENER_DEFAULT}"
: "${THREE_JUDGES_PUBLISHABILITY_LEDGER:=$LEDGER_DEFAULT}"
export THREE_JUDGES_REWORK_OPENER THREE_JUDGES_PUBLISHABILITY_LEDGER

python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

FACETS = [
    ("F1", "README front-door"),
    ("F2", "Doctrine clarity"),
    ("F3", "Doctor/health/repair triad"),
    ("F4", "Executable tests"),
    ("F5", "Idempotent install + uninstall"),
    ("F6", "Code aesthetic"),
    ("F7", "Demo-ability"),
]
VERSION = "three-judges-publishability-validator.v1.0.0"


def iso_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def usage_error(message):
    print(f"ERR: {message}", file=sys.stderr)
    return 2


def mode_for(repo, explicit):
    if explicit:
        return explicit
    mode_file = Path(repo) / ".flywheel/three-judges-mode"
    if mode_file.exists():
        raw = mode_file.read_text(encoding="utf-8", errors="replace").strip()
        if raw in {"strict", "advisory"}:
            return raw
    return "advisory"


def score_for_verdict(verdict):
    raw = str(verdict or "").strip()
    numeric = re.search(r"\b([0-9](?:\.[0-9]+)?|10(?:\.0+)?)\b", raw)
    if numeric:
        value = float(numeric.group(1))
        return max(0.0, min(10.0, value))
    upper = raw.upper()
    if upper in {"YES", "PASS", "PASSED", "TRUE"}:
        return 9.0
    if upper in {"WARN", "PARTIAL", "MIXED"}:
        return 7.0
    if upper in {"NO", "FAIL", "FAILED", "FALSE"}:
        return 4.0
    return 5.0


def parse_audit(repo):
    audit = Path(repo) / ".flywheel/PUBLISHABILITY-AUDIT.md"
    text = read_text(audit)
    if not text:
        return None
    rows = {}
    for line in text.splitlines():
        parts = [part.strip() for part in line.strip().strip("|").split("|")]
        if len(parts) < 4 or not re.fullmatch(r"F[1-7]", parts[0] or ""):
            continue
        facet_id, facet, verdict = parts[:3]
        evidence = parts[3] if len(parts) > 3 else ""
        rows[facet_id] = {
            "facet_id": facet_id,
            "facet": facet or dict(FACETS).get(facet_id, facet_id),
            "verdict": verdict,
            "score": score_for_verdict(verdict),
            "evidence": evidence,
            "source": str(audit),
        }
    if not rows:
        return None
    return [rows.get(fid, missing_facet(repo, fid, name, "audit_missing_facet")) for fid, name in FACETS]


def has_any(root, rels):
    return any((Path(root) / rel).exists() for rel in rels)


def missing_facet(repo, facet_id, facet, reason):
    return {"facet_id": facet_id, "facet": facet, "verdict": "NO", "score": 4.0, "evidence": reason, "source": "heuristic"}


def heuristic_facets(repo):
    root = Path(repo)
    readme = read_text(root / "README.md")
    scripts = list((root / ".flywheel/scripts").glob("*.sh")) if (root / ".flywheel/scripts").exists() else []
    tests = list((root / "tests").glob("*.sh")) if (root / "tests").exists() else []
    tests += list((root / ".flywheel/tests").glob("*.sh")) if (root / ".flywheel/tests").exists() else []
    checks = [
        (bool(readme.strip()), "README.md present"),
        (has_any(root, ["AGENTS.md", "INCIDENTS.md", ".flywheel/MISSION.md"]), "doctrine files present"),
        (has_any(root, [".flywheel/scripts/publishability-bar.sh"]) or "doctor" in readme.lower(), "doctor signal visible"),
        (len(tests) > 0, "shell tests present"),
        (has_any(root, ["templates/flywheel-install", ".flywheel/loop.json"]), "install substrate present"),
        (len(scripts) > 0, "named flywheel scripts present"),
        (bool(re.search(r"(quick start|demo|example|try it|smoke)", readme, re.I)), "demo language present"),
    ]
    facets = []
    for (facet_id, facet), (ok, evidence) in zip(FACETS, checks):
        facets.append({
            "facet_id": facet_id,
            "facet": facet,
            "verdict": "YES" if ok else "NO",
            "score": 7.0 if ok else 4.0,
            "evidence": evidence,
            "source": "heuristic",
        })
    return facets


def repo_state(repo):
    root = Path(repo)
    status_lines = []
    try:
        proc = subprocess.run(["git", "-C", str(root), "status", "--short"], text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=5)
        status_lines = [line for line in proc.stdout.splitlines() if line.strip()]
    except Exception:
        pass
    manifests = [rel for rel in ("package.json", "pyproject.toml", "Cargo.toml", ".flywheel/loop.json") if (root / rel).exists()]
    return {
        "readme_present": (root / "README.md").exists(),
        "package_json_present": (root / "package.json").exists(),
        "publishability_audit_present": (root / ".flywheel/PUBLISHABILITY-AUDIT.md").exists(),
        "manifest_paths": manifests,
        "git_status_count": len(status_lines),
    }


def judge_verdicts(facets, brand_voice_score):
    scores = {f["facet_id"]: float(f["score"]) for f in facets}
    jeff = round((scores["F3"] + scores["F4"] + scores["F5"] + scores["F6"]) / 4, 2)
    donella = round((scores["F2"] + scores["F3"] + scores["F7"]) / 3, 2)
    joshua = round((scores["F1"] + scores["F6"] + scores["F7"] + brand_voice_score) / 4, 2)
    def verdict(score):
        if score >= 7:
            return "PASS"
        if score >= 5:
            return "WARN"
        return "FAIL"
    return {
        "Jeff": {"score": jeff, "verdict": verdict(jeff), "basis": ["F3", "F4", "F5", "F6"]},
        "Donella": {"score": donella, "verdict": verdict(donella), "basis": ["F2", "F3", "F7"]},
        "Joshua": {"score": joshua, "verdict": verdict(joshua), "basis": ["F1", "F6", "F7", "brand_voice"]},
    }


def brand_voice(repo):
    audit = Path(repo) / ".flywheel/PUBLISHABILITY-AUDIT.md"
    text = read_text(audit)
    public = re.search(r"^Public repo:\s*(yes|true|public)\s*$", text, re.I | re.M) is not None
    def field(name, default):
        pat = re.compile(rf"\|\s*{re.escape(name)}\s*\|\s*([^|]+?)\s*\|", re.I)
        m = pat.search(text)
        if not m:
            return default
        return m.group(1).strip()
    try:
        voice_score = float(field("ZestStream voice score", "100" if not public else "0"))
    except ValueError:
        voice_score = 100.0 if not public else 0.0
    try:
        banned = int(float(field("Banned words count", "0")))
        ungrounded = int(float(field("Ungrounded claims count", "0")))
    except ValueError:
        banned, ungrounded = 0, 0
    normalized = max(0.0, min(10.0, voice_score / 10.0))
    return {
        "public_repo": public,
        "public_voice_gate": field("Public voice gate", "EXEMPT_INTERNAL" if not public else "UNKNOWN"),
        "brand_voice_composite": voice_score,
        "brand_voice_score_0_10": normalized,
        "banned_words_count": banned,
        "ungrounded_claims_count": ungrounded,
        "scorecard_log": field("Scorecard log", ""),
    }


def append_ledger(path, payload):
    try:
        ledger = Path(path).expanduser()
        ledger.parent.mkdir(parents=True, exist_ok=True)
        with ledger.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")
        return True
    except Exception:
        return False


def open_rework_beads(repo, bead_id, facets, opener):
    rows = []
    if not opener or not Path(opener).exists():
        return [{"action": "skipped", "reason": "opener_missing", "path": opener}]
    for facet in facets:
        cmd = [
            opener, "--repo", repo, "--parent-bead", bead_id,
            "--facet-id", facet["facet_id"], "--facet", facet["facet"],
            "--score", str(facet["score"]), "--reason", "publishability_refuse",
            "--json",
        ]
        try:
            proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
            if proc.stdout.strip():
                rows.append(json.loads(proc.stdout))
            else:
                rows.append({"action": "error", "facet_id": facet["facet_id"], "stderr": proc.stderr[:300], "rc": proc.returncode})
        except Exception as exc:
            rows.append({"action": "error", "facet_id": facet["facet_id"], "error": str(exc)[:300]})
    return rows


def main(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("command", nargs="?", default="check")
    parser.add_argument("--repo", default=os.environ.get("THREE_JUDGES_REPO", str(Path.cwd())))
    parser.add_argument("--bead-id", default=os.environ.get("THREE_JUDGES_BEAD_ID", "unknown"))
    parser.add_argument("--mode", choices=["strict", "advisory"], default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--help", "-h", action="store_true")
    args = parser.parse_args(argv)
    if args.help:
        return usage_error("use shell --help")
    if args.command != "check":
        return usage_error(f"unknown command: {args.command}")
    repo_path = Path(args.repo).expanduser()
    try:
        repo = str(repo_path.resolve())
    except Exception:
        repo = str(repo_path)
    mode = mode_for(repo, args.mode)
    facets = parse_audit(repo) or heuristic_facets(repo)
    voice = brand_voice(repo)
    composite = round(sum(float(f["score"]) for f in facets) / len(facets), 2)
    failed_facets = [f for f in facets if float(f["score"]) < 5.0]
    if composite < 7.0:
        decision = "REFUSE"
    elif failed_facets:
        decision = "WARN"
    else:
        decision = "PASS"
    opener = os.environ.get("THREE_JUDGES_REWORK_OPENER", str(Path(__file__).resolve().parent / "three-judges-rework-bead-opener.sh"))
    rework = open_rework_beads(repo, args.bead_id, failed_facets, opener) if decision == "REFUSE" else []
    exit_code = 1 if mode == "strict" and decision == "REFUSE" else 0
    payload = {
        "schema_version": "three-judges-publishability/v1",
        "validator_version": VERSION,
        "timestamp": iso_now(),
        "repo_path": repo,
        "bead_id": args.bead_id,
        "mode": mode,
        "decision": decision,
        "exit_code": exit_code,
        "close_allowed": exit_code == 0,
        "composite_score": composite,
        "min_facet_score": min(float(f["score"]) for f in facets),
        "per_facet_scores": facets,
        "failed_facets": failed_facets,
        "judge_verdicts": judge_verdicts(facets, voice["brand_voice_score_0_10"]),
        "brand_voice": voice,
        "repo_state": repo_state(repo),
        "thresholds": {"pass_composite_min": 7.0, "warn_when_any_facet_below": 5.0, "refuse_composite_below": 7.0},
        "rework_beads_filed": rework,
        "rubric_refs": {
            "publishability_bar": str(Path(repo) / ".flywheel/PUBLISHABILITY-BAR.md"),
            "three_judges_prompt": str(Path.home() / ".claude/skills/.flywheel/prompts/three-judges-rubric.md"),
        },
    }
    ledger = os.environ.get("THREE_JUDGES_PUBLISHABILITY_LEDGER", str(Path.home() / ".local/state/flywheel/three-judges-publishability-validator-ledger.jsonl"))
    payload["ledger_path"] = ledger
    payload["ledger_appended"] = append_ledger(ledger, payload)
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"decision={decision} composite={composite} mode={mode} close_allowed={str(exit_code == 0).lower()}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
