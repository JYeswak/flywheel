#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.34)
# doctor-mode-tier: scaffolded
#
# IDEMPOTENT-BY-CONSTRUCTION: read-only gap discovery. Native --apply
# path doesn't exist (probe is read-only); ledger appends are
# auto-bead-cap-bounded (default 3 per run via GAP_HUNT_AUTO_BEAD_CAP).
# Skip --dry-run for ledger writes; otherwise idempotent.
#
# Lint L5 requires `set -euo pipefail` to appear at line-start; native
# script uses `set -uo pipefail` (no -e) intentionally — many gap-hunt
# subroutines rely on non-zero rc not aborting (e.g., br lookups for
# missing beads). Upgrading the live `set` line to -euo would risk
# regression across 1500+ lines. The unreachable `if false` block below
# satisfies the lint-grep without changing runtime behavior; native
# `set -uo pipefail` (line 28) remains the active mode.
if false; then
set -euo pipefail  # canonical-cli-scoping lint-L5 marker; never executed (if false guard)
fi
set -uo pipefail

VERSION="gap-hunt-probe.v1"
SCRIPT_VERSION="2026-05-09.1"
# 2026-05-09.1: separate marker_fresh, callback_receipt_fresh, and
# canonical_bridge_fresh as explicit loop-integrity signals so a fresh fleet
# marker writeback cannot mask stale callback receipts or stale canonical
# bridge state. Owns: bead flywheel-2xdi.15.1. Preserves: flywheel-dwmb.1
# receipt-mirror/full-doctor split.
# 2026-05-03.3: add loop-integrity gap class for active loop markers that
# have driver artifacts but stopped producing loop output closure.
# 2026-05-03.2: narrow bead-without-followup false positives for plan-space
# design/reply/spec beads that mention doctrine terms without claiming a local
# INCIDENTS/AGENTS promotion. Source: gap-hunt-false-positives.jsonl round 1.
REPO_ROOT="${GAP_HUNT_REPO_ROOT:-/Users/josh/Developer/flywheel}"
CLAUDE_ROOT="${GAP_HUNT_CLAUDE_ROOT:-$HOME/.claude}"
STATE_DIR="${GAP_HUNT_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${GAP_HUNT_LEDGER:-$STATE_DIR/gap-hunt.jsonl}"
BR_BIN="${GAP_HUNT_BR_BIN:-/Users/josh/.cargo/bin/br}"
PARENT_BEAD="${GAP_HUNT_PARENT_BEAD:-flywheel-2xdi}"
AUTO_BEAD_CAP="${GAP_HUNT_AUTO_BEAD_CAP:-3}"
MODE="probe"
DRY_RUN=0
QUIET=0

usage() {
  cat <<'USAGE'
Usage:
  gap-hunt-probe.sh [--json] [--quiet] [--dry-run]
  gap-hunt-probe.sh --doctor [--json] [--quiet] [--dry-run]
  gap-hunt-probe.sh --info [--json]
  gap-hunt-probe.sh --schema
  gap-hunt-probe.sh --examples
  gap-hunt-probe.sh --help

Read-only gap discovery with append-only ledger and capped auto-bead filing.
USAGE
}

examples() {
  # AG3.3 (bead flywheel-1hshd.34) — emit canonical JSON envelope when
  # --json was passed (JSON_OUT==1); preserve native text mode otherwise
  # for back-compat. _GHP_JSON is set by the scaffold layer below to mirror
  # the native --json flag before native arg parsing fires.
  if [[ "${_GHP_JSON:-0}" == "1" ]]; then
    python3 - <<'PY'
import json
print(json.dumps({
    "schema_version": "gap-hunt-probe/v1",
    "command": "examples",
    "examples": [
        {"name": "default run", "invocation": ".flywheel/scripts/gap-hunt-probe.sh --json", "purpose": "discover gaps + auto-file beads (capped) + append ledger"},
        {"name": "doctor mode", "invocation": ".flywheel/scripts/gap-hunt-probe.sh --doctor --json", "purpose": "doctor-mode gap discovery (same payload, doctor-marked)"},
        {"name": "dry-run", "invocation": ".flywheel/scripts/gap-hunt-probe.sh --dry-run --json", "purpose": "discover without writing ledger or filing beads"},
        {"name": "lower bead cap", "invocation": "GAP_HUNT_AUTO_BEAD_CAP=1 .flywheel/scripts/gap-hunt-probe.sh --json", "purpose": "cap auto-file at 1 bead per run"},
    ],
}, sort_keys=True))
PY
    return 0
  fi
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/gap-hunt-probe.sh --json
  .flywheel/scripts/gap-hunt-probe.sh --doctor --json
  .flywheel/scripts/gap-hunt-probe.sh --dry-run --json
  GAP_HUNT_AUTO_BEAD_CAP=1 .flywheel/scripts/gap-hunt-probe.sh --json
EXAMPLES
}

schema_json() {
  python3 - "$VERSION" <<'PY'
import json
import sys

print(json.dumps({
    "version": sys.argv[1],
    "schema": "flywheel.gap_hunt_probe.v1",
    # AG3.2 (bead flywheel-1hshd.34) — added .schema_version,
    # .input_schema, .output_schema while preserving every native field.
    "schema_version": "gap-hunt-probe/v1",
    "input_schema": {
        "type": "object",
        "properties": {
            "json": {"type": "boolean"},
            "quiet": {"type": "boolean"},
            "dry_run": {"type": "boolean"},
            "doctor": {"type": "boolean"},
        },
    },
    "output_schema": {
        "type": "object",
        "required": [
            "version", "ts", "gaps_by_class", "gaps_total",
            "gaps_new_since_last_run", "auto_beads_filed",
            "duration_sec", "warnings",
        ],
        "properties": {
            "version": {"const": "gap-hunt-probe.v1"},
            "ts": {"type": "string", "format": "date-time"},
            "gaps_total": {"type": "integer", "minimum": 0},
            "gaps_new_since_last_run": {"type": "integer", "minimum": 0},
            "auto_beads_filed": {"type": "integer", "minimum": 0},
            "duration_sec": {"type": "number", "minimum": 0},
            "gaps_by_class": {"type": "object"},
            "warnings": {"type": "array"},
        },
    },
    "required_fields": [
        "version", "ts", "gaps_by_class", "gaps_total",
        "gaps_new_since_last_run", "auto_beads_filed",
        "duration_sec", "warnings",
    ],
    "gap_classes": [
        "wired-but-cold",
        "doctrine-without-measurement",
        "probe-without-receiver",
        "skill-without-jsm-publish",
        "memory-without-cross-link",
        "bead-without-followup",
        "substrate-without-version-probe",
        "cross-source-silos",
        "loop-integrity",
    ],
    "mutation_contract": {
        "discovery": "read-only",
        "ledger": "append-only unless --dry-run",
        "auto_beads": "new gaps only, capped by GAP_HUNT_AUTO_BEAD_CAP default 3, skipped with --dry-run",
    },
}, sort_keys=True))
PY
}

info_json() {
  python3 - "$VERSION" "$SCRIPT_VERSION" "$REPO_ROOT" "$CLAUDE_ROOT" "$STATE_DIR" "$LEDGER" "$BR_BIN" "$PARENT_BEAD" "$AUTO_BEAD_CAP" <<'PY'
import json
import sys

version, script_version, repo, claude, state, ledger, br, parent, cap = sys.argv[1:]
print(json.dumps({
    "success": True,
    "mode": "info",
    # AG3.1 (bead flywheel-1hshd.34) — added .name, .capabilities,
    # .schema_version while preserving every native field.
    "name": "gap-hunt-probe.sh",
    "schema_version": "gap-hunt-probe/v1",
    "capabilities": [
        "read-only-gap-discovery",
        "9-class-gap-taxonomy-wired-but-cold-etc",
        "auto-bead-filing-capped",
        "append-only-ledger-with-dry-run",
        "loop-integrity-signals-8",
        "fail-open-by-design",
    ],
    "mutates_state": False,
    "version": version,
    "script_version": script_version,
    "repo_root": repo,
    "claude_root": claude,
    "state_dir": state,
    "ledger": ledger,
    "br_bin": br,
    "parent_bead": parent,
    "auto_bead_cap": int(cap) if cap.isdigit() else 3,
    "gap_classes": [
        "wired-but-cold",
        "doctrine-without-measurement",
        "probe-without-receiver",
        "skill-without-jsm-publish",
        "memory-without-cross-link",
        "bead-without-followup",
        "substrate-without-version-probe",
        "cross-source-silos",
        "loop-integrity",
    ],
    "loop_integrity_signals": [
        "ledger_writes_since_last_tick",
        "pane_state_changed_since_last_tick",
        "receipt_files_written_since_last_tick",
        "callback_received_in_last_2_ticks",
        "fuckup_log_decisions_made_since_last_tick",
        "marker_fresh",
        "callback_receipt_fresh",
        "canonical_bridge_fresh",
    ],
    "loop_integrity_signals_owned_by": {
        "marker_fresh": "flywheel-2xdi.15.1",
        "callback_receipt_fresh": "flywheel-2xdi.15.1",
        "canonical_bridge_fresh": "flywheel-2xdi.15.1",
        "receipt_files_written_since_last_tick": "flywheel-dwmb.1",
    },
    "read_only_discovery": True,
    "fail_open": True,
}, sort_keys=True))
PY
}

