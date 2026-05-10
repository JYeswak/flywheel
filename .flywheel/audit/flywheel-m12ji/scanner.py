"""Mutation-gate-ordering audit scanner v2 (fixed regexes)."""
import os
import re
import sys
from pathlib import Path


# Gate patterns (looser to catch the actual shell shapes used in the fleet).
GATE_PATTERNS = [
    re.compile(r'cli_refuse_apply_without_idem_key'),
    re.compile(r'\$mode.*==.*"apply".*&&.*-z'),
    re.compile(r'\$apply_mode.*&&.*-z'),
    re.compile(r'\$\{?apply\}?\s*=\s*true.*-z'),
    # explicit refusal envelope shape (when surface emits its own JSON refusal)
    re.compile(r'reason"\s*:\s*"--apply requires --idempotency-key"'),
]

# Side-effect patterns.
SIDE_EFFECT_PATTERNS = [
    # Redirected output to a real path (not /dev/null, not piped, not heredoc to tmp)
    re.compile(r'>\s*"\$\{?(?!_?tmp|WORK_TMP|tmp_dir|tmp_)\w+'),
    re.compile(r'>>\s*"\$\{?(?!_?tmp|WORK_TMP|tmp_dir|tmp_)\w+'),
    # File ops with real destination (excluding tmp_dir staging)
    re.compile(r'\bcp\s+(?!--help|-h\b)(?!.*"\$tmp_)'),
    re.compile(r'\bmv\s+(?!--help|-h\b)(?!.*"\$tmp_)'),
    re.compile(r'\brm\s+-rf?\b(?!.*"\$tmp_)'),
    re.compile(r'\bsed\s+-i'),
    # mkdir / chmod / touch outside tmp
    re.compile(r'\bmkdir\s+-p\s+"\$\{?(?!_?tmp|WORK_TMP|tmp_dir)'),
    re.compile(r'\bchmod\s+(?!.*"\$tmp_|.*"\$WORK_TMP)'),
    re.compile(r'\btouch\s+(?!--help)(?!.*"\$tmp_)'),
    # git mutating
    re.compile(r'\bgit\s+(commit|push|reset\s+--hard|rebase|cherry-pick)'),
]

# Apply-block opener patterns.
APPLY_BLOCK_OPENER = [
    re.compile(r'if\s+\[\[\s+"\$mode"\s*==\s*"apply"\s*\]\]'),
    re.compile(r'if\s+\[\[\s+"\$\{?mode:?-?\}?"\s*==\s*"apply"\s*\]\]'),
    re.compile(r'if\s+\[\[\s+"\$apply_mode"\s*==\s*true\s*\]\]'),
    re.compile(r'if\s+\[\[\s+\$\{?mode\}?\s*==\s*"?apply"?\s*\]\]'),
]


def classify(path: Path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return "NA_unreadable", {"err": str(e)}
    lines = text.splitlines()

    gate_lines = []
    side_effect_lines = []
    apply_block_lines = []

    for i, line in enumerate(lines, 1):
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith("//"):
            continue
        for p in APPLY_BLOCK_OPENER:
            if p.search(line):
                apply_block_lines.append(i)
                break
        for p in GATE_PATTERNS:
            if p.search(line):
                gate_lines.append(i)
                break
        for p in SIDE_EFFECT_PATTERNS:
            if p.search(line):
                side_effect_lines.append((i, line.strip()[:140]))
                break

    has_helper = any('cli_refuse_apply_without_idem_key' in lines[g - 1] for g in gate_lines)

    if not gate_lines and not apply_block_lines:
        return "NA_no_apply_logic", {"reason": "no apply-mode logic detected"}

    if not gate_lines:
        return "NEEDS_REVIEW_no_gate", {
            "reason": "apply-mode block(s) found but no idempotency-key gate",
            "apply_block_lines": apply_block_lines[:5],
            "side_effect_lines": [(i, s) for (i, s) in side_effect_lines[:5]],
        }

    first_gate = min(gate_lines)
    suspicious = []
    for (line_no, sample) in side_effect_lines:
        prior_apply_blocks = [b for b in apply_block_lines if b < line_no]
        if line_no < first_gate and prior_apply_blocks:
            suspicious.append((line_no, sample, prior_apply_blocks[-1]))

    if suspicious:
        return "VIOLATION", {
            "first_gate_line": first_gate,
            "suspicious_side_effects": suspicious,
            "all_gate_lines": gate_lines[:5],
            "all_apply_block_lines": apply_block_lines[:5],
        }

    if has_helper:
        return "CLEAN_HELPER", {
            "gate_line": first_gate,
            "n_gates": len(gate_lines),
            "reason": "uses cli_refuse_apply_without_idem_key from helper-lib",
        }

    return "CLEAN", {
        "first_gate_line": first_gate,
        "n_gates": len(gate_lines),
        "n_side_effects": len(side_effect_lines),
    }


def main():
    candidates = [Path(p.strip()) for p in sys.stdin if p.strip()]
    results = []
    for path in candidates:
        verdict, ev = classify(path)
        results.append({"path": str(path), "verdict": verdict, "evidence": ev})

    summary = {}
    for r in results:
        summary[r["verdict"]] = summary.get(r["verdict"], 0) + 1

    print("=== SUMMARY ===")
    for v, c in sorted(summary.items()):
        print(f"  {v}: {c}")
    print()

    print("=== VIOLATIONS (gate fires AFTER mutation side-effect) ===")
    n_viol = 0
    for r in results:
        if r["verdict"] == "VIOLATION":
            n_viol += 1
            print(f"\n{r['path']}")
            print(f"  first_gate_line: {r['evidence']['first_gate_line']}")
            for (line_no, sample, prior_block) in r["evidence"]["suspicious_side_effects"]:
                print(f"  L{line_no}  (under apply-block opened at L{prior_block})")
                print(f"      {sample}")
    if n_viol == 0:
        print("  (none)")

    print()
    print("=== NEEDS_REVIEW (apply block, no gate found) ===")
    n_nr = 0
    for r in results:
        if r["verdict"] == "NEEDS_REVIEW_no_gate":
            n_nr += 1
            print(f"\n{r['path']}")
            ev = r["evidence"]
            print(f"  apply_block_lines: {ev['apply_block_lines']}")
            for (line_no, sample) in ev["side_effect_lines"]:
                print(f"  L{line_no}  {sample}")
    if n_nr == 0:
        print("  (none)")

    import json
    out_path = os.environ.get("AUDIT_JSON_OUT", "/tmp/m12ji-audit.json")
    with open(out_path, "w") as f:
        json.dump({"summary": summary, "results": results}, f, indent=2)


if __name__ == "__main__":
    main()
