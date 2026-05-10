"""No-idempotency-key audit scanner.

Bead: flywheel-7axmt (sister to flywheel-m12ji).
Bug class: surfaces with --apply flag but NO --idempotency-key flag.
Question: does the absence of the gate represent a bug, or is the surface
read-only / naturally idempotent / gated by other means?

Verdict taxonomy (per-surface):

- APPLY_IS_READ_ONLY     — `--apply` is a no-op flag (legacy, unused), or all
                            writes target tmp/scratch/dev-null. No mutation.
                            CLEAN. No fix needed.
- APPLY_IS_IDEMPOTENT    — Mutation is naturally idempotent (mkdir -p,
                            atomic-write to receipt that overwrites, append-only
                            log row with sha-dedupe). CLEAN. No fix needed.
- APPLY_HAS_OTHER_GATE   — Has dry-run-by-default with explicit --apply
                            requirement, external lock, --confirm prompt, or
                            other safety mechanism. CLEAN. No fix needed.
- APPLY_NEEDS_KEY        — Has --apply that triggers non-idempotent mutation
                            with NO compensating gate. BUG class. Needs fix:
                            add --idempotency-key + canonical refusal.

Method: regex-heuristic per-file classification. Spot-check 10 surfaces
manually to validate the heuristic accuracy (matches m12ji methodology).
"""
import re
import sys
from pathlib import Path


# Where --apply is read.
APPLY_FLAG_PATTERNS = [
    re.compile(r'apply\)\s+(?:apply=1|mode="?apply"?)', re.IGNORECASE),
    re.compile(r'--apply\)'),
    re.compile(r'-{1,2}apply\b'),
]

# Where mutation happens (non-tmp writes).
MUTATION_PATTERNS = [
    # Redirect to non-tmp absolute or repo-relative path
    re.compile(r'>\s*"\$\{?(?!_?[Tt][Mm][Pp]|WORK_TMP|tmp_dir|TMPDIR|tmpfile|tmp_file|TMP_)\w+'),
    re.compile(r'>>\s*"\$\{?(?!_?[Tt][Mm][Pp]|WORK_TMP|tmp_dir|TMPDIR|tmpfile|tmp_file|TMP_)\w+'),
    # cp / mv / rm of non-tmp targets
    re.compile(r'\bcp\s+(?!.*"\$tmp_|.*"\$TMP|.*--help)'),
    re.compile(r'\bmv\s+(?!.*"\$tmp_|.*"\$TMP|.*--help)'),
    re.compile(r'\brm\s+(?:-rf?|-f)\s+(?!.*"\$tmp_|.*"\$TMP|.*"\$WORK_TMP)'),
    # in-place editing
    re.compile(r'\bsed\s+-i\b'),
    # mkdir -p outside tmp (note: mkdir -p is idempotent so flagged separately)
    re.compile(r'\bmkdir\s+-p\s+"\$\{?(?!_?[Tt][Mm][Pp]|WORK_TMP|tmp_dir|TMPDIR)'),
    # git mutations
    re.compile(r'\bgit\s+(?:commit|push|reset\s+--hard|checkout\s+--|merge|rebase|tag|branch\s+-D)\b'),
    # plistlib / plist write
    re.compile(r'plistlib\.dump\b'),
    # python file writes
    re.compile(r'\.write_text\b'),
    re.compile(r'\.write_bytes\b'),
    re.compile(r"open\s*\([^)]+,\s*['\"][wax][b]?['\"]"),
]

# Patterns that suggest mutation is naturally idempotent.
IDEMPOTENT_HINTS = [
    re.compile(r'\bmkdir\s+-p\b'),
    re.compile(r'\bln\s+-sfn?\b'),
    re.compile(r'\bcp\s+(?:-f|--force)\b'),
    re.compile(r'atomic_replace\b'),
    re.compile(r'\bos\.replace\b'),
    re.compile(r'\.tmp[\'"]'),
    re.compile(r'with\s+tempfile\.'),
    re.compile(r'append-only', re.IGNORECASE),
    re.compile(r'jsonl', re.IGNORECASE),
    # Hash-stable write-if-changed pattern (sha256 → skip if unchanged)
    re.compile(r'write_if_changed\b'),
    re.compile(r'write_if_diff\b'),
    re.compile(r'if_changed\b'),
    # Doc-comment marker that explicitly claims idempotency
    re.compile(r'idempotent[:\s_-]', re.IGNORECASE),
    # Backup-before-write pattern (mitigates re-run risk somewhat)
    re.compile(r'backup[-_]before[-_]write', re.IGNORECASE),
    re.compile(r'\.bak\b'),
]