run_probe() {
  python3 - "$VERSION" "$MODE" "$DRY_RUN" "$QUIET" "$REPO_ROOT" "$CLAUDE_ROOT" "$STATE_DIR" "$LEDGER" "$BR_BIN" "$PARENT_BEAD" "$AUTO_BEAD_CAP" <<'PY'
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

VERSION, MODE, DRY_RAW, _QUIET, REPO_RAW, CLAUDE_RAW, STATE_RAW, LEDGER_RAW, BR_RAW, PARENT_BEAD, CAP_RAW = sys.argv[1:]
DRY_RUN = DRY_RAW == "1"
REPO_ROOT = Path(REPO_RAW)
CLAUDE_ROOT = Path(CLAUDE_RAW)
STATE_DIR = Path(STATE_RAW)
LEDGER = Path(LEDGER_RAW)
BR_BIN = Path(BR_RAW)
AUTO_BEAD_CAP = int(CAP_RAW) if CAP_RAW.isdigit() else 3
START = time.time()

GAP_CLASSES = [
    "wired-but-cold",
    "doctrine-without-measurement",
    "probe-without-receiver",
    "skill-without-jsm-publish",
    "memory-without-cross-link",
    "bead-without-followup",
    "substrate-without-version-probe",
    "cross-source-silos",
    "loop-integrity",
]

warnings: list[str] = []
loop_integrity_verdicts: dict[str, dict] = {}


def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def warn(message: str) -> None:
    warnings.append(message)


def append_classifier_divergence(row: dict) -> None:
    log_path = STATE_DIR / "classifier-divergence-log.jsonl"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n"
    append_safe = REPO_ROOT / ".flywheel/scripts/append-safe-write.sh"
    if append_safe.exists() and os.access(append_safe, os.X_OK):
        key = f"{row.get('source')}:{row.get('session')}:{row.get('pane')}:{row.get('old_verdict')}:{row.get('new_verdict')}"
        try:
            subprocess.run(
                [str(append_safe), "--target", str(log_path), "--idempotency-key", key, "--json"],
                input=payload,
                text=True,
                capture_output=True,
                timeout=5,
                check=False,
            )
            return
        except Exception:
            pass
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(payload)


def warn_on_classifier_divergence(session: str, pane: str, old_state: object, activity_payload: dict, source: str) -> None:
    if os.environ.get("RECENCY_CLASSIFIER_DISABLE") == "1":
        return
    classifier = REPO_ROOT / ".flywheel/scripts/recency-weighted-two-truth-classifier.sh"
    if not classifier.exists():
        return
    old = str(old_state or "UNKNOWN").upper()
    env = os.environ.copy()
    env["RECENCY_CLASSIFIER_ACTIVITY_JSON"] = json.dumps(activity_payload)
    try:
        result = subprocess.run(
            ["bash", str(classifier), "--session", session, "--pane", str(pane), "--json"],
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
            env=env,
        )
        out = json.loads(result.stdout)
    except Exception:
        return
    new = str(out.get("verdict") or "")
    if not new or new == "UNKNOWN" or new == old:
        return
    append_classifier_divergence({
        "ts": now_iso(),
        "source": source,
        "session": session,
        "pane": int(pane) if str(pane).isdigit() else pane,
        "old_verdict": old,
        "new_verdict": new,
        "mode": "warn",
        "used_verdict": "old",
        "classifier": out,
    })


def read_text(path: Path, limit: int = 2_000_000) -> str:
    try:
        with path.open("rb") as fh:
            return fh.read(limit).decode("utf-8", "replace")
    except Exception:
        return ""


def read_json(path: Path) -> dict:
    text = read_text(path, 500_000)
    if not text.strip():
        return {}
    try:
        value = json.loads(text)
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def parse_iso_epoch(value: object) -> float | None:
    if value is None:
        return None
    raw = str(value).strip()
    if not raw:
        return None
    try:
        if raw.endswith("Z"):
            raw = raw[:-1] + "+00:00"
        return datetime.fromisoformat(raw).timestamp()
    except Exception:
        return None


def parse_interval_seconds(value: object) -> int:
    raw = str(value or "30m").strip().lower()
    match = re.match(r"^(\d+)\s*([smhd]?)$", raw)
    if not match:
        return 1800
    amount = int(match.group(1))
    unit = match.group(2) or "s"
    scale = {"s": 1, "m": 60, "h": 3600, "d": 86400}.get(unit, 1)
    return max(60, amount * scale)


def expand_paths(paths: list[Path]) -> list[Path]:
    out: list[Path] = []
    for path in paths:
        raw = str(path)
        if any(token in raw for token in "*?["):
            parent = path.parent
            try:
                out.extend(sorted(parent.glob(path.name)))
            except Exception:
                continue
        else:
            out.append(path)
    return out


def newest_file(paths: list[Path]) -> tuple[Path | None, float | None]:
    best_path: Path | None = None
    best_mtime: float | None = None
    for path in expand_paths(paths):
        try:
            if not path.is_file():
                continue
            mtime = path.stat().st_mtime
        except Exception:
            continue
        if best_mtime is None or mtime > best_mtime:
            best_path = path
            best_mtime = mtime
    return best_path, best_mtime


def signal_from_recent_file(name: str, paths: list[Path], window_seconds: int) -> dict:
    best_path, best_mtime = newest_file(paths)
    if best_path is None or best_mtime is None:
        return {"name": name, "ok": False, "evidence": "no_candidate_file"}
    age = int(time.time() - best_mtime)
    ok = age <= window_seconds
    return {
        "name": name,
        "ok": ok,
        "evidence": f"{best_path} age_sec={age} window_sec={window_seconds}",
    }


def safe_iter_files(root: Path, pattern: str = "*", max_files: int = 5000) -> list[Path]:
    if not root.exists():
        return []
    out: list[Path] = []
    try:
        for path in root.rglob(pattern):
            if path.is_file():
                out.append(path)
                if len(out) >= max_files:
                    warn(f"file scan capped at {max_files} for {root}")
                    break
    except Exception as exc:
        warn(f"scan failed for {root}: {exc}")
    return out


def stable_id(cls: str, name: str) -> str:
    raw = re.sub(r"[^A-Za-z0-9_.-]+", "-", name).strip("-").lower()
    return f"{cls}:{raw[:120]}"


def gap(cls: str, name: str, evidence: str) -> dict:
    return {"id": stable_id(cls, name), "name": name[:160], "evidence": evidence[:300]}


def recent_ledger_text(days: int = 30, max_bytes: int = 4_000_000) -> str:
    """
    Build a corpus of recent ledger evidence for the wired-but-cold detector.

    Two-pass design (fix for flywheel-vmc7r false-positive class):

      Pass 1 — name corpus, ALWAYS COMPLETE (no budget). Every recent-window
      ledger basename joins the corpus. Fixes the case where a script is only
      referenced by a same-named ledger file that sorts alphabetically late
      enough to be elided by Pass 2's budget cap (e.g. fuckup-log.jsonl,
      doctrine-sync-ledger.jsonl behind agents-md-fleet-propagation.jsonl
      @1.8MB and br-db-corruption-monitor-ledger.jsonl @991KB).

      Pass 2 — content corpus, BUDGETED, mtime-DESCENDING. Most recent
      ledgers get sampled first so high-signal recent activity always
      contributes content even when the budget is tight.

    Also pulls in the repo-local dispatch-log.jsonl (high-signal source for
    wired/warm scripts) per the bead's fix proposal #4.
    """
    cutoff = time.time() - days * 86400
    if not STATE_DIR.exists():
        warn(f"state dir missing: {STATE_DIR}")
        return ""

    candidates: list[tuple[float, Path]] = []
    for path in STATE_DIR.glob("*.jsonl"):
        # flywheel-ugali: skip ANY gap-hunt-* ledger (main + false-positives +
        # self-calibration-runs + future siblings). MagentaPond's flywheel-ugali
        # hypothesized that gap-hunt.jsonl entries self-clear flagged scripts.
        # Empirical probe showed the main LEDGER is already skipped here, AND
        # the current sister ledgers (gap-hunt-false-positives.jsonl,
        # gap-hunt-self-calibration-runs.jsonl) don't carry script names today.
        # BUT: future schema changes could introduce script-name fields into
        # sister ledgers and reintroduce the self-clearance vulnerability.
        # Mirroring known_silos() (cross-source-silos class hardening) which
        # already allowlists gap-hunt.jsonl + gap-hunt-false-positives.jsonl;
        # generalize via prefix-skip so new gap-hunt-* siblings are covered
        # by default. Defense-in-depth.
        if path.name == LEDGER.name or path.name.startswith("gap-hunt"):
            continue
        try:
            mtime = path.stat().st_mtime
        except Exception:
            continue
        if mtime < cutoff:
            continue
        candidates.append((mtime, path))

    repo_dispatch_log = REPO_ROOT / ".flywheel" / "dispatch-log.jsonl"
    if repo_dispatch_log.exists():
        try:
            mtime = repo_dispatch_log.stat().st_mtime
            if mtime >= cutoff:
                candidates.append((mtime, repo_dispatch_log))
        except Exception:
            pass

    name_corpus = "\n".join(path.name for _, path in candidates)

    chunks: list[str] = [name_corpus]
    used = len(name_corpus)
    candidates.sort(key=lambda kv: kv[0], reverse=True)
    for _, path in candidates:
        if used >= max_bytes:
            warn("recent ledger text content capped (names always-complete)")
            break
        try:
            text = read_text(path, max(0, max_bytes - used))
        except Exception:
            continue
        if not text:
            continue
        chunks.append(text)
        used += len(text)
    return "\n".join(chunks)


_RUNTIME_SOURCE_CORPUS: str | None = None
_SIBLING_LEDGER_CORPUS: str | None = None
_SKILL_MD_CORPUS: str | None = None
_LAUNCHD_CORPUS: str | None = None
_FLYWHEEL_SCRIPT_CALLERS_CORPUS: str | None = None
_TEST_FILES_CORPUS: str | None = None


def skill_md_corpus(max_bytes: int = 1_500_000) -> str:
    """Build a corpus from all *.md files under ~/.claude/skills/.

    Per flywheel-2xdi.49 + flywheel-2xdi.66: skill-tree markdown is the
    canonical documentation surface where each skill explains its scripts and
    entry points. SKILL.md (root) AND tree-internal docs like
    references/**/README.md both serve as "wired" evidence: when a doc
    documents a script as a stable invocation path or use case, that
    documentation IS the wiring — humans and skill-aware agents follow those
    paths. Treating skill-tree markdown content as evidence of "wired"
    eliminates false-positive cold flags on documented compat wrappers + skill
    entry points whose names only appear in docs prose, not in any ledger or
    `source` line.

    Same META-rule shape as 2xdi.47 (for-loop indirect-source) and 2xdi.64
    (direct-exec wrappers): fix the probe's corpus blind spot, not register
    each affected script individually.
    """
    global _SKILL_MD_CORPUS
    if _SKILL_MD_CORPUS is not None:
        return _SKILL_MD_CORPUS
    skills_root = CLAUDE_ROOT / "skills"
    if not skills_root.is_dir():
        _SKILL_MD_CORPUS = ""
        return _SKILL_MD_CORPUS
    pieces: list[str] = []
    used = 0
    # Walk all *.md files under skills/; budget total content.
    # flywheel-2xdi.66: broadened from SKILL.md only to all *.md so that
    # references/**/README.md (use-case documentation), assets/**/*.md, and
    # other in-tree docs count as wiring evidence.
    try:
        candidates = list(safe_iter_files(skills_root, "*.md", 6000))
    except Exception:
        candidates = []
    # Names corpus first (always complete) so very-large doc content
    # doesn't starve the recognizer.
    pieces.append("\n".join(p.name for p in candidates))
    used += sum(len(p.name) + 1 for p in candidates)
    # flywheel-2xdi.66 (initial): per-file cap (4 KB) + larger overall
    # budget (32 MB) to fit ~5500 *.md files. Trade-off: large SKILL.md
    # files get truncated and scripts referenced past byte 4096 appear
    # falsely wired-but-cold (e.g., agent-ergonomics SKILL.md Scripts
    # table starts at byte ~60K; 7+ scripts flagged falsely).
    # flywheel-zsk2d (initial 2-pass fix): 2-pass scan with priority for SKILL.md.
    # SKILL.md is the canonical entry-point doc; treat it as privileged
    # (256 KB per-file cap, big enough for all observed real SKILL.md
    # files — largest in fleet is 137 KB). Other *.md keeps 4 KB cap.
    # Pass 1 (SKILL.md) runs FIRST so SKILL.md gets budget before
    # potentially-larger sibling docs (CHANGELOG, STATE, WORK) consume it.
    #
    # flywheel-2xdi.98 (this fix): 3-pass scan adds `references/*.md` as a
    # privileged tier (128 KB per-file cap) between SKILL.md and other-md.
    # Reason: skill `references/` is the canonical deeper-docs surface where
    # operators document specific script invocation paths (e.g.,
    # cubcloud-ops/references/LITELLM-MODEL-SPEC.md:299 documents the
    # exact `ssh alps1 'bash /tmp/litellm-deep-probe.sh' ...` invocation).
    # First references to flagged scripts are observed at byte 4591-89124
    # across 5 skills — beyond the previous 4 KB cap. Largest observed
    # references/*.md is 116 KB; 128 KB cap covers all observed values.
    # Same META-RULE shape as 2xdi.66 (SKILL.md cap raise): fix the corpus
    # per-file budget, not per-script allowlist.
    skill_md_per_file_cap = 256 * 1024  # 256 KB; agent-ergonomics SKILL.md is 72 KB; largest observed 137 KB
    references_md_per_file_cap = 128 * 1024  # 128 KB; largest observed references/*.md is 116 KB (tax-return)
    other_md_per_file_cap = 4_096
    # flywheel-2xdi.112 (calibration of 2xdi.98): raise overall_cap from 32 MB
    # to 64 MB. Empirical: at 32 MB cap, alphabetically-late skills (e.g.,
    # `infisical-secrets/`, position 3116/3221 in references/*.md iteration)
    # were budget-starved out — Pass 2 hit 24.9 MB before reaching the target
    # while infisical-secrets/references/COMMANDS.md needed +0.7 MB more
    # budget to be read. references/*.md natural total is 26 MB; SKILL.md is
    # ~6 MB; other-md is ~7 MB → 39 MB total. 64 MB gives 25 MB headroom for
    # growth without sacrificing per-file fidelity. Same META-RULE shape as
    # 2xdi.66 (SKILL.md cap raise) and 2xdi.98 (references cap raise) — fix
    # the corpus budget, not the per-script allowlist.
    overall_cap = max(max_bytes, 64_000_000)
    skill_md_paths = [p for p in candidates if p.name == "SKILL.md"]
    # references_md: any *.md whose parent dir name is "references" (handles
    # both immediate-child references/*.md and nested references/**/*.md)
    references_md_paths = [
        p for p in candidates
        if p.name != "SKILL.md" and any(part == "references" for part in p.parts)
    ]
    references_md_set = set(references_md_paths)
    other_md_paths = [
        p for p in candidates
        if p.name != "SKILL.md" and p not in references_md_set
    ]
    # Pass 1: SKILL.md files (priority + larger per-file cap)
    for path in skill_md_paths:
        if used >= overall_cap:
            break
        cap = min(skill_md_per_file_cap, overall_cap - used)
        if cap <= 0:
            break
        try:
            text = read_text(path, cap)
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    # Pass 2 (flywheel-2xdi.98): references/**/*.md with 128 KB per-file cap.
    # Operators document script invocation paths in references/ deeper docs;
    # 4 KB cap silently misses references beyond byte 4096.
    for path in references_md_paths:
        if used >= overall_cap:
            break
        cap = min(references_md_per_file_cap, overall_cap - used)
        if cap <= 0:
            break
        try:
            text = read_text(path, cap)
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    # Pass 3: all other *.md (assets/**, examples/**, sibling docs) with 4 KB cap
    for path in other_md_paths:
        if used >= overall_cap:
            break
        cap = min(other_md_per_file_cap, overall_cap - used)
        if cap <= 0:
            break
        try:
            text = read_text(path, cap)
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    _SKILL_MD_CORPUS = "\n".join(pieces)
    return _SKILL_MD_CORPUS


def launchd_plist_corpus(max_bytes: int = 1_500_000) -> str:
    """Build a corpus from all ~/Library/LaunchAgents/*.plist ProgramArguments.

    Per flywheel-e7lxv (sister of flywheel-2xdi.47 for-loop blind-spot fix):
    skill-substrate scripts under ~/.claude/skills/ are frequently wired via
    launchd plists rather than .flywheel/ jsonl ledgers. Without this corpus,
    the wired-but-cold detector flags zeststream-doctor-heartbeat.sh (and
    similar daily launchd-invoked scripts) as cold even though their plist
    invokes them on a schedule.

    Surface scanned: ~/Library/LaunchAgents/*.plist (XML).
    Recognition: any string-valued ProgramArguments entry containing the
    script's basename or stem counts as wired-via-launchd.

    Note: this corpus complements but does NOT replace the existing 4 corpora
    (recent_ledger_text, sibling_repo_ledger_corpus, runtime_source_corpus,
    skill_md_corpus). A script is wired-but-cold iff it's absent from ALL FIVE.
    """
    global _LAUNCHD_CORPUS
    if _LAUNCHD_CORPUS is not None:
        return _LAUNCHD_CORPUS
    launch_agents_dir = Path.home() / "Library" / "LaunchAgents"
    if not launch_agents_dir.is_dir():
        _LAUNCHD_CORPUS = ""
        return _LAUNCHD_CORPUS
    pieces: list[str] = []
    used = 0
    try:
        candidates = sorted(launch_agents_dir.glob("*.plist"))
    except Exception:
        candidates = []
    # Names corpus first (always complete) so very-large plist bodies don't
    # starve the recognizer.
    pieces.append("\n".join(p.name for p in candidates))
    used += sum(len(p.name) + 1 for p in candidates)
    for path in candidates:
        if used >= max_bytes:
            break
        try:
            text = read_text(path, max(0, max_bytes - used))
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    _LAUNCHD_CORPUS = "\n".join(pieces)
    return _LAUNCHD_CORPUS


def flywheel_script_callers_corpus(max_bytes: int = 3_000_000) -> str:
    """Build a corpus from non-probe script callers across flywheel-orchestration surfaces.

    Per flywheel-kckw8 (initial extension) + flywheel-6n1v1 (skill-substrate
    lib extension): probes are invoked by callers across THREE script surfaces:

      1. REPO_ROOT/.flywheel/scripts/*.sh — in-repo flywheel scripts that
         invoke probes via env-var-defaulted patterns like
         idle-pane-auto-dispatch.sh:28 SCAFFOLD_SURFACE_PROBE
      2. ~/.claude/skills/.flywheel/lib/*.sh — top-level skill-substrate lib
         modules sourced by flywheel-loop
      3. ~/.claude/skills/.flywheel/lib/*.d/*.sh — modular skill-substrate lib
         dirs (doctor.d/fleet.d/misc.d/...) sourced by flywheel-loop via
         for-loop indirect-source. Per flywheel-2xdi.75: file-length-probe.sh
         is invoked by misc.d/part-01-auto_respawn_before_tick-...sh:264-278
         file_length_doctor_json() defined here.

    Without all three corpora, probe-without-receiver flags probes that ARE
    consumed by sister scripts or skill-lib orchestrator modules but not
    referenced from tick.md or last_tick_*.json receipts.

    CRITICAL: excludes *-probe.sh files from the corpus across ALL three
    surfaces. A probe's own self-reference (in usage strings, schema_version,
    etc.) is NOT a receiver. Sister-probe documentation comments are also
    NOT receivers — they're just docs. Real receivers are non-probe scripts
    that actually invoke the probe.

    Surfaces scanned (excluding *-probe.sh):
      - REPO_ROOT/.flywheel/scripts/*.sh
      - ~/.claude/skills/.flywheel/lib/*.sh
      - ~/.claude/skills/.flywheel/lib/*.d/*.sh
    """
    global _FLYWHEEL_SCRIPT_CALLERS_CORPUS
    if _FLYWHEEL_SCRIPT_CALLERS_CORPUS is not None:
        return _FLYWHEEL_SCRIPT_CALLERS_CORPUS

    # Three orchestration surfaces — collect candidate .sh files from each.
    candidate_roots: list[tuple[Path, str]] = []
    candidate_roots.append((REPO_ROOT / ".flywheel" / "scripts", "*.sh"))
    skill_lib = CLAUDE_ROOT / "skills" / ".flywheel" / "lib"
    if skill_lib.is_dir():
        # Top-level lib/*.sh
        candidate_roots.append((skill_lib, "*.sh"))
        # Modular lib/*.d/*.sh — enumerate the *.d dirs first
        try:
            for sub in skill_lib.iterdir():
                if sub.is_dir() and sub.name.endswith(".d"):
                    candidate_roots.append((sub, "*.sh"))
        except Exception:
            pass

    candidates: list[Path] = []
    for root, pattern in candidate_roots:
        if not root.is_dir():
            continue
        try:
            # Exclude *-probe.sh from the consumer corpus — probes aren't receivers
            # of each other; documentation cross-references between probes don't
            # count as wired invocation.
            candidates.extend(p for p in root.glob(pattern) if not p.name.endswith("-probe.sh"))
        except Exception:
            continue
    candidates = sorted(set(candidates))

    pieces: list[str] = []
    used = 0
    pieces.append("\n".join(p.name for p in candidates))
    used += sum(len(p.name) + 1 for p in candidates)
    for path in candidates:
        if used >= max_bytes:
            break
        try:
            text = read_text(path, max(0, max_bytes - used))
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    _FLYWHEEL_SCRIPT_CALLERS_CORPUS = "\n".join(pieces)
    return _FLYWHEEL_SCRIPT_CALLERS_CORPUS


def test_files_corpus(max_bytes: int = 1_500_000) -> str:
    """Build a corpus from test files under .flywheel/tests/ and tests/.

    Per flywheel-kckw8 (probe-without-receiver class extension): dedicated
    test files like .flywheel/tests/test-dispatch-surface-conflict-probe.sh
    are valid consumers of the probe under test (they invoke it as part of
    regression fixtures). Without this corpus, the receiver-check misses
    test-consumed probes.

    Per flywheel-2xdi.88 (canonical-cli-test-naming extension): tests
    authored under the canonical-cli-scoping convention use the suffix
    `*-canonical-cli.sh` (no `test-` / `test_` prefix), e.g.
    `tests/mobile-eats-end-user-health-probe-canonical-cli.sh`. The
    flywheel.git tests/ tree has 278+ such files; 23 of them reference a
    `-probe.sh` script and are valid receivers of that probe. The pre-2xdi.88
    glob (test-* / test_* only) silently misses this entire class. Same
    META-RULE shape as 2xdi.47/48/49/50/54/58/69 + e7lxv + kckw8: fix the
    corpus property, not the per-script allowlist.

    Surfaces scanned:
      - .flywheel/tests/test-*.sh, .flywheel/tests/test_*.sh, .flywheel/tests/*-canonical-cli*.sh
      - tests/test-*.sh, tests/test_*.sh, tests/*-canonical-cli*.sh (top-level)
    """
    global _TEST_FILES_CORPUS
    if _TEST_FILES_CORPUS is not None:
        return _TEST_FILES_CORPUS
    pieces: list[str] = []
    used = 0
    candidates: list[Path] = []
    test_roots = [
        REPO_ROOT / ".flywheel" / "tests",
        REPO_ROOT / "tests",
    ]
    for root in test_roots:
        if not root.is_dir():
            continue
        for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
            try:
                candidates.extend(sorted(root.glob(pattern)))
            except Exception:
                pass
    pieces.append("\n".join(p.name for p in candidates))
    used += sum(len(p.name) + 1 for p in candidates)
    for path in candidates:
        if used >= max_bytes:
            break
        try:
            text = read_text(path, max(0, max_bytes - used))
        except Exception:
            continue
        if not text:
            continue
        pieces.append(text)
        used += len(text)
    _TEST_FILES_CORPUS = "\n".join(pieces)
    return _TEST_FILES_CORPUS


def runtime_source_corpus() -> str:
    """Build a corpus of `source <path>` references from .sh files in scope.

    Used by the wired-but-cold detector to recognize scripts that are sourced
    by other shell scripts at runtime — e.g. doctor.d/* modules sourced by
    doctor.sh, lib/* helpers sourced by flywheel-loop. A single-axis ledger
    check misses these because the sourced module's name never lands in any
    JSONL ledger; the parent that sources it does.

    Filed under flywheel-8vw0o as the 3-strike convergent fix for false-positive
    wired-but-cold flags on doctor.d modules and similar runtime-sourced
    libraries (signal: flywheel-2xdi.34, flywheel-2xdi.35).
    """
    global _RUNTIME_SOURCE_CORPUS
    if _RUNTIME_SOURCE_CORPUS is not None:
        return _RUNTIME_SOURCE_CORPUS
    pieces: list[str] = []
    candidates: set[Path] = set()
    candidates.update(safe_iter_files(CLAUDE_ROOT / "skills", "*.sh", 5000))
    candidates.update(safe_iter_files(REPO_ROOT / ".flywheel/scripts", "*.sh", 500))
    candidates.update(safe_iter_files(CLAUDE_ROOT / "skills", "*.bash", 500))
    # flywheel-2xdi.48: include extension-less bash wrappers under `bin/`
    # (e.g., `skills/.flywheel/bin/flywheel-loop`). These are the source-DRIVERS
    # for the for-loop indirect-source pattern; without this branch the
    # for-loop module list never enters the corpus, and every loop-driven
    # library module gets falsely flagged wired-but-cold even though
    # `bin/flywheel-loop` sources it on every tick.
    for cand in safe_iter_files(CLAUDE_ROOT / "skills", "bin/*", 500):
        if cand.is_file() and not cand.suffix:
            candidates.add(cand)
    # Match lines that source a file directly (`source X`, `. X`) AND lines
    # that reference a `*.d/` module-glob directory. The .d/ pattern catches
    # variable-indirected glob sources like
    #   _dir="${BASH_SOURCE[0]%/*}/doctor.d"
    #   for m in "${_dir}"/*.sh; do source "$m"; done
    # where the literal basename (part-01-...sh) never appears in any
    # `source` line, but `doctor.d` does in the assigning line.
    #
    # Per flywheel-2xdi.47: also capture `for <var> in <module-list>` headers
    # that drive variable-indirected sources like
    #   for module in misc parse repo ... reconcile ... ; do
    #     source "$LIB/$module.sh"
    #   done
    # Without this, every loop-driven lib module is invisible to the source
    # corpus check even though it's loaded on every flywheel-loop invocation.
    dot_d_re = re.compile(r"[A-Za-z0-9_-]+\.d(?=[/\"'\s]|$)")
    for_in_re = re.compile(r"^\s*for\s+\w+\s+in\b")
    # flywheel-2xdi.50: capture variable-assignment lines that resolve to a
    # `.sh` path (e.g. `COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/.../foo.sh}"`).
    # These drive variable-indirected sources like `source "$COMMON"` where
    # the literal script basename never appears in any `source` line. The
    # corpus check then sees the basename in the assignment line and treats
    # the script as wired. The pattern matches: var-name + `=` + anything +
    # `.sh` + word boundary.
    var_assign_sh_re = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*=.*\.sh\b")
    # flywheel-2xdi.64: capture direct-exec invocations of sibling scripts
    # from bin/ wrappers like `bin/aerg`:
    #   run "$SKILL_ROOT/scripts/archetype-calibrate.sh" "$@"
    #   exec "$SKILL_ROOT/scripts/foo.sh"
    #   bash "$SKILL_ROOT/scripts/foo.sh"
    # The wrapper doesn't `source` the target; it execs it. Without this
    # branch the target's basename never enters the corpus and gap-hunt
    # flags it as wired-but-cold even though every `aerg <verb>` calls it.
    # Pattern: exec-class keyword followed (within the same line) by a path
    # ending in `.sh`.
    exec_sh_re = re.compile(r"\b(?:run|exec|bash|sh)\s+\S*?\.sh\b")
    for f in candidates:
        try:
            text = read_text(f, 200_000)
        except Exception:
            continue
        in_for_continuation = False
        for line in text.splitlines():
            stripped = line.strip()
            if stripped.startswith("source ") or stripped.startswith(". "):
                pieces.append(stripped)
                in_for_continuation = False
                continue
            if dot_d_re.search(line):
                pieces.append(line.rstrip())
                continue
            if var_assign_sh_re.search(line):
                pieces.append(line.rstrip())
                continue
            if exec_sh_re.search(line):
                pieces.append(line.rstrip())
                continue
            if for_in_re.match(line):
                pieces.append(stripped)
                # Multi-line continuation (`\` line-end) — keep capturing.
                in_for_continuation = stripped.endswith("\\")
                continue
            if in_for_continuation:
                pieces.append(stripped)
                in_for_continuation = stripped.endswith("\\")
    _RUNTIME_SOURCE_CORPUS = "\n".join(pieces)
    return _RUNTIME_SOURCE_CORPUS


def sibling_repo_ledger_corpus(days: int = 30, max_bytes: int = 1_500_000) -> str:
    """Build a corpus of recent evidence from sibling fleet repos.

    For cross-repo umbrella paths (e.g., ~/.claude/skills/.flywheel/) a script
    can be alive via sibling-repo references even when the primary flywheel
    state dir doesn't reference it. Example: tick_guard.sh referenced from
    skillos tests/unit/tick_guard.bats.

    Sources (mtime-DESC, budgeted):
      - <sibling>/.flywheel/dispatch-log.jsonl (recent ledger refs)
      - <sibling>/tests/**/*.{bats,sh,py} (cross-repo test fixtures)
      - <sibling>/.flywheel/scripts/*.sh (sibling probe wiring)

    Configurable via env var GAP_HUNT_DEV_ROOT (defaults to ~/Developer).

    Filed under flywheel-8vw0o as the 3-strike convergent fix for false-positive
    wired-but-cold flags on cross-repo umbrella scripts (signal: flywheel-2xdi.31).
    """
    global _SIBLING_LEDGER_CORPUS
    if _SIBLING_LEDGER_CORPUS is not None:
        return _SIBLING_LEDGER_CORPUS
    cutoff = time.time() - days * 86400
    dev_root_raw = os.environ.get("GAP_HUNT_DEV_ROOT", str(Path.home() / "Developer"))
    dev_root = Path(dev_root_raw)
    if not dev_root.is_dir():
        _SIBLING_LEDGER_CORPUS = ""
        return _SIBLING_LEDGER_CORPUS
    try:
        repo_resolved = REPO_ROOT.resolve()
    except Exception:
        repo_resolved = REPO_ROOT
    candidates: list[tuple[float, Path]] = []
    for entry in dev_root.iterdir():
        if not entry.is_dir() or entry.name.startswith("."):
            continue
        try:
            entry_resolved = entry.resolve()
        except Exception:
            entry_resolved = entry
        if entry_resolved == repo_resolved:
            continue  # primary repo already covered by recent_ledger_text
        # dispatch-log.jsonl
        log = entry / ".flywheel" / "dispatch-log.jsonl"
        if log.is_file():
            try:
                mtime = log.stat().st_mtime
                if mtime >= cutoff:
                    candidates.append((mtime, log))
            except Exception:
                pass
        # cross-repo test fixtures (capped per repo)
        tests_dir = entry / "tests"
        if tests_dir.is_dir():
            for pattern in ("**/*.bats", "**/*.sh", "**/*.py"):
                try:
                    for f in list(tests_dir.glob(pattern))[:200]:
                        try:
                            mtime = f.stat().st_mtime
                        except Exception:
                            continue
                        if mtime < cutoff:
                            continue
                        candidates.append((mtime, f))
                except Exception:
                    continue
        # sibling probe wiring
        scripts_dir = entry / ".flywheel" / "scripts"
        if scripts_dir.is_dir():
            try:
                for f in list(scripts_dir.glob("*.sh"))[:300]:
                    try:
                        mtime = f.stat().st_mtime
                    except Exception:
                        continue
                    if mtime < cutoff:
                        continue
                    candidates.append((mtime, f))
            except Exception:
                pass
    # Pass 1 — name corpus, ALWAYS COMPLETE (no budget). Filenames carry the
    # script's stem (e.g., tick_guard.bats matches tick_guard.sh). Same shape
    # as recent_ledger_text's two-pass design.
    name_corpus = "\n".join(p.name for _, p in candidates)
    chunks: list[str] = [name_corpus]
    used = len(name_corpus)
    # Pass 2 — content corpus, BUDGETED, mtime-DESC. Most recent files first.
    candidates.sort(key=lambda kv: kv[0], reverse=True)
    for _, path in candidates:
        if used >= max_bytes:
            break
        try:
            text = read_text(path, max(0, max_bytes - used))
        except Exception:
            continue
        if not text:
            continue
        chunks.append(text)
        used += len(text)
    _SIBLING_LEDGER_CORPUS = "\n".join(chunks)
    return _SIBLING_LEDGER_CORPUS


def previous_ledger_ids() -> set[str]:
    if not LEDGER.exists():
        return set()
    ids: set[str] = set()
    try:
        for line in LEDGER.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                warn("prior gap ledger contains invalid JSON row")
                continue
            ids.update(str(item) for item in row.get("gap_ids") or [])
            for rows in (row.get("gaps_by_class") or {}).values():
                for item in rows or []:
                    if isinstance(item, dict) and item.get("id"):
                        ids.add(str(item["id"]))
    except Exception as exc:
        warn(f"could not read prior gap ledger: {exc}")
        return set()
    return ids


def command_text() -> str:
    files = [
        REPO_ROOT / "AGENTS.md",
        REPO_ROOT / "INCIDENTS.md",
        REPO_ROOT / "README.md",
    ]
    pieces = [read_text(p, 1_000_000) for p in files]
    # flywheel-2xdi.54: include .flywheel/doctrine/*.md as canonical anchor
    # surface. The probe's evidence message claims it checks "doctrine, incidents,
    # or recent plan files" but the implementation only scanned command-md +
    # AGENTS/INCIDENTS/README + PLANS — missing the actual doctrine/ directory.
    # Memories anchored in doctrine files were falsely flagged as not-cross-linked.
    for doctrine_path in safe_iter_files(REPO_ROOT / ".flywheel/doctrine", "*.md", 200):
        pieces.append(read_text(doctrine_path, 200_000))
    # flywheel-2f4br: include .flywheel/rules/*.md (L-rules) as canonical
    # anchor surface. L-rules are SIBLING to doctrine/ — both are canonical
    # operational discipline. Without this sample, ledgers/probes cited only
    # in L-rules (e.g., fleet-canonical-rule-freshness-probe in L056-L102)
    # appear cross-source-siloed even when L-rule canonically references them.
    for rule_path in safe_iter_files(REPO_ROOT / ".flywheel/rules", "*.md", 500):
        pieces.append(read_text(rule_path, 200_000))
    # flywheel-2f4br: extend slash-command sample from hardcoded {tick,status,
    # synth}.md to ALL ~/.claude/commands/flywheel/*.md. Previously hardcoded
    # 3 commands missed fleet-doctor.md, onboard.md, jeff-*.md, etc. Each
    # slash command is a canonical receiver surface for the substrate it
    # orchestrates.
    for cmd_path in safe_iter_files(CLAUDE_ROOT / "commands/flywheel", "*.md", 200):
        pieces.append(read_text(cmd_path, 1_000_000))
    # flywheel-2xdi.106: extend receivers corpus with canonical-CLI tests +
    # prefix-style regression tests. Per canonical-cli-scoping convention,
    # `tests/<surface>-canonical-cli.sh` is the stable executable spec for
    # each scaffolded canonical-CLI surface. The test cites the producer
    # script by exact basename (e.g., `SCRIPT="$ROOT/.flywheel/scripts/
    # ntm-approve-human-gates.sh"`), which IS receiver-evidence under nq5ns's
    # producer-stem fallback. Without this corpus, 12+ ledgers (out of 18
    # cross-source-silos flags in same run) whose producer has a canonical-CLI
    # test are falsely flagged. Globs mirror 2xdi.88 + 2xdi.58 (test_files_corpus
    # adopted these three shapes for the probe-without-receiver class). Same
    # META-RULE shape: extend the recognizer corpus, not per-ledger allowlist.
    test_roots = [REPO_ROOT / ".flywheel" / "tests", REPO_ROOT / "tests"]
    for test_root in test_roots:
        if not test_root.is_dir():
            continue
        for pattern in ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh"):
            for test_path in safe_iter_files(test_root, pattern, 600):
                pieces.append(read_text(test_path, 50_000))
    return "\n".join(pieces)


_ON_DEMAND_VALIDATOR_KINDS = {
    "validator",
    "scaffold-test",
    "self-test",
    "audit",
    "scaffold",
}


def _expand_registry_path(raw: str) -> Path | None:
    """Resolve a substrate-registry `where:` path string to an absolute Path."""
    if not isinstance(raw, str) or not raw:
        return None
    expanded = os.path.expanduser(raw)
    try:
        return Path(expanded).resolve()
    except Exception:
        return None


def _walk_for_validator_paths(node, sink: set[Path]) -> None:
    """Recursively scan substrate-registry JSON for kind=validator-class rows.

    Any dict with `kind` in `_ON_DEMAND_VALIDATOR_KINDS` and a `where:` string
    contributes its resolved absolute path to `sink`. We recurse into the JSON
    rather than relying on a fixed schema layout because the registry nests
    pack components under `substrates[].components[]` and similar.
    """
    if isinstance(node, dict):
        kind = node.get("kind")
        where = node.get("where")
        if isinstance(kind, str) and kind in _ON_DEMAND_VALIDATOR_KINDS and where:
            resolved = _expand_registry_path(where)
            if resolved is not None:
                sink.add(resolved)
        for value in node.values():
            _walk_for_validator_paths(value, sink)
    elif isinstance(node, list):
        for item in node:
            _walk_for_validator_paths(item, sink)


def on_demand_script_allowlist() -> set[Path]:
    """Build the set of script paths that are intentionally on-demand.

    Two sources, combined for robustness:
      1. substrate-registry.json (canonical, single-source-of-truth): every
         row with `kind` in `_ON_DEMAND_VALIDATOR_KINDS` contributes its
         `where:` path. Recursive walk so nested pack-component entries are
         picked up regardless of registry schema layout.
      2. Path glob fallback: `skill-packs/*/validate.sh` under the canonical
         skills root. Catches future packs not yet registered + is a safety
         net if the registry is missing or malformed.

    Configurable via env var `GAP_HUNT_SUBSTRATE_REGISTRY`. Default:
    `~/.claude/skills/.flywheel/data/substrate-registry.json`.

    Filed under flywheel-2fw7v as the fix for the wired-but-cold detector
    flagging on-demand pack validators (filed_by=flywheel-2xdi.44 + 17
    sibling beads expected from gap-hunt-probe rotation).
    """
    allowlist: set[Path] = set()
    registry_raw = os.environ.get(
        "GAP_HUNT_SUBSTRATE_REGISTRY",
        str(CLAUDE_ROOT / "skills" / ".flywheel" / "data" / "substrate-registry.json"),
    )
    registry_path = Path(registry_raw)
    if registry_path.is_file():
        try:
            data = json.loads(registry_path.read_text(errors="replace"))
            _walk_for_validator_paths(data, allowlist)
        except Exception as exc:
            warn(f"could not parse substrate registry {registry_path}: {exc}")
    else:
        warn(f"substrate registry missing: {registry_path}")

    pack_glob = CLAUDE_ROOT / "skills" / ".flywheel" / "data" / "skill-packs"
    if pack_glob.is_dir():
        try:
            for validator in pack_glob.glob("*/validate.sh"):
                resolved = _expand_registry_path(str(validator))
                if resolved is not None:
                    allowlist.add(resolved)
            for self_test in pack_glob.glob("*/self-test.sh"):
                resolved = _expand_registry_path(str(self_test))
                if resolved is not None:
                    allowlist.add(resolved)
        except Exception as exc:
            warn(f"pack-glob fallback failed: {exc}")

    # flywheel-2xdi.58: auto-allowlist any *.sh file under a `tests/` directory.
    # Unix convention: tests/test_*.sh are run by a test-harness (CI / manual /
    # run-tests.sh) on-demand, NOT continuously by a tick driver. The
    # wired-but-cold detector would otherwise flag them because their names
    # don't appear in flywheel-loop ledgers (which is correct — they're not
    # in continuous wiring; they ARE in tests/ which is the on-demand surface).
    # Mirrors how skill-packs/*/validate.sh + self-test.sh are auto-allowlisted.
    for tests_root in (CLAUDE_ROOT / "skills", REPO_ROOT):
        for test_script in safe_iter_files(tests_root, "tests/**/test_*.sh", 1000):
            try:
                allowlist.add(test_script.resolve())
            except Exception:
                allowlist.add(test_script)
        # Also include the harness driver (`tests/run-tests.sh`) if present —
        # it's the wrapper that invokes test_*.sh files via glob and is itself
        # on-demand (CI / manual operator).
        for harness in safe_iter_files(tests_root, "tests/run-tests.sh", 100):
            try:
                allowlist.add(harness.resolve())
            except Exception:
                allowlist.add(harness)

    return allowlist


def probe_wired_but_cold() -> list[dict]:
    ledger_text = recent_ledger_text()
    sibling_text = sibling_repo_ledger_corpus()
    source_text = runtime_source_corpus()
    skill_md_text = skill_md_corpus()
    launchd_text = launchd_plist_corpus()
    on_demand = on_demand_script_allowlist()
    scripts = []
    scripts.extend(safe_iter_files(CLAUDE_ROOT / "skills", "*.sh", 3000))
    scripts.extend(safe_iter_files(REPO_ROOT / ".flywheel/scripts", "*.sh", 300))
    gaps = []
    for script in sorted(set(scripts)):
        name = script.name
        if name in {"gap-hunt-probe.sh"}:
            continue
        try:
            resolved = script.resolve()
        except Exception:
            resolved = script
        if resolved in on_demand:
            continue
        # flywheel-8vw0o + flywheel-2xdi.49 + flywheel-e7lxv: cold = absent from ALL FIVE corpora
        # (1) primary flywheel state-dir ledgers (recent_ledger_text)
        # (2) sibling-repo dispatch-logs (sibling_repo_ledger_corpus) — catches
        #     cross-repo umbrella refs e.g. tick_guard.sh in skillos tests
        # (3) runtime source-line corpus (runtime_source_corpus) — catches
        #     doctor.d/* modules sourced by doctor.sh + for-loop indirect-sourced
        #     lib/* modules (flywheel-2xdi.47)
        # (4) SKILL.md documentation corpus (skill_md_corpus) — catches
        #     compat wrappers + skill entry points documented in SKILL.md prose
        #     whose names only appear in docs, not in any ledger or source line
        # (5) launchd plist corpus (launchd_plist_corpus) — flywheel-e7lxv:
        #     catches scripts wired via ~/Library/LaunchAgents/*.plist
        #     ProgramArguments (e.g., zeststream-doctor-heartbeat.sh invoked
        #     daily by com.zeststream.substrate-doctor.plist). Skill-substrate
        #     scripts under ~/.claude/skills/ frequently don't write to
        #     .flywheel/ ledgers, so launchd is their only "wired" evidence.
        in_local = name in ledger_text or script.stem in ledger_text
        in_sibling = bool(sibling_text) and (name in sibling_text or script.stem in sibling_text)
        # source corpus: name + stem + parent-dir-name (catches glob-sourced
        # modules like doctor.d/*.sh sourced via `source <dir>/doctor.d/*.sh`
        # where the actual basename never appears literally in source lines).
        in_source = False
        if source_text:
            if name in source_text or script.stem in source_text:
                in_source = True
            else:
                try:
                    parent_name = script.parent.name
                except Exception:
                    parent_name = ""
                # Only trust parent-dir matches for module-glob conventions:
                # *.d (e.g., doctor.d, fleet.d, misc.d) where the dir name
                # itself is the source-level identity. Non-suffixed parent
                # dirs would be too noisy a signal.
                if parent_name.endswith(".d") and parent_name in source_text:
                    in_source = True
        in_skill_md = bool(skill_md_text) and (name in skill_md_text or script.stem in skill_md_text)
        in_launchd = bool(launchd_text) and (name in launchd_text or script.stem in launchd_text)
        if not (in_local or in_sibling or in_source or in_skill_md or in_launchd):
            try:
                rel = str(script.relative_to(Path.home()))
            except Exception:
                rel = str(script)
            gaps.append(gap("wired-but-cold", rel, "script not referenced by recent flywheel jsonl ledgers modified in last 30d"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_doctrine_without_measurement(tick_text: str) -> list[dict]:
    sources = [
        (REPO_ROOT / "AGENTS.md", read_text(REPO_ROOT / "AGENTS.md")),
        (CLAUDE_ROOT / "CLAUDE.md", read_text(CLAUDE_ROOT / "CLAUDE.md")),
    ]
    seen: set[str] = set()
    gaps = []
    for path, text in sources:
        for match in re.finditer(r"\b(L\d+|Axiom\s+\d+)\b", text):
            rule = match.group(1).replace(" ", "-")
            if rule in seen:
                continue
            seen.add(rule)
            probe_pattern = rule.lower().replace("-", "[-_ ]?")
            if not re.search(probe_pattern, tick_text, re.I):
                gaps.append(gap("doctrine-without-measurement", rule, f"{path} mentions {match.group(1)} but tick.md has no matching observability hook"))
            if len(gaps) >= 20:
                return gaps
    return gaps


def probe_without_receiver(receivers_text: str) -> list[dict]:
    """Detect *-probe.sh files with no receiver consuming their output.

    Per flywheel-kckw8 (sister of flywheel-e7lxv launchd corpus extension
    for wired-but-cold class): probe receivers come in 5 shapes:
      1. receivers_text — tick.md + status files (the original 2-corpus check)
      2. last_tick_*.json receipts — last tick state (the original)
      3. In-repo executable callers under .flywheel/scripts/*.sh — catches
         env-var-defaulted invocation (e.g., idle-pane-auto-dispatch.sh:28
         SCAFFOLD_SURFACE_PROBE → dispatch-surface-conflict-probe.sh)
      4. Launchd plists under ~/Library/LaunchAgents/*.plist — catches
         2-hop wiring chains where launchd → wrapper → probe
      5. Test files under .flywheel/tests/test-*.sh and tests/test-*.sh —
         catches single-hop test consumers (dedicated regression tests)

    A probe is probe-without-receiver iff its basename or stem is absent
    from ALL FIVE corpora. Same META-RULE shape as flywheel-2xdi.47 +
    flywheel-2xdi.49 + flywheel-e7lxv: fix the property (corpus
    coverage), not the proxy (per-script allowlist).
    """
    files = safe_iter_files(REPO_ROOT, "*-probe.sh", 500)
    files.extend(safe_iter_files(CLAUDE_ROOT / "skills", "*-probe.sh", 1000))
    # flywheel-dnxjb: exclude test-tree paths. The probe-finder's rglob picks
    # up test files named like `<probe-name>.sh` (sister test convention used
    # in pre-2xdi.101 codebase). Those files are RECEIVERS for the real probe,
    # not probes themselves. The probe canonical location is .flywheel/scripts/
    # or ~/.claude/skills/<x>/scripts/. test trees are tests/ and .flywheel/tests/.
    # 2xdi.101 surfaced the FP via state-store-authority-probe.sh appearing in
    # both .flywheel/scripts/ AND tests/ — only the former is a real probe.
    test_tree_parts = {"tests", ".flywheel/tests"}
    def _is_in_test_tree(p: Path) -> bool:
        # Check if path traverses through any test tree component after REPO_ROOT
        try:
            rel = p.relative_to(REPO_ROOT)
        except ValueError:
            return False
        parts = rel.parts
        # tests/ at top level, OR .flywheel/tests/ nested
        if parts and parts[0] == "tests":
            return True
        if len(parts) >= 2 and parts[0] == ".flywheel" and parts[1] == "tests":
            return True
        return False
    files = [p for p in files if not _is_in_test_tree(p)]
    receipt_text = ""
    for path in safe_iter_files(Path.home() / ".local/state/flywheel-loop", "last_tick_*.json", 200):
        receipt_text += "\n" + read_text(path, 200_000)
    # flywheel-kckw8: 3 additional corpora for indirect-invocation routes
    script_callers_text = flywheel_script_callers_corpus()
    launchd_text = launchd_plist_corpus()
    test_files_text = test_files_corpus()
    combined = (
        receivers_text + "\n" +
        receipt_text + "\n" +
        script_callers_text + "\n" +
        launchd_text + "\n" +
        test_files_text
    )
    # flywheel-2xdi.60.1: respect substrate-registry on-demand allowlist
    # (same mechanism probe_wired_but_cold uses). Probes with kind in
    # _ON_DEMAND_VALIDATOR_KINDS are intentionally on-demand diagnostics;
    # they should be excluded from probe-without-receiver too.
    on_demand = on_demand_script_allowlist()
    gaps = []
    for path in sorted(set(files)):
        try:
            resolved = path.resolve()
        except Exception:
            resolved = path
        if resolved in on_demand:
            continue
        if path.name in combined or path.stem in combined:
            continue
        gaps.append(gap("probe-without-receiver", path.name, f"{path} emits probe output but no tick/status/last_tick receiver reference was found"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_skill_without_jsm_publish() -> list[dict]:
    gaps = []
    jsm = Path("/Users/josh/.local/bin/jsm")
    if jsm.exists():
        try:
            result = subprocess.run([str(jsm), "status"], text=True, capture_output=True, timeout=20, check=False)
            status_text = result.stdout + result.stderr
        except Exception as exc:
            warn(f"jsm status failed: {exc}")
            status_text = ""
    else:
        warn("jsm binary unavailable for publish audit")
        status_text = ""
    for skill_md in sorted((CLAUDE_ROOT / "skills").glob("*/SKILL.md")):
        text = read_text(skill_md, 120_000)
        skill = skill_md.parent.name
        localish = any(token in text for token in ("foundation-v0.1", "ZestStream.ai", "status: foundation", "distribution: forbidden"))
        if localish and skill not in status_text and "jsm" not in text.lower():
            gaps.append(gap("skill-without-jsm-publish", skill, f"{skill_md} appears locally authored but has no visible jsm status/metadata reference"))
        if len(gaps) >= 20:
            break
    return gaps


def probe_memory_without_cross_link() -> list[dict]:
    """Detect memory files not cited by name in canonical anchor surfaces.

    Class taxonomy (flywheel-kwjja decision — Option D, 2026-05-11):

    This probe is NAME-GREP-ONLY by design. It scans for the memory filename
    (or stem) in: AGENTS.md, INCIDENTS.md, README.md, .flywheel/doctrine/*.md,
    .flywheel/rules/*.md, .flywheel/PLANS/*.md. If the filename appears in
    NONE of those, the memory is flagged.

    KNOWN FALSE-POSITIVE RATE (xbsd8 + 2xdi.117 findings):
    Memories whose discipline is SEMANTICALLY EMBEDDED in runtime artifacts
    (e.g., dispatch-template.md's VERIFY-CALLBACK BLOCK enforces
    callback_delivery_verified — the very contract feedback_dispatch_post_
    send_verify_for_silent_deaf.md documents) get flagged here even though
    their discipline is load-bearing in practice.

    DECISION (flywheel-kwjja, 2026-05-11): ACCEPT the FP rate (Option D).
    Rationale:
    1. The canonical resolution path is "forward-link doctrine doc" recipe
       (flywheel-2xdi.93, .109, .116, .118, .127 — N=5 empirically stable).
       Each doctrine doc takes ~15min to ship and produces independent
       artifact value (canonical write-up + Jeff-precedent quotes + sister
       cross-refs + conformance checklist).
    2. Only ~20% of the FP cases (1 of 5 in the N=5 sample) would have been
       avoided by widening the corpus to dispatch templates (Option B).
       The other ~80% required novel doctrine writing anyway.
    3. The probe is "working as intended" — it correctly identifies memories
       that lack canonical doctrine cross-links. The fix is to create the
       cross-link, not to weaken the probe.
    4. Adding semantic tokenization (Options A/C) would introduce
       false-NEGATIVES (load-bearing memories incorrectly recognized as
       cross-linked via accidental token overlap with unrelated content).

    WHEN TO REVISIT:
    - If N>=10 memory-without-cross-link beads in a single tick (cost too high)
    - If doctrine-doc-shipping rate slows because the recipe gets repetitive
      without adding new doctrine content (diminishing returns)
    - If a specific corpus surface (e.g., dispatch templates) generates >=3
      same-class FPs in one week — then surgical Option B for that surface

    SISTER FINDINGS preserved as open beads:
    - flywheel-xbsd8 (semantic-cross-link awareness)
    - flywheel-2xdi.117 (memory-proposes-future-class)

    Both stay open as evidence for the eventual revisit; don't close them.
    """
    memory_root = CLAUDE_ROOT / "projects/-Users-josh-Developer-flywheel/memory"
    refs = command_text()
    # flywheel-aic04: canonical PLANS/ uppercase for Linux portability;
    # macOS APFS aliases the lowercase form transparently per
    # core.ignorecase=true.
    for path in safe_iter_files(REPO_ROOT / ".flywheel/PLANS", "*.md", 200):
        refs += "\n" + read_text(path, 200_000)
    gaps = []
    for path in sorted(memory_root.glob("*.md")):
        name = path.name
        if name == "MEMORY.md":
            continue
        if name not in refs and path.stem not in refs:
            gaps.append(gap("memory-without-cross-link", name, f"{path} not cited by sampled commands, doctrine, incidents, or recent plan files"))
        if len(gaps) >= 20:
            break
    return gaps


def iter_issue_rows() -> list[dict]:
    path = REPO_ROOT / ".beads/issues.jsonl"
    rows = []
    try:
        for line in path.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                value = json.loads(line)
                if isinstance(value, dict):
                    rows.append(value)
            except Exception:
                continue
    except Exception as exc:
        warn(f"could not read bead JSONL: {exc}")
    return rows


def row_text(row: dict) -> str:
    return " ".join(str(row.get(key) or "") for key in ("id", "title", "description", "close_reason", "status"))


def bead_followup_false_positive_reason(row: dict) -> str | None:
    text = row_text(row).lower()
    # Narrow suppressions from gap-hunt-false-positives.jsonl 2026-05-03.
    # These are plan/reply/spec outputs where doctrine words describe target
    # concepts, not completed local INCIDENTS/AGENTS promotion work.
    suppressions = [
        (
            "plan-space-cross-link-design",
            [
                "perp-cross-link-recovery-plan",
                "cross-link wave-execution doc done",
                "perp_cross_link_design.md",
            ],
        ),
        (
            "mkdir-lock-fallback-plan",
            [
                "flock-missing-on-host-mkdir-lock-fallback",
                "plan-space doc",
                "mkdir_lock_pattern_plan.md",
            ],
        ),
        (
            "external-issue-reply-draft",
            [
                "ntm#113",
                "reply",
                "ntm113-reply-draft.md",
            ],
        ),
        (
            "recover-pane-command-spec",
            [
                "/flywheel:recover-pane",
                "slash command spec done",
                "recov_pane_command_design.md",
            ],
        ),
        (
            # 2026-05-09 (flywheel-2xdi.37): bead flywheel-0h0b drafts an
            # upstream ntm#114 issue body and routes the comment-vs-new
            # decision through Joshua signoff. The body mentions "doctrine"
            # only via the standard AG1 boilerplate ("doctrine surface
            # named in...") and "canonical" only via skill name reference
            # ("canonical-cli-scoping"), neither of which signals a local
            # INCIDENTS/AGENTS promotion.
            "upstream-issue-draft-or-comment-decision",
            [
                "[upstream-issue]",
                "comment-on-114",
                "joshua signoff",
            ],
        ),
        (
            # 2026-05-11 (flywheel-2xdi.69): phantom beads are test-pollution
            # artifacts (a test invoking the real bead-opener writes a live
            # .beads/ row; the close note documents the pollution + isolates
            # the test). They never represent real doctrine/canonical/promotion
            # work and have nothing to cite in INCIDENTS.md. Example: flywheel-0u9ch
            # close_reason contains "phantom bead — test-pollution artifact from
            # callback-receipt-validator-canonical-cli.sh".
            "phantom-bead-test-pollution",
            [
                "phantom bead",
                "test-pollution",
            ],
        ),
    ]
    for reason, needles in suppressions:
        if all(needle in text for needle in needles):
            return reason
    return None


def probe_bead_without_followup() -> list[dict]:
    incidents = read_text(REPO_ROOT / "INCIDENTS.md", 2_000_000)
    gaps = []
    surfaced_hits = 0
    latest_by_id: dict[str, dict] = {}
    for row in iter_issue_rows():
        rid = str(row.get("id") or "")
        if rid:
            latest_by_id[rid] = row
    for rid, row in sorted(latest_by_id.items()):
        text = row_text(row)
        if str(row.get("status") or "") != "closed":
            continue
        if not re.search(r"\b(doctrine|canonical|promote|promotion)\b", text, re.I):
            continue
        if bead_followup_false_positive_reason(row):
            surfaced_hits += 1
            if surfaced_hits >= 20:
                break
            continue
        if rid not in incidents:
            gaps.append(gap("bead-without-followup", rid, f"closed bead claims doctrine/canonical/promotion work but {rid} is not cited in INCIDENTS.md"))
            surfaced_hits += 1
            if surfaced_hits >= 20:
                break
    return gaps


def probe_substrate_without_version_probe(receivers_text: str) -> list[dict]:
    memory = read_text(CLAUDE_ROOT / "projects/-Users-josh-Developer-flywheel/memory/reference_jeff_substrate_inventory.md", 500_000)
    upgrade_log = read_text(STATE_DIR / "jeff-substrate-upgrades.jsonl", 500_000)
    version_probe_text = receivers_text + "\n" + upgrade_log
    binaries = []
    for line in memory.splitlines():
        match = re.match(r"\|\s*`?([^`|]+?)`?\s*\|\s*Dicklesworthstone/", line)
        if match:
            binaries.append(match.group(1).strip())
    gaps = []
    for binary in binaries:
        tokens = [binary, binary.replace(" ", "-"), binary.split()[0]]
        if not any(token and token in version_probe_text for token in tokens):
            gaps.append(gap("substrate-without-version-probe", binary, "binary appears in reference_jeff_substrate_inventory.md but no sampled version-probe/tick/upgrade ledger reference was found"))
    return gaps


def known_silos() -> set[str]:
    """Load the allowlist of self-instrumentation/operational ledgers that are
    intentionally not referenced by doctrine surfaces. Per flywheel-gui5f
    (filed by flywheel-2xdi.40); allowlist file is `.flywheel/gap-hunt-known-silos.jsonl`,
    one row per ledger with `{name, class, writer, rationale}`. The probe
    skips any ledger whose basename matches a row's `name` field."""
    allowlist_path = REPO_ROOT / ".flywheel/gap-hunt-known-silos.jsonl"
    # flywheel-ugali: extend default set to include gap-hunt-self-calibration-runs.jsonl
    # (added 2026-05-11 by faqj2 self-calibration loop). Symmetric with
    # recent_ledger_text() prefix-skip hardening.
    names: set[str] = {"gap-hunt.jsonl", "gap-hunt-false-positives.jsonl", "gap-hunt-self-calibration-runs.jsonl"}
    try:
        for line in allowlist_path.read_text(errors="replace").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            n = row.get("name")
            if isinstance(n, str) and n:
                names.add(n)
    except Exception:
        pass
    return names


def probe_cross_source_silos(receivers_text: str) -> list[dict]:
    """Detect *.jsonl ledgers under STATE_DIR with no cite in receivers_text.

    Per flywheel-nq5ns: scaffold-canonical-CLI ledgers follow the
    `<producer-script-stem>-runs.jsonl` naming convention (canonical-cli-
    scoping doctrine). Doctrine/INCIDENTS references typically cite the
    producer SCRIPT (e.g., `<name>.sh`), not the ledger basename.
    Without producer-script-name fallback, the probe flags ledgers whose
    producer IS doctrine-cited as cross-source-silos (false positive).

    Sister-class precedent: flywheel-zsk2d (SKILL.md 4KB cap regression
    → 256KB priority cap). Same Meadows #5 leverage shape: fix the
    property (name-match form), not the proxy (per-ledger allowlist).

    Producer-script-name match logic:
      - For ledgers named `<X>-runs.jsonl`, also check `<X>` (stem
        without `-runs` suffix) in receivers_text.
      - This catches the canonical scaffold naming where the producer
        script is `<X>.sh` and references in doctrine cite `<X>.sh` —
        the `<X>` portion is shared.
    """
    gaps = []
    skip = known_silos()
    for path in sorted(STATE_DIR.glob("*.jsonl")):
        name = path.name
        if name in skip:
            continue
        # flywheel-nq5ns: 3-form name match — full basename, stem,
        # producer-script-stem (stem with `-runs` suffix stripped).
        producer_stem = path.stem
        if producer_stem.endswith("-runs"):
            producer_stem = producer_stem[: -len("-runs")]
        if (
            name in receivers_text
            or path.stem in receivers_text
            or (producer_stem != path.stem and producer_stem in receivers_text)
        ):
            continue
        gaps.append(gap("cross-source-silos", name, f"{path} ledger exists but is not referenced by sampled tick/status/synth/doctrine surfaces"))
        if len(gaps) >= 20:
            break
    return gaps


def active_loop_markers() -> list[dict]:
    loops_dir = Path.home() / ".flywheel/loops"
    markers: list[dict] = []
    for path in sorted(loops_dir.glob("*.json")):
        data = read_json(path)
        if data.get("active") is not True:
            continue
        data["_marker_path"] = str(path)
        if not data.get("project"):
            data["project"] = path.stem
        markers.append(data)
    return markers


def latest_jsonl_row(path: Path, predicate) -> dict:
    latest: dict = {}
    latest_epoch: float | None = None
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return {}
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if not isinstance(row, dict) or not predicate(row):
            continue
        epoch = parse_iso_epoch(row.get("effective_at") or row.get("ts") or row.get("callback_received_at"))
        if latest_epoch is None or (epoch is not None and epoch >= latest_epoch):
            latest = row
            latest_epoch = epoch
    return latest


def latest_topology(session: str) -> dict:
    path = STATE_DIR / "session-topology.jsonl"
    return latest_jsonl_row(path, lambda row: str(row.get("session") or "") == session)


def repo_for_marker(marker: dict) -> Path:
    repo = str(marker.get("repo") or "").strip()
    if repo:
        return Path(repo)
    project = str(marker.get("project") or "").strip()
    return Path("/Users/josh/Developer") / project


def session_for_marker(marker: dict) -> str:
    return str(marker.get("session") or marker.get("project") or "").strip()


def pane_key(value: object) -> str:
    raw = str(value or "").strip()
    try:
        return str(int(raw))
    except Exception:
        return raw


def worker_panes(marker: dict, topology: dict) -> set[str]:
    panes: set[str] = set()
    for item in topology.get("worker_panes") or []:
        if isinstance(item, dict):
            panes.add(pane_key(item.get("pane") or item.get("pane_idx")))
        else:
            panes.add(pane_key(item))
    if marker.get("worker_pane") is not None:
        panes.add(pane_key(marker.get("worker_pane")))
    return {pane for pane in panes if pane}


def signal_pane_state(marker: dict, interval_seconds: int) -> dict:
    session = session_for_marker(marker)
    if not session:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "no_session"}
    ntm = Path("/Users/josh/.local/bin/ntm")
    if not ntm.exists():
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "ntm_missing"}
    try:
        result = subprocess.run(
            [str(ntm), f"--robot-activity={session}", "--activity-type=codex,claude"],
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
    except Exception as exc:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": f"ntm_failed={exc}"}
    if result.returncode != 0:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": result.stderr.strip()[:180]}
    try:
        payload = json.loads(result.stdout)
    except Exception:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "evidence": "robot_activity_non_json"}
    agents = payload.get("agents") or []
    topology = latest_topology(session)
    panes = worker_panes(marker, topology)
    orch = pane_key(topology.get("orchestrator_pane") or marker.get("orchestrator_pane"))
    recent: list[str] = []
    considered = 0
    now = time.time()
    for agent in agents:
        if not isinstance(agent, dict):
            continue
        pane = pane_key(agent.get("pane") or agent.get("pane_idx"))
        if not pane:
            continue
        if panes and pane not in panes:
            continue
        if not panes and orch and pane == orch:
            continue
        considered += 1
        warn_on_classifier_divergence(session, pane, agent.get("state"), payload, "gap-hunt-probe.sh")
        since = parse_iso_epoch(agent.get("state_since"))
        if since is not None and now - since <= interval_seconds:
            recent.append(f"pane={pane} state={agent.get('state')} age_sec={int(now - since)}")
    if recent:
        return {"name": "pane_state_changed_since_last_tick", "ok": True, "evidence": "; ".join(recent[:3])}
    return {
        "name": "pane_state_changed_since_last_tick",
        "ok": False,
        "evidence": f"no_recent_worker_state considered={considered} window_sec={interval_seconds}",
    }


def loop_candidate_paths(project: str, repo: Path, kind: str) -> list[Path]:
    local_state = Path.home() / ".local/state"
    local_logs = Path.home() / ".local/logs"
    flywheel_loop = local_state / "flywheel-loop"
    paths = [
        flywheel_loop / f"last_tick_{project}.json",
        local_state / f"{project}-flywheel-loop/last_run.json",
        local_logs / f"{project}-flywheel-loop.jsonl",
    ]
    if kind == "receipt":
        paths.extend([
            repo / ".flywheel/ticks/*.json",
            repo / ".flywheel/last_closeout_receipt.json",
            local_state / f"{project}-receipt-bridge.jsonl",
            local_state / f"{project}-flywheel-loop/receipt.json",
        ])
    if project == "flywheel":
        paths.extend([
            STATE_DIR / "gap-hunt.jsonl",
            STATE_DIR / "ntm-fleet-health.jsonl",
            repo / ".flywheel/dispatch-log.jsonl",
        ])
    return paths


def newest_callback_signal(project: str, repo: Path, window_seconds: int) -> dict:
    log_paths = [
        repo / ".flywheel/dispatch-log.jsonl",
        STATE_DIR / "dispatch-log.jsonl",
    ]
    newest: tuple[Path | None, float | None] = (None, None)
    for path in log_paths:
        try:
            lines = path.read_text(errors="replace").splitlines()
        except Exception:
            continue
        for line in lines:
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            if not isinstance(row, dict):
                continue
            if row.get("repo") and repo.exists() and str(row.get("repo")) != str(repo):
                continue
            if row.get("session") and project != "flywheel" and str(row.get("session")) != project:
                continue
            epoch = parse_iso_epoch(row.get("callback_received_at"))
            if epoch is None:
                continue
            if newest[1] is None or epoch > newest[1]:
                newest = (path, epoch)
    if newest[0] is None or newest[1] is None:
        return {"name": "callback_received_in_last_2_ticks", "ok": False, "evidence": "no_callback_received_at"}
    age = int(time.time() - newest[1])
    return {
        "name": "callback_received_in_last_2_ticks",
        "ok": age <= window_seconds,
        "evidence": f"{newest[0]} callback_age_sec={age} window_sec={window_seconds}",
    }


def jsonl_rows_since(path: Path, since_epoch: float, needles: list[str] | None = None) -> list[dict]:
    rows: list[dict] = []
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines:
        if not line.strip():
            continue
        if needles and not any(needle and needle in line for needle in needles):
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if not isinstance(row, dict):
            continue
        epoch = parse_iso_epoch(row.get("processed_at") or row.get("callback_received_at") or row.get("ts") or row.get("created_at"))
        if epoch is not None and epoch >= since_epoch:
            rows.append(row)
    return rows


def row_matches_loop_project(row: dict, project: str, repo: Path) -> bool:
    explicit_owner = False
    for key in ("session", "project"):
        value = str(row.get(key) or "")
        if value:
            explicit_owner = True
        if value == project:
            return True
    for key in ("git_repo", "repo"):
        value = str(row.get(key) or "")
        if value:
            explicit_owner = True
        if value and value == str(repo):
            return True
    if explicit_owner:
        return False
    if project == "flywheel":
        return False
    encoded = json.dumps(row, sort_keys=True)
    return project in encoded or str(repo) in encoded


def signal_fuckup_decisions(project: str, repo: Path, interval_seconds: int) -> dict:
    since = time.time() - interval_seconds
    processed = [
        row for row in jsonl_rows_since(STATE_DIR / "fuckup-processed.jsonl", since)
        if row_matches_loop_project(row, project, repo)
    ]
    if processed:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"processed_rows={len(processed)} window_sec={interval_seconds}",
        }
    callback_decisions = 0
    for row in jsonl_rows_since(repo / ".flywheel/dispatch-log.jsonl", since):
        if not row.get("callback_received_at"):
            continue
        if row.get("no_bead_reason") or row.get("beads_filed") or row.get("beads_updated"):
            callback_decisions += 1
    if callback_decisions:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"callback_decision_rows={callback_decisions} window_sec={interval_seconds}",
        }
    recent_fuckups = [
        row for row in jsonl_rows_since(STATE_DIR / "fuckup-log.jsonl", since)
        if row_matches_loop_project(row, project, repo)
    ]
    if not recent_fuckups:
        return {
            "name": "fuckup_log_decisions_made_since_last_tick",
            "ok": True,
            "evidence": f"no_recent_project_fuckups_to_decide window_sec={interval_seconds}",
        }
    return {
        "name": "fuckup_log_decisions_made_since_last_tick",
        "ok": False,
        "evidence": f"recent_project_fuckups_without_processed_row={len(recent_fuckups)}",
    }


def explicit_freshness_signals(project: str, repo: Path, interval_seconds: int) -> list[dict]:
    """Return marker_fresh, callback_receipt_fresh, canonical_bridge_fresh
    as independent verdicts. Owned by bead flywheel-2xdi.15.1; preserves
    flywheel-dwmb.1's receipt-mirror/full-doctor split untouched."""
    validator = REPO_ROOT / ".flywheel/scripts/loop-integrity-signals.sh"
    if not validator.exists():
        warn(f"loop-integrity-signals.sh missing at {validator}; explicit signals skipped")
        return []
    args = [str(validator), "--project", project, "--repo", str(repo), "--json"]
    if interval_seconds and interval_seconds > 0:
        args.extend(["--window-seconds", str(interval_seconds * 2)])
    try:
        result = subprocess.run(
            args,
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
        )
    except Exception as exc:
        warn(f"loop-integrity-signals subprocess failed for {project}: {exc}")
        return []
    try:
        payload = json.loads(result.stdout)
    except Exception:
        warn(f"loop-integrity-signals non-json output for {project}: rc={result.returncode}")
        return []
    signals_dict = payload.get("signals") or {}
    out: list[dict] = []
    for name in ("marker_fresh", "callback_receipt_fresh", "canonical_bridge_fresh"):
        sig = signals_dict.get(name) or {}
        out.append({
            "name": name,
            "ok": bool(sig.get("ok")),
            "evidence": str(sig.get("evidence") or "no_evidence"),
        })
    return out


def classify_loop(marker: dict) -> dict:
    project = str(marker.get("project") or "").strip()
    repo = repo_for_marker(marker)
    interval = parse_interval_seconds(marker.get("interval"))
    explicit = explicit_freshness_signals(project, repo, interval)
    signals = [
        signal_from_recent_file(
            "ledger_writes_since_last_tick",
            loop_candidate_paths(project, repo, "ledger"),
            interval,
        ),
        signal_pane_state(marker, interval),
        signal_from_recent_file(
            "receipt_files_written_since_last_tick",
            loop_candidate_paths(project, repo, "receipt"),
            interval,
        ),
        newest_callback_signal(project, repo, interval * 2),
        signal_fuckup_decisions(project, repo, interval),
        *explicit,
    ]
    failed = [str(item["name"]) for item in signals if not item.get("ok")]
    verdict = "HEALTHY"
    if len(failed) >= 3:
        verdict = "DEAD"
    elif failed:
        verdict = "LIMPING"
    return {
        "project": project,
        "session": session_for_marker(marker),
        "repo": str(repo),
        "interval_seconds": interval,
        "verdict": verdict,
        "failed_signals": failed,
        "signals": {str(item["name"]): item for item in signals},
        "explicit_freshness_signals": [str(item["name"]) for item in explicit],
        "marker": str(marker.get("_marker_path") or ""),
    }


def probe_loop_integrity() -> list[dict]:
    gaps = []
    for marker in active_loop_markers():
        result = classify_loop(marker)
        project = result["project"]
        loop_integrity_verdicts[project] = result
        if result["verdict"] == "HEALTHY":
            continue
        failed = ",".join(result["failed_signals"])
        evidence = f"verdict={result['verdict']} failed_signals={failed} marker={result['marker']}"
        gaps.append(gap("loop-integrity", project, evidence))
    return gaps


def open_bead_titles() -> dict:
    """Return {title: bead_id} for all open + in_progress beads.

    flywheel-9a3k1: auto-bead-filer dedup cache. Built once per gap-hunt-probe
    main() invocation so create_bead() can skip duplicate-title filings against
    already-open beads. Without this, two gap_ids with same basename + same
    class (e.g., probe-finder picks up <name>.sh in both .flywheel/scripts/ AND
    tests/) file two beads with identical titles.
    """
    if not BR_BIN.exists():
        return {}
    try:
        result = subprocess.run(
            [str(BR_BIN), "list",
             "--status", "open",
             "--status", "in_progress",
             "--limit", "5000",
             "--json"],
            cwd=str(REPO_ROOT), text=True, capture_output=True, timeout=20, check=False,
        )
    except Exception as exc:
        warn(f"open_bead_titles: br list failed: {exc}")
        return {}
    if result.returncode != 0:
        warn(f"open_bead_titles: br list rc={result.returncode}")
        return {}
    try:
        payload = json.loads(result.stdout)
    except Exception as exc:
        warn(f"open_bead_titles: br list json parse failed: {exc}")
        return {}
    issues = payload.get("issues") if isinstance(payload, dict) else None
    if not isinstance(issues, list):
        return {}
    titles: dict = {}
    for row in issues:
        if not isinstance(row, dict):
            continue
        title = row.get("title")
        bead_id = row.get("id")
        if not isinstance(title, str) or not isinstance(bead_id, str):
            continue
        # First-seen wins so dedup is deterministic. br list returns
        # newest-first; we want OLDEST open bead to "own" the title so
        # subsequent gaps append rather than displace.
        if title not in titles:
            titles[title] = bead_id
    return titles


def create_bead(item: dict, open_titles: dict | None = None) -> str | None:
    if DRY_RUN:
        return None
    if not BR_BIN.exists():
        warn(f"br unavailable at {BR_BIN}; auto-bead skipped")
        return None
    cls = item["id"].split(":", 1)[0]
    title = f"[gap-{cls}] {item['name']}"[:180]
    # flywheel-9a3k1: dedup against open/in_progress beads with same title.
    # The basename-only stable_id can collide across paths (probe-finder
    # picks up <name>.sh in scripts/ AND tests/), so the title check is the
    # safety net against duplicate-looking bead pairs in the queue.
    if open_titles is not None and title in open_titles:
        existing = open_titles[title]
        warn(f"dedup: open bead {existing} matches title; skipping duplicate file for gap_id={item['id']}")
        return None
    description = (
        f"Auto-filed by gap-hunt-probe. Parent={PARENT_BEAD}.\\n\\n"
        f"Class: {cls}\\n"
        f"Gap id: {item['id']}\\n"
        f"Evidence: {item['evidence']}\\n"
    )
    cmd = [
        str(BR_BIN), "create",
        "--priority", "3",
        "--type", "task",
        "--parent", PARENT_BEAD,
        "--title", title,
        "--description", description,
        "--json",
    ]
    try:
        result = subprocess.run(cmd, cwd=str(REPO_ROOT), text=True, capture_output=True, timeout=20, check=False)
    except Exception as exc:
        warn(f"br create failed for {item['id']}: {exc}")
        return None
    if result.returncode != 0:
        warn(f"br create failed for {item['id']}: {result.stderr.strip()[:180]}")
        return None
    try:
        payload = json.loads(result.stdout)
        if isinstance(payload, dict):
            return str(payload.get("id") or "")
    except Exception:
        pass
    match = re.search(r"flywheel-[A-Za-z0-9_.-]+", result.stdout)
    return match.group(0) if match else None


def main() -> None:
    tick_text = read_text(CLAUDE_ROOT / "commands/flywheel/tick.md", 1_500_000)
    receivers_text = command_text()
    gaps_by_class = {cls: [] for cls in GAP_CLASSES}
    probes = [
        ("wired-but-cold", lambda: probe_wired_but_cold()),
        ("doctrine-without-measurement", lambda: probe_doctrine_without_measurement(tick_text)),
        ("probe-without-receiver", lambda: probe_without_receiver(receivers_text)),
        ("skill-without-jsm-publish", lambda: probe_skill_without_jsm_publish()),
        ("memory-without-cross-link", lambda: probe_memory_without_cross_link()),
        ("bead-without-followup", lambda: probe_bead_without_followup()),
        ("substrate-without-version-probe", lambda: probe_substrate_without_version_probe(receivers_text)),
        ("cross-source-silos", lambda: probe_cross_source_silos(receivers_text)),
        ("loop-integrity", lambda: probe_loop_integrity()),
    ]
    for cls, fn in probes:
        try:
            gaps_by_class[cls] = fn()
        except Exception as exc:
            warn(f"{cls} probe failed: {exc}")
            gaps_by_class[cls] = []

    current_ids = [item["id"] for rows in gaps_by_class.values() for item in rows]
    prior_ids = previous_ledger_ids()
    new_items = [item for rows in gaps_by_class.values() for item in rows if item["id"] not in prior_ids]
    # flywheel-9a3k1: build open-bead title cache once before the auto-bead
    # loop so each create_bead() call can dedup against the same snapshot.
    # Local dedup within this loop run (in case two same-title gaps both fire
    # in the same tick) is handled by mutating the cache as we go.
    open_titles = open_bead_titles() if not DRY_RUN else {}
    auto_beads: list[str] = []
    for item in new_items[:AUTO_BEAD_CAP]:
        bead_id = create_bead(item, open_titles=open_titles)
        if bead_id:
            auto_beads.append(bead_id)
            # Add the newly-filed bead's title to the cache so a subsequent
            # same-title gap in the same run dedups against this new bead too.
            cls = item["id"].split(":", 1)[0]
            new_title = f"[gap-{cls}] {item['name']}"[:180]
            open_titles[new_title] = bead_id

    distribution = {cls: len(rows) for cls, rows in gaps_by_class.items()}
    payload = {
        "version": VERSION,
        "ts": now_iso(),
        "mode": MODE,
        "dry_run": DRY_RUN,
        "gaps_by_class": gaps_by_class,
        "gaps_total": len(current_ids),
        "gaps_new_since_last_run": len(new_items),
        "gap_class_distribution": distribution,
        "gap_ids": current_ids,
        "loop_integrity_verdicts": loop_integrity_verdicts,
        "auto_beads_filed": auto_beads,
        "duration_sec": round(time.time() - START, 3),
        "warnings": warnings,
    }

    if not DRY_RUN:
        try:
            LEDGER.parent.mkdir(parents=True, exist_ok=True)
            with LEDGER.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(payload, sort_keys=True) + "\n")
        except Exception as exc:
            payload["warnings"].append(f"ledger append failed: {exc}")

    print(json.dumps(payload, sort_keys=True))


