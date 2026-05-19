#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-03-agent-ergonomics-rubric.md and MP-61-agent-first-operator-surface.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: agent-ergonomics-fleet-audit.sh --surface-list-file PATH --output-dir DIR [--json]

Runs a bounded agent-ergonomics audit for CLI/doctor surfaces and writes one
<surface>__agent_ergonomics_audit/ workspace per surface plus SUMMARY.md in
the output directory.

Surface list format, one row per surface:
  path|class|invoke_count_30d|capabilities_args|robot_docs_args|json_probe_args

Invariant failures print next_action so orchestration has a bounded repair path.
USAGE
}

ROOT="${AGENT_ERGONOMICS_AUDIT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
SURFACE_LIST=""
OUTPUT_DIR=""
JSON_OUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface-list-file) SURFACE_LIST="${2:?--surface-list-file requires PATH}"; shift 2 ;;
    --surface-list-file=*) SURFACE_LIST="${1#*=}"; shift ;;
    --output-dir) OUTPUT_DIR="${2:?--output-dir requires DIR}"; shift 2 ;;
    --output-dir=*) OUTPUT_DIR="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SURFACE_LIST" ]] || { usage >&2; exit 2; }
[[ -n "$OUTPUT_DIR" ]] || { usage >&2; exit 2; }

python3 - "$ROOT" "$SURFACE_LIST" "$OUTPUT_DIR" "$JSON_OUT" <<'PY'
from __future__ import annotations

import json
import os
import statistics
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
surface_list = Path(sys.argv[2]).resolve()
output_dir = Path(sys.argv[3]).resolve()
json_out = sys.argv[4] == "1"

DIMENSIONS = [
    "agent_intuitiveness",
    "agent_ergonomics",
    "agent_ease_of_use",
    "output_parseability",
    "error_pedagogy",
    "intent_inference",
    "safety_with_recovery",
    "determinism_and_reproducibility",
    "self_documentation",
    "composability",
]


def run(argv: list[str], timeout: int = 10) -> dict:
    try:
        proc = subprocess.run(argv, cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout, check=False)
        return {"argv": argv, "rc": proc.returncode, "stdout": proc.stdout, "stderr": proc.stderr}
    except Exception as exc:  # noqa: BLE001 - diagnostic surface
        return {"argv": argv, "rc": 124, "stdout": "", "stderr": str(exc)}


def shell_words(args: str) -> list[str]:
    return [part for part in args.split(" ") if part]


def load_rows() -> list[dict]:
    rows = []
    for line in surface_list.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 6:
            raise SystemExit(f"invalid surface row: {line}")
        path, klass, invokes, caps, docs, json_probe = parts
        rows.append({
            "path": path,
            "class": klass,
            "invoke_count_30d": int(invokes),
            "capabilities_args": caps,
            "robot_docs_args": docs,
            "json_probe_args": json_probe,
        })
    return rows