# Patterns that suggest another gate.
OTHER_GATE_HINTS = [
    re.compile(r'--confirm\b'),
    re.compile(r'flock\b'),
    re.compile(r'read\s+-r?\s+\w+.*[Yy]/[Nn]'),
    re.compile(r'--force\b'),
    re.compile(r'CONFIRM_DELETE'),
    re.compile(r'dry-run-by-default', re.IGNORECASE),
    re.compile(r'\bWORKER_DRY_RUN\b'),
    re.compile(r'\bDRY_RUN_ONLY\b'),
]

# Patterns suggesting --apply is no-op / legacy / docs-only.
APPLY_NO_OP_HINTS = [
    re.compile(r'#.*--apply.*(?:no-op|legacy|unused|compat|placeholder)', re.IGNORECASE),
    re.compile(r'apply=\w+\s+#.*(?:ignored|no-op|legacy)', re.IGNORECASE),
]


def classify(path):
    """Return (verdict, evidence_strings)."""
    try:
        text = Path(path).read_text(encoding='utf-8', errors='replace')
    except Exception as exc:
        return "READ_ERROR", [f"exc={exc}"]

    lines = text.splitlines()
    apply_lines = []
    mutation_lines = []
    idempotent_lines = []
    other_gate_lines = []
    apply_no_op_lines = []

    for i, line in enumerate(lines, 1):
        # Skip comments-only assessment unless they're flag definitions
        for pat in APPLY_FLAG_PATTERNS:
            if pat.search(line):
                apply_lines.append((i, line.strip()[:100]))
                break
        for pat in MUTATION_PATTERNS:
            if pat.search(line):
                mutation_lines.append((i, line.strip()[:100]))
                break
        for pat in IDEMPOTENT_HINTS:
            if pat.search(line):
                idempotent_lines.append((i, line.strip()[:100]))
                break
        for pat in OTHER_GATE_HINTS:
            if pat.search(line):
                other_gate_lines.append((i, line.strip()[:100]))
                break
        for pat in APPLY_NO_OP_HINTS:
            if pat.search(line):
                apply_no_op_lines.append((i, line.strip()[:100]))
                break

    evidence = []
    if apply_lines:
        evidence.append(f"apply_flag_lines={len(apply_lines)}")
    if mutation_lines:
        evidence.append(f"mutation_lines={len(mutation_lines)}")
    if idempotent_lines:
        evidence.append(f"idempotent_hints={len(idempotent_lines)}")
    if other_gate_lines:
        evidence.append(f"other_gate_hints={len(other_gate_lines)}")
    if apply_no_op_lines:
        evidence.append(f"apply_no_op_hints={len(apply_no_op_lines)}")

    # No apply flag found? Surface might use a different flag name.
    if not apply_lines:
        return "NO_APPLY_FLAG_FOUND", evidence

    # Explicit no-op markers win.
    if apply_no_op_lines:
        return "APPLY_IS_READ_ONLY", evidence

    # If apply present but no mutations found, treat as read-only.
    if not mutation_lines:
        return "APPLY_IS_READ_ONLY", evidence

    # Strong idempotent hints + at most weak mutation = idempotent
    # Heuristic: ratio of idempotent hints to mutation lines >= 0.5
    if idempotent_lines and len(idempotent_lines) * 2 >= len(mutation_lines):
        return "APPLY_IS_IDEMPOTENT", evidence

    # Other gate present.
    if other_gate_lines:
        return "APPLY_HAS_OTHER_GATE", evidence

    # Apply + mutations + no compensating signal = needs key.
    return "APPLY_NEEDS_KEY", evidence


def main(argv):
    if len(argv) < 2:
        print("usage: scanner.py <candidates-file>", file=sys.stderr)
        return 64
    candidates_file = argv[1]
    rows = []
    with open(candidates_file) as fh:
        for line in fh:
            path = line.strip()
            if not path:
                continue
            verdict, evidence = classify(path)
            rows.append({"path": path, "verdict": verdict, "evidence": evidence})

    # Print rows
    counts = {}
    for row in rows:
        counts[row["verdict"]] = counts.get(row["verdict"], 0) + 1
        print(f"{row['verdict']:30s} {row['path']:75s} {' '.join(row['evidence'])}")

    print()
    print("=== verdict summary ===")
    for v, c in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {v:30s} {c}")
    print(f"  TOTAL                          {len(rows)}")

    # Emit JSON sidecar
    import json
    out_path = Path(candidates_file).parent / "audit-results.json"
    with open(out_path, "w") as fh:
        json.dump({"bead": "flywheel-7axmt", "rows": rows, "counts": counts, "total": len(rows)}, fh, indent=2)
    print(f"  wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