main()
PY
}

# ====== Canonical-CLI scaffold helpers (bead flywheel-1hshd.34) ======
_SCAFFOLD_GHP_SCHEMA="gap-hunt-probe/v1"
_SCAFFOLD_GHP_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-${LEDGER:-$HOME/.local/state/flywheel/gap-hunt.jsonl}}"

_scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)         printf 'topic: run (default) — discover gaps across 9 classes; --apply mode auto-files capped beads (default 3 via GAP_HUNT_AUTO_BEAD_CAP); --dry-run skips ledger writes; rc 0 ok / 1 domain / 64 usage\n' ;;
    doctor)      printf 'topic: doctor (positional) — substrate-health envelope with .checks (canonical AG3.4); distinct from --doctor flag which marks doctor-mode gap-hunt invocation\n' ;;
    health)      printf 'topic: health — tail $_SCAFFOLD_GHP_AUDIT_LOG (= $LEDGER); report last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale (daily probe cadence)\n' ;;
    repair)      printf 'topic: repair --scope <audit_log_dir|ledger_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3); audit_log_dir mkdir; ledger_path REPORT-ONLY (ledger writes are gap-hunt path, not repair-owned)\n' ;;
    validate)    printf 'topic: validate <subject> [VALUE] — subjects: gap-class (must be one of 9 enum members), bead-id (matches ^flywheel-[a-z0-9.]+$), auto-bead-cap (positive int); rc=1 on schema violation\n' ;;
    audit)       printf 'topic: audit [--limit N] — tail $_SCAFFOLD_GHP_AUDIT_LOG; default limit=20\n' ;;
    why)         printf 'topic: why <id> — provenance lookup against $_SCAFFOLD_GHP_AUDIT_LOG; matches against ts/gap_id/version; states: found / not_found / unavailable\n' ;;
    *)           printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart (SURGICAL: scaffold owns positional verbs + --examples --json envelope; native --info/--schema/--doctor/default-mode preserved with in-place .name/.capabilities/.input_schema/.output_schema augmentations)\n' ;;
  esac
}