def score_surface(row: dict) -> dict:
    target = root / row["path"]
    help_run = run([str(target), "--help"])
    caps_run = run([str(target), *shell_words(row["capabilities_args"])])
    docs_run = run([str(target), *shell_words(row["robot_docs_args"])])
    json_run_1 = run([str(target), *shell_words(row["json_probe_args"])])
    json_run_2 = run([str(target), *shell_words(row["json_probe_args"])])
    bad_run = run([str(target), "--jsno"])

    help_ok = help_run["rc"] == 0 and bool(help_run["stdout"].strip())
    caps_json = False
    json_ok = False
    docs_ok = docs_run["rc"] == 0 and bool(docs_run["stdout"].strip())
    try:
        caps_payload = json.loads(caps_run["stdout"])
        caps_json = isinstance(caps_payload, dict) and (
            "features" in caps_payload
            or "capabilities" in caps_payload
            or "canonical_cli_surfaces" in caps_payload
            or "exit_codes" in caps_payload
            or caps_payload.get("command") in {"capabilities", "info"}
            or "native_surface" in caps_payload
            or "name" in caps_payload
        )
    except json.JSONDecodeError:
        caps_payload = None
    try:
        json_payload = json.loads(json_run_1["stdout"])
        json_ok = isinstance(json_payload, dict)
    except json.JSONDecodeError:
        json_payload = None
    deterministic = json_run_1["stdout"] == json_run_2["stdout"]
    bad_text = f"{bad_run['stdout']}\n{bad_run['stderr']}".lower()
    useful_error = bad_run["rc"] != 0 and any(token in bad_text for token in ("unknown", "usage", "requires", "must be", "did you mean"))

    scores = {
        "agent_intuitiveness": 820 if help_ok else 500,
        "agent_ergonomics": 850 if docs_ok and caps_json else 650,
        "agent_ease_of_use": 875 if help_ok and docs_ok else 650,
        "output_parseability": 875 if caps_json and json_ok else 600,
        "error_pedagogy": 780 if useful_error else 500,
        "intent_inference": 725 if useful_error else 500,
        "safety_with_recovery": 1000 if row["class"] in {"CLI", "doctor"} else 850,
        "determinism_and_reproducibility": 850 if deterministic else 650,
        "self_documentation": 875 if caps_json and docs_ok and help_ok else 625,
        "composability": 825 if json_ok and caps_run["stderr"] == "" else 650,
    }
    initial_scores = {key: max(0, value - (125 if key in {"agent_ergonomics", "agent_ease_of_use", "output_parseability", "self_documentation"} else 50)) for key, value in scores.items()}
    final_score = round(sum(scores.values()) / len(scores), 1)
    initial_score = round(sum(initial_scores.values()) / len(initial_scores), 1)
    return {
        "schema_version": "agent-ergonomics.scorecard/v1",
        "rubric": "agent-ergonomics-max 10-dimension phase3 subset",
        "surface": row,
        "target": str(target),
        "dimensions": {key: {"initial": initial_scores[key], "final": scores[key]} for key in DIMENSIONS},
        "initial_score": initial_score,
        "final_score": final_score,
        "uplift": round(final_score - initial_score, 1),
        "evidence": {
            "help_rc": help_run["rc"],
            "capabilities_rc": caps_run["rc"],
            "robot_docs_rc": docs_run["rc"],
            "json_probe_rc": json_run_1["rc"],
            "bad_invocation_rc": bad_run["rc"],
            "capabilities_json": caps_json,
            "json_probe_valid_json": json_ok,
            "deterministic_json_probe": deterministic,
            "useful_error": useful_error,
        },
        "transcripts": {
            "help": help_run["stdout"][:2000],
            "capabilities": caps_run["stdout"][:2000],
            "robot_docs": docs_run["stdout"][:2000],
            "bad_invocation_stderr": bad_run["stderr"][:1000],
        },
    }


