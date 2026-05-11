#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
#
# gap-hunt-probe-self-calibration.sh — read-only probe-of-the-probe.
#
# Surfaces structural drift signals in gap-hunt-probe.sh that would, if
# uncalibrated, manifest as per-bead FPs requiring per-bead worker
# triages. Designed to run periodically (per /flywheel:tick or via
# launchd cadence) and emit JSON proposals — orch reviews + dispatches
# calibration beads.
#
# Source: flywheel-faqj2 (N=7 calibration findings in 1 session 2026-05-11
# motivated meta-bead per pattern threshold formally noted in
# flywheel-2xdi.103 evidence).
#
# Anti-pattern guard: this probe is READ-ONLY. Proposals only. No
# auto-apply. Sister to Step 4o tick discipline.
#
# Five finding types:
#   1. corpus_cap_approaching — any corpus exceeds threshold of its cap
#   2. orphan_script_no_glob_coverage — *.sh files in canonical dirs
#      not matched by any gap-hunt-probe corpus glob
#   3. new_ledger_since_last_run — *.jsonl in STATE_DIR appearing since
#      last self-calibration snapshot
#   4. ledger_producer_name_mismatch — *-runs.jsonl ledgers where neither
#      basename nor stem nor producer-stem appears in receivers_text
#      (residual after flywheel-nq5ns producer-stem fallback)
#   5. large_skill_md_over_threshold — SKILL.md files exceeding 50% of
#      current skill_md_per_file_cap (256 KB post-zsk2d), signaling
#      drift toward needing another cap bump
#
# Canonical CLI:
#   gap-hunt-probe-self-calibration.sh --json               # emit findings
#   gap-hunt-probe-self-calibration.sh --info --json        # introspection
#   gap-hunt-probe-self-calibration.sh --schema --json      # output schema
#   gap-hunt-probe-self-calibration.sh --doctor --json      # health
#   gap-hunt-probe-self-calibration.sh --threshold 0.7      # cap-warn threshold (default 0.5)
#   gap-hunt-probe-self-calibration.sh --apply              # append findings to runs.jsonl

set -uo pipefail

VERSION="gap-hunt-probe-self-calibration.v1"
SCHEMA_VERSION="gap-hunt-probe-self-calibration/v1"
SOURCE_BEAD="flywheel-faqj2"

REPO_ROOT="${GAP_HUNT_SELF_CALIB_REPO_ROOT:-/Users/josh/Developer/flywheel}"
CLAUDE_ROOT="${GAP_HUNT_SELF_CALIB_CLAUDE_ROOT:-$HOME/.claude}"
STATE_DIR="${GAP_HUNT_SELF_CALIB_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${GAP_HUNT_SELF_CALIB_LEDGER:-$STATE_DIR/gap-hunt-self-calibration-runs.jsonl}"
PROBE="${GAP_HUNT_SELF_CALIB_PROBE:-$REPO_ROOT/.flywheel/scripts/gap-hunt-probe.sh}"
SNAPSHOT="${GAP_HUNT_SELF_CALIB_SNAPSHOT:-$STATE_DIR/gap-hunt-self-calibration-snapshot.json}"

MODE="json"
THRESHOLD="0.5"
APPLY=0

# --json is the canonical output format and the default; it doesn't change
# MODE. Other mode flags (--info / --schema / --doctor / --examples) set
# MODE exclusively. This avoids the bug where `--info --json` had --json
# override MODE back to json.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --examples) MODE="examples"; shift ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --threshold=*) THRESHOLD="${1#*=}"; shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    -h|--help)
      cat <<'USG'
usage: gap-hunt-probe-self-calibration.sh [SUBCOMMAND]

Read-only probe-of-the-probe. Surfaces drift signals in gap-hunt-probe.sh
that would manifest as per-bead FPs. Emits JSON proposals — read-only.

  --json                    emit findings as JSON (default)
  --info --json             surface metadata
  --schema --json           output schema
  --doctor --json           health check
  --examples --json         curated workflow examples
  --threshold FLOAT         cap-warn threshold (default 0.5; 0.7 = 70%)
  --apply                   append findings to runs.jsonl
  --dry-run                 default; do not append
  --help / -h               this help

Source: flywheel-faqj2 meta-bead. Sister: gap-hunt-probe.sh.
USG
      exit 0
      ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 64 ;;
  esac
done

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