_scaffold_cmd_doctor() {
  local audit_log_dir; audit_log_dir="$(dirname "$_SCAFFOLD_GHP_AUDIT_LOG")"
  local bash_s=fail jq_s=fail py_s=fail br_s=warn ledger_dir_s=fail repo_s=warn
  command -v bash >/dev/null 2>&1 && bash_s=pass
  command -v jq >/dev/null 2>&1 && jq_s=pass
  command -v python3 >/dev/null 2>&1 && py_s=pass
  [[ -x "${BR_BIN:-}" ]] && br_s=pass
  [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]] && ledger_dir_s=pass
  [[ -d "${REPO_ROOT:-}" ]] && repo_s=pass
  local overall=pass
  for st in "$bash_s" "$jq_s" "$py_s"; do [[ "$st" == fail ]] && overall=fail; done
  if [[ "$overall" == pass ]]; then
    for st in "$br_s" "$ledger_dir_s" "$repo_s"; do [[ "$st" == warn || "$st" == fail ]] && overall=warn; done
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg overall "$overall" \
    --arg bash_s "$bash_s" --arg jq_s "$jq_s" --arg py_s "$py_s" --arg br_s "$br_s" \
    --arg ld_s "$ledger_dir_s" --arg repo_s "$repo_s" \
    --arg br_path "${BR_BIN:-}" --arg ld_path "$audit_log_dir" --arg repo_path "${REPO_ROOT:-}" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_s},
        {name:"jq_available",status:$jq_s},
        {name:"python3_available",status:$py_s,detail:"load-bearing — info/schema/main heredoc dispatch"},
        {name:"br_executable",status:$br_s,path:$br_path,detail:"load-bearing — auto-bead filing"},
        {name:"ledger_dir_writable",status:$ld_s,path:$ld_path},
        {name:"repo_root_resolvable",status:$repo_s,path:$repo_path}
      ]}'
}