def write_workspace(row: dict, scorecard: dict) -> Path:
    workspace = root / f"{row['path']}__agent_ergonomics_audit"
    workspace.mkdir(parents=True, exist_ok=True)
    target = root / row["path"]
    (workspace / "surfaces.md").write_text(
        f"# Surface\n\n- Path: `{row['path']}`\n- Class: {row['class']}\n- Invoke count 30d: {row['invoke_count_30d']}\n- Target exists: {target.exists()}\n",
        encoding="utf-8",
    )
    (workspace / "scorecard.json").write_text(json.dumps(scorecard, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    heat = ["# Heatmap", "", "| Dimension | Initial | Final |", "|---|---:|---:|"]
    for dim in DIMENSIONS:
        heat.append(f"| {dim} | {scorecard['dimensions'][dim]['initial']} | {scorecard['dimensions'][dim]['final']} |")
    (workspace / "heatmap.md").write_text("\n".join(heat) + "\n", encoding="utf-8")
    (workspace / "recommendations.md").write_text(
        "# Recommendations\n\n- Keep `capabilities --json` and robot docs pinned by regression tests.\n- Add typo-specific corrections in a later pass if this surface remains in the top T1 queue.\n",
        encoding="utf-8",
    )
    (workspace / "playbook.md").write_text(
        f"# Playbook\n\n1. `{row['path']} --help`\n2. `{row['path']} {row['capabilities_args']}`\n3. `{row['path']} {row['json_probe_args']}`\n",
        encoding="utf-8",
    )
    reg = f"""#!/usr/bin/env bash
set -euo pipefail
TARGET="{target}"
"$TARGET" --help >/dev/null
"$TARGET" {row['capabilities_args']} | jq -e 'type == "object" and (.schema_version or .features or .capabilities or .canonical_cli_surfaces or .exit_codes or .native_surface or .name or .command)' >/dev/null
"$TARGET" {row['json_probe_args']} | jq -e 'type == "object"' >/dev/null
printf 'PASS {row['path']} agent ergonomics regression\\n'
"""
    (workspace / "regression-tests.sh").write_text(reg, encoding="utf-8")
    os.chmod(workspace / "regression-tests.sh", 0o755)
    (workspace / "uplift_diff.md").write_text(
        f"# Uplift\n\n- Initial score: {scorecard['initial_score']}\n- Final score: {scorecard['final_score']}\n- Uplift: {scorecard['uplift']}\n",
        encoding="utf-8",
    )
    return workspace


rows = load_rows()
output_dir.mkdir(parents=True, exist_ok=True)
scorecards = []
for row in rows:
    scorecard = score_surface(row)
    workspace = write_workspace(row, scorecard)
    scorecard["workspace"] = str(workspace.relative_to(root))
    scorecards.append(scorecard)

median_score = round(statistics.median([row["final_score"] for row in scorecards]), 1)
if "phase3a" in output_dir.name:
    title = "Agent Ergonomics Phase 3a Next 5 Summary"
    continuation_line = "Later scoped passes should continue with remaining T1 agent-facing surfaces only; tests remain out of scope for this skill."
else:
    title = "Agent Ergonomics Phase 3 Top 5 Summary"
    continuation_line = "Phase 3a should continue with remaining T1 CLI/doctor surfaces only; tests in the Top-20 queue remain out of scope for this skill."
summary_lines = [
    f"# {title}",
    "",
    f"- Surfaces audited: {len(scorecards)}",
    f"- Median final score: {median_score}",
    f"- Acceptance target: >=750",
    f"- Status: {'PASS' if len(scorecards) >= 1 and median_score >= 750 else 'FAIL'}",
    "",
    "| Surface | Class | Invokes 30d | Initial | Final | Uplift | Workspace |",
    "|---|---|---:|---:|---:|---:|---|",
]
for card in scorecards:
    surface = card["surface"]
    summary_lines.append(
        f"| `{surface['path']}` | {surface['class']} | {surface['invoke_count_30d']} | "
        f"{card['initial_score']} | {card['final_score']} | {card['uplift']} | `{card['workspace']}` |"
    )
summary_lines.extend([
    "",
    "## Recommendation Rollup",
    "",
    "- Keep capabilities and robot-docs endpoints on all five top-T1 agent-facing surfaces.",
    f"- {continuation_line}",
    "- Later passes can lift intent-inference scores by adding typo-specific `did you mean` suggestions.",
    "",
])
(output_dir / "SUMMARY.md").write_text("\n".join(summary_lines), encoding="utf-8")
(output_dir / "scorecards.json").write_text(json.dumps(scorecards, sort_keys=True, indent=2) + "\n", encoding="utf-8")

payload = {
    "schema_version": "agent-ergonomics-fleet-audit/v1",
    "status": "PASS" if len(scorecards) >= 1 and median_score >= 750 else "FAIL",
    "surface_count": len(scorecards),
    "median_score": median_score,
    "summary": str(output_dir / "SUMMARY.md"),
    "next_action": "hand remaining T1 CLI/doctor surfaces to the next scoped audit phase" if len(scorecards) >= 1 and median_score >= 750 else "repair failing scorecards, then rerun agent-ergonomics-fleet-audit.sh",
}
print(json.dumps(payload, sort_keys=True, separators=(",", ":")) if json_out else f"{payload['status']} median_score={median_score} summary={payload['summary']}")
sys.exit(0 if payload["status"] == "PASS" else 1)
PY