case "$MODE" in
  info)
    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" --arg sb "$SOURCE_BEAD" \
      --arg pr "$PROBE" --arg sd "$STATE_DIR" --arg lg "$LEDGER" \
      '{schema_version:$sv,version:$v,source_bead:$sb,mode:"info",
        finding_types:["corpus_cap_approaching","orphan_script_no_glob_coverage","new_ledger_since_last_run","ledger_producer_name_mismatch","large_skill_md_over_threshold"],
        read_only:true,proposals_only:true,
        probe:$pr,state_dir:$sd,ledger:$lg,
        canonical_cli:{json:true,dry_run_apply:true,threshold_param:true}}'
    exit 0
    ;;
  schema)
    jq -nc --arg sv "$SCHEMA_VERSION" \
      '{schema_version:$sv,command:"schema",
        emits:{schema_version:"string",ts:"iso8601",threshold:"float",
               findings:"array<{finding_type,severity,details,proposal}>",
               summary:"object<{total_findings,by_type}>"},
        finding_types:["corpus_cap_approaching","orphan_script_no_glob_coverage","new_ledger_since_last_run","ledger_producer_name_mismatch","large_skill_md_over_threshold"],
        severity_levels:["info","warn","alert"]}'
    exit 0
    ;;
  doctor)
    issues=()
    [[ -x "$PROBE" ]] || issues+=("gap-hunt-probe missing or not executable: $PROBE")
    [[ -d "$STATE_DIR" ]] || issues+=("state dir missing: $STATE_DIR")
    if (( ${#issues[@]} == 0 )); then
      jq -nc --arg ts "$(now_iso)" --arg sv "$SCHEMA_VERSION" --arg pr "$PROBE" --arg sd "$STATE_DIR" \
        '{schema_version:$sv,command:"doctor",status:"pass",ts:$ts,checks:[
           {name:"probe_executable",status:"pass",path:$pr},
           {name:"state_dir_present",status:"pass",path:$sd}
         ]}'
    else
      printf '{"schema_version":"%s","command":"doctor","status":"warn","issues":[' "$SCHEMA_VERSION"
      for i in "${!issues[@]}"; do [[ "$i" -gt 0 ]] && printf ','; printf '"%s"' "${issues[$i]}"; done
      printf ']}\n'
    fi
    exit 0
    ;;
  examples)
    jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv,examples:[
      {name:"basic",invocation:"gap-hunt-probe-self-calibration.sh --json"},
      {name:"strict",invocation:"gap-hunt-probe-self-calibration.sh --threshold 0.7 --json"},
      {name:"apply-to-ledger",invocation:"gap-hunt-probe-self-calibration.sh --apply --json"}
    ]}'
    exit 0
    ;;
esac

# Default mode: run all 5 finding checks; emit JSON
python3 - "$VERSION" "$SCHEMA_VERSION" "$SOURCE_BEAD" "$REPO_ROOT" "$CLAUDE_ROOT" "$STATE_DIR" "$LEDGER" "$PROBE" "$SNAPSHOT" "$THRESHOLD" "$APPLY" <<'PY'
from __future__ import annotations
import json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path

(_, VERSION, SCHEMA_VERSION, SOURCE_BEAD, REPO_RAW, CLAUDE_RAW, STATE_RAW,
 LEDGER_RAW, PROBE_RAW, SNAPSHOT_RAW, THRESHOLD_RAW, APPLY_RAW) = sys.argv

REPO = Path(REPO_RAW)
CLAUDE = Path(CLAUDE_RAW)
STATE = Path(STATE_RAW)
LEDGER = Path(LEDGER_RAW)
PROBE = Path(PROBE_RAW)
SNAPSHOT = Path(SNAPSHOT_RAW)
THRESHOLD = float(THRESHOLD_RAW)
APPLY = APPLY_RAW == "1"

now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
findings: list[dict] = []


def read_text(path: Path, cap: int = 1_000_000) -> str:
    try:
        return path.read_text(errors="replace")[:cap]
    except Exception:
        return ""


def safe_iter(root: Path, pattern: str, limit: int = 1000) -> list[Path]:
    if not root.is_dir():
        return []
    try:
        return list(root.glob(pattern))[:limit]
    except Exception:
        return []


# --- Finding 1: corpus_cap_approaching -----------------------------------
# For each canonical receiver corpus in gap-hunt-probe, measure its current
# byte size against its declared cap. Warn if utilization >= THRESHOLD.

corpora_specs = [
    # (corpus_name, root_dir, glob_pattern, per_file_cap, overall_cap_or_None, max_files)
    ("doctrine_md", REPO / ".flywheel/doctrine", "*.md", 200_000, None, 200),
    ("rules_md", REPO / ".flywheel/rules", "*.md", 200_000, None, 500),
    ("slash_cmds_md", CLAUDE / "commands/flywheel", "*.md", 1_000_000, None, 200),
    ("skill_md_priority", CLAUDE / "skills", "SKILL.md", 256 * 1024, 32_000_000, 6000),
    ("flywheel_scripts", REPO / ".flywheel/scripts", "*.sh", 2_000_000, 3_000_000, 500),
    ("launchd_plists", Path.home() / "Library/LaunchAgents", "*.plist", 1_500_000, 1_500_000, 1000),
]