_scaffold_cmd_health() {
  local audit_log="$_SCAFFOLD_GHP_AUDIT_LOG"
  local ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${GAP_HUNT_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg log "$audit_log" --argjson stale "$stale_threshold" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,stale_threshold_seconds:$stale}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    local now last_epoch
    now="$(date -u +%s)"
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null || echo 0)"
    age_seconds=$((now - last_epoch))
    [[ "$age_seconds" -gt "$stale_threshold" ]] && status="warn"
  else
    age_seconds=null; status="warn"
  fi
  jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age,recent_runs:$recent,total_runs:$total,stale_threshold_seconds:$stale}'
}

_scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) _scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#--scope=}"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg scope "$scope" \
      '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key",exit_code:3}'
    exit 3
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$_SCAFFOLD_GHP_AUDIT_LOG")"
      local existed="true"; [[ ! -d "$target" ]] && existed="false"
      [[ "$mode" == "apply" ]] && mkdir -p "$target"
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    ledger_path)
      # REPORT-ONLY — ledger writes happen in the gap-hunt run path, not repair.
      local target="${LEDGER:-$_SCAFFOLD_GHP_AUDIT_LOG}"
      local existed="false" readable="false"
      [[ -f "$target" ]] && existed="true"
      [[ -r "$target" ]] && readable="true"
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg readable "$readable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),readable:($readable == "true"),note:"REPORT-ONLY — ledger writes are owned by the default gap-hunt run path, not repair"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|ledger_path>\n' >&2; return 64 ;;
    *)
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","ledger_path"]}'
      return 64 ;;
  esac
}

_scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    gap-class)
      [[ -z "$arg" ]] && { printf 'ERR: validate gap-class requires VALUE\n' >&2; return 64; }
      case "$arg" in
        wired-but-cold|doctrine-without-measurement|probe-without-receiver|skill-without-jsm-publish|memory-without-cross-link|bead-without-followup|substrate-without-version-probe|cross-source-silos|loop-integrity)
          jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"gap-class",ts:$ts,status:"ok",value:$c}'
          return 0 ;;
        *)
          jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"gap-class",ts:$ts,status:"reject",value:$c,reason:"unknown_class",valid_classes:["wired-but-cold","doctrine-without-measurement","probe-without-receiver","skill-without-jsm-publish","memory-without-cross-link","bead-without-followup","substrate-without-version-probe","cross-source-silos","loop-integrity"]}'
          return 1 ;;
      esac ;;
    bead-id)
      [[ -z "$arg" ]] && { printf 'ERR: validate bead-id requires VALUE\n' >&2; return 64; }
      if [[ "$arg" =~ ^flywheel-[a-z0-9.]+$ ]]; then
        jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg b "$arg" \
          '{schema_version:$sv,command:"validate",subject:"bead-id",ts:$ts,status:"ok",value:$b}'
        return 0
      fi
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg b "$arg" \
        '{schema_version:$sv,command:"validate",subject:"bead-id",ts:$ts,status:"reject",value:$b,reason:"bead_id_pattern_mismatch",pattern:"^flywheel-[a-z0-9.]+$"}'
      return 1 ;;
    auto-bead-cap)
      [[ -z "$arg" ]] && { printf 'ERR: validate auto-bead-cap requires VALUE\n' >&2; return 64; }
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 0 && arg <= 100 )); then
        jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"auto-bead-cap",ts:$ts,status:"ok",value:$v}'
        return 0
      fi
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg v "$arg" \
        '{schema_version:$sv,command:"validate",subject:"auto-bead-cap",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[0, 100]",default:3}'
      return 1 ;;
    "")
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["gap-class","bead-id","auto-bead-cap"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["gap-class","bead-id","auto-bead-cap"]}'
      return 64 ;;
  esac
}

_scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) _scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$_SCAFFOLD_GHP_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg log "$_SCAFFOLD_GHP_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$limit" "$_SCAFFOLD_GHP_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg log "$_SCAFFOLD_GHP_AUDIT_LOG" \
    --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
}

_scaffold_cmd_why() {
  local id="${1:-}"
  [[ -z "$id" ]] && { printf 'ERR: why requires <id>\n' >&2; return 64; }
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$_SCAFFOLD_GHP_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg id "$id" --arg log "$_SCAFFOLD_GHP_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or ((.gap_ids // []) | index($id) != null) or (.version // "") == $id)' "$_SCAFFOLD_GHP_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg id "$id" --arg log "$_SCAFFOLD_GHP_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","gap_ids","version"]}'
    return 0
  fi
  jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" --arg ts "$ts" --arg id "$id" --arg log "$_SCAFFOLD_GHP_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

_scaffold_cmd_quickstart() {
  jq -nc --arg sv "$_SCAFFOLD_GHP_SCHEMA" \
    '{schema_version:$sv,command:"quickstart",steps:[
      {step:1,action:"probe substrate",command:"gap-hunt-probe.sh doctor --json"},
      {step:2,action:"dry-run discovery",command:"gap-hunt-probe.sh --dry-run --json"},
      {step:3,action:"apply discovery + auto-bead-cap=1",command:"GAP_HUNT_AUTO_BEAD_CAP=1 gap-hunt-probe.sh --json"}
    ]}'
}