for name, root, pat, per_cap, overall_cap, max_files in corpora_specs:
    if not root.is_dir():
        continue
    total_bytes = 0
    file_count = 0
    try:
        for p in safe_iter(root, pat, max_files):
            try:
                s = p.stat().st_size
                total_bytes += min(s, per_cap)
                file_count += 1
            except Exception:
                continue
    except Exception:
        continue
    effective_cap = overall_cap if overall_cap else (per_cap * max_files)
    if effective_cap <= 0:
        continue
    util = total_bytes / effective_cap
    if util >= THRESHOLD:
        sev = "alert" if util >= 0.85 else ("warn" if util >= 0.7 else "info")
        findings.append({
            "finding_type": "corpus_cap_approaching",
            "corpus_name": name,
            "severity": sev,
            "details": {
                "root": str(root),
                "pattern": pat,
                "file_count": file_count,
                "total_bytes": total_bytes,
                "effective_cap_bytes": effective_cap,
                "utilization": round(util, 3),
                "threshold": THRESHOLD,
            },
            "proposal": f"bump {name} cap (current util={util:.0%}); sister fix shape: flywheel-zsk2d (256KB SKILL.md priority cap)",
        })


# --- Finding 2: orphan_script_no_glob_coverage ----------------------------
# Find scripts in .flywheel/scripts/*.sh that aren't matched by ANY of the
# gap-hunt-probe corpus globs. (Approximation: probe wired-but-cold class
# scans these; if a script isn't in any corpus AND not in any receivers,
# it would be flagged.)

flywheel_scripts = {p.name for p in safe_iter(REPO / ".flywheel/scripts", "*.sh", 500)}
# Other surfaces that contain script references via globs we know
covered_in_globs = set()
for glob_root, glob_pat in [
    (REPO / ".flywheel/lib", "*.sh"),
    (CLAUDE / "skills/.flywheel/lib", "*.sh"),
    (REPO / "tests", "*.sh"),
    (REPO / ".flywheel/tests", "*.sh"),
]:
    if glob_root.is_dir():
        for p in safe_iter(glob_root, glob_pat, 2000):
            covered_in_globs.add(p.name)
# Surface flywheel-scripts not appearing in any other directory (no name collision)
orphans = sorted(flywheel_scripts - covered_in_globs)
# Skip well-known "always orphan" patterns: probes (caught by probe-without-receiver class), wrappers
filtered_orphans = [s for s in orphans if not s.endswith("-probe.sh")]
if filtered_orphans:
    # Cap to first 5 to keep findings actionable
    sample = filtered_orphans[:5]
    findings.append({
        "finding_type": "orphan_script_no_glob_coverage",
        "severity": "info",
        "details": {
            "total_orphan_count": len(filtered_orphans),
            "sample": sample,
            "note": "These .flywheel/scripts/*.sh have no name-collision in lib/tests/skills — may surface as wired-but-cold FPs if not cited elsewhere. Excludes *-probe.sh (handled by probe-without-receiver class).",
        },
        "proposal": "audit sample for receiver wire-in OR add corpus extension if a clear glob pattern emerges (N>=3 of same shape)",
    })


# --- Finding 3: new_ledger_since_last_run ---------------------------------
# Compare current STATE_DIR/*.jsonl to prior snapshot. Surface new ledgers.

current_ledgers = sorted([p.name for p in safe_iter(STATE, "*.jsonl", 5000)])
prior_ledgers: list[str] = []
if SNAPSHOT.is_file():
    try:
        snap = json.loads(SNAPSHOT.read_text())
        prior_ledgers = sorted(snap.get("ledgers", []))
    except Exception:
        pass
new_ledgers = sorted(set(current_ledgers) - set(prior_ledgers))
if prior_ledgers and new_ledgers:
    findings.append({
        "finding_type": "new_ledger_since_last_run",
        "severity": "info",
        "details": {
            "new_ledger_count": len(new_ledgers),
            "sample": new_ledgers[:5],
            "total_current_ledgers": len(current_ledgers),
        },
        "proposal": "review new ledgers for cross-source-silos class — fresh producers should have receivers wired in tick.md / doctrine / rules",
    })


# --- Finding 4: ledger_producer_name_mismatch -----------------------------
# For each *-runs.jsonl ledger, build receivers corpus, check if producer-stem
# (stripping -runs) appears. If neither basename nor stem nor producer-stem
# in corpus → mismatch class (would surface as cross-source-silos despite
# flywheel-nq5ns calibration if producer also not cited).

receivers_pieces = []
for r in [REPO / "AGENTS.md", REPO / "INCIDENTS.md", REPO / "README.md"]:
    if r.is_file():
        receivers_pieces.append(read_text(r, 1_000_000))
for d in safe_iter(REPO / ".flywheel/doctrine", "*.md", 200):
    receivers_pieces.append(read_text(d, 200_000))
for d in safe_iter(REPO / ".flywheel/rules", "*.md", 500):
    receivers_pieces.append(read_text(d, 200_000))
for c in safe_iter(CLAUDE / "commands/flywheel", "*.md", 200):
    receivers_pieces.append(read_text(c, 1_000_000))
receivers_text = "\n".join(receivers_pieces)

mismatch_samples = []
for lg in safe_iter(STATE, "*-runs.jsonl", 2000):
    name = lg.name
    stem = lg.stem
    producer = stem[:-len("-runs")] if stem.endswith("-runs") else stem
    if name not in receivers_text and stem not in receivers_text and producer not in receivers_text:
        mismatch_samples.append({
            "ledger_basename": name,
            "producer_stem_attempted": producer,
        })
        if len(mismatch_samples) >= 5:
            break

if mismatch_samples:
    findings.append({
        "finding_type": "ledger_producer_name_mismatch",
        "severity": "warn",
        "details": {
            "sample_count": len(mismatch_samples),
            "sample": mismatch_samples,
            "note": "These ledgers have no basename/stem/producer-stem match in any sampled receiver. Either genuinely siloed (file follow-on bead per L52) OR producer is referenced under a different name shape (new probe blind spot — file calibration follow-on).",
        },
        "proposal": "audit each ledger: confirm if producer script exists + check if cited under different name; if pattern recurs (N>=3 same shape), file calibration follow-on",
    })


# --- Finding 5: large_skill_md_over_threshold -----------------------------
# SKILL.md files exceeding 50% of current 256KB cap (flywheel-zsk2d). Signal
# drift toward needing another cap bump.

skill_md_cap = 256 * 1024
skill_md_threshold = skill_md_cap * 0.5
large_skill_mds = []
for sm in safe_iter(CLAUDE / "skills", "SKILL.md", 6000):
    try:
        size = sm.stat().st_size
    except Exception:
        continue
    if size >= skill_md_threshold:
        large_skill_mds.append({
            "path": str(sm.relative_to(CLAUDE / "skills")) if (CLAUDE / "skills") in sm.parents else str(sm),
            "size_bytes": size,
            "cap_bytes": skill_md_cap,
            "utilization": round(size / skill_md_cap, 3),
        })
# Sort largest first
large_skill_mds.sort(key=lambda x: -x["size_bytes"])
if large_skill_mds:
    sample = large_skill_mds[:5]
    max_util = sample[0]["utilization"] if sample else 0
    sev = "alert" if max_util >= 1.0 else ("warn" if max_util >= 0.7 else "info")
    findings.append({
        "finding_type": "large_skill_md_over_threshold",
        "severity": sev,
        "details": {
            "total_count_over_threshold": len(large_skill_mds),
            "sample": sample,
            "current_cap_bytes": skill_md_cap,
            "threshold_bytes": skill_md_threshold,
        },
        "proposal": f"if max utilization >= 1.0 (currently {max_util:.0%}), file calibration to bump SKILL.md cap (sister: flywheel-zsk2d)",
    })


# --- Summary --------------------------------------------------------------

summary = {
    "total_findings": len(findings),
    "by_type": {},
    "by_severity": {"info": 0, "warn": 0, "alert": 0},
}
for f in findings:
    t = f.get("finding_type", "unknown")
    s = f.get("severity", "info")
    summary["by_type"][t] = summary["by_type"].get(t, 0) + 1
    summary["by_severity"][s] = summary["by_severity"].get(s, 0) + 1

result = {
    "schema_version": SCHEMA_VERSION,
    "version": VERSION,
    "source_bead": SOURCE_BEAD,
    "ts": now_iso,
    "threshold": THRESHOLD,
    "read_only": True,
    "findings": findings,
    "summary": summary,
    "snapshot_path": str(SNAPSHOT),
    "ledger_path": str(LEDGER),
}

print(json.dumps(result))

# --- Apply mode: append to ledger + update snapshot ----------------------
if APPLY:
    try:
        LEDGER.parent.mkdir(parents=True, exist_ok=True)
        with LEDGER.open("a") as f:
            f.write(json.dumps(result) + "\n")
        SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
        SNAPSHOT.write_text(json.dumps({
            "ts": now_iso,
            "ledgers": current_ledgers,
        }))
    except Exception as exc:
        print(f"warn: --apply failed: {exc}", file=sys.stderr)
PY