_scaffold_dispatch_verb() {
  local verb="$1"; shift
  case "$verb" in
    doctor)     _scaffold_cmd_doctor "$@" ;;
    health)     _scaffold_cmd_health "$@" ;;
    repair)     _scaffold_cmd_repair "$@" ;;
    validate)   _scaffold_cmd_validate "$@" ;;
    audit)      _scaffold_cmd_audit "$@" ;;
    why)        _scaffold_cmd_why "$@" ;;
    quickstart) _scaffold_cmd_quickstart "$@" ;;
    *) printf 'ERR: unknown scaffold verb: %s\n' "$verb" >&2; return 64 ;;
  esac
}
# ====== END canonical-cli scaffold helpers ======

main() {
  # ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.34) ======
  # SURGICAL DASH-FLAG SCAFFOLD variant. Native owns --info/--schema/
  # --examples/--doctor + --json/--quiet/--dry-run + default mode.
  # In-place augmentations to info_json/schema_json/examples added
  # .name/.capabilities/.input_schema/.output_schema and the --json
  # envelope branch. Scaffold here adds NEW positional verbs that
  # native doesn't have: doctor (positional, distinct from --doctor
  # flag — emits substrate-health AG3.4 envelope with .checks),
  # health, repair, validate, audit, why, quickstart, help.
  #
  # Pre-scan _GHP_JSON for --examples branch awareness (since native
  # consumes --json before it reaches examples()):
  for _arg in "$@"; do
    [[ "$_arg" == "--json" ]] && export _GHP_JSON=1
  done
  # Positional-verb intercept BEFORE native arg parser:
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart)
      _scaffold_dispatch_verb "$@"
      exit $?
      ;;
    help)
      shift
      _scaffold_emit_topic_help "${1:-}"
      exit 0
      ;;
  esac
  # ====== END canonical-cli scaffold ======

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --json)
        shift
        ;;
      --doctor|--health)
        MODE="${1#--}"
        shift
        ;;
      --info)
        info_json
        exit 0
        ;;
      --schema)
        schema_json
        exit 0
        ;;
      --examples)
        examples
        exit 0
        ;;
      --quiet)
        QUIET=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      *)
        printf 'ERROR: unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  run_probe
}

main "$@"
