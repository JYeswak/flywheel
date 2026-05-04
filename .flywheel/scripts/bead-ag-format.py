#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

SCHEMA_VERSION = "bead-ag-format/v1"

TESTABLE_VERBS = {
    "add", "adds", "block", "blocks", "canonize", "canonizes",
    "canonicalize", "canonicalizes", "cover", "covers", "create",
    "creates", "detect", "detects", "document", "documents", "emit",
    "emits", "enforce", "enforces", "exist", "exists", "expose", "exposes", "fail", "fails",
    "flag", "flags", "include", "includes", "link", "links", "pass",
    "passes", "produce", "produces", "read", "reads", "reject", "rejects",
    "require", "requires", "return", "returns", "run", "runs", "surface",
    "surfaces", "support", "supports", "update", "updates", "validate",
    "validates", "warn", "warns", "write", "writes",
}

ARTIFACT_HINT = re.compile(
    r"(`[^`]+`|\.flywheel/|tests/|scripts/|templates/|README\.md|AGENTS\.md|INCIDENTS\.md|doctor signal|field|JSON|CLI|command|path|file)",
    re.I,
)


def _issue(kind, code, message, line_no=None, gate_id=None):
    item = {"kind": kind, "code": code, "message": message}
    if line_no is not None:
        item["line"] = line_no
    if gate_id is not None:
        item["gate_id"] = gate_id
    return item


def validate_description(description):
    lines = description.splitlines()
    in_section = False
    gates = []
    errors = []
    warnings = []
    seen = set()
    last_gate = None

    for idx, line in enumerate(lines, start=1):
        stripped = line.strip()
        if re.match(r"^#{1,6}\s+.+", stripped) and in_section and not re.search(r"acceptance gates?", stripped, re.I):
            break
        if re.search(r"acceptance gates?", stripped, re.I):
            in_section = True
            continue
        if not in_section or not stripped:
            continue

        gate = re.match(r"^AG([1-9][0-9]*):\s+(.+)$", stripped)
        if gate:
            gate_id = f"AG{gate.group(1)}"
            text = gate.group(2).strip()
            gates.append({"id": gate_id, "number": int(gate.group(1)), "text": text, "line": idx})
            seen.add(gate_id)
            last_gate = gate_id
            words = {w.lower() for w in re.findall(r"[A-Za-z][A-Za-z0-9_-]*", text)}
            if not words.intersection(TESTABLE_VERBS):
                warnings.append(_issue("warning", "ag_without_testable_verb", "AG line lacks a testable verb", idx, gate_id))
            if not ARTIFACT_HINT.search(text):
                warnings.append(_issue("warning", "ag_without_artifact_hint", "AG line lacks an artifact, command, file, path, JSON field, or doctor-signal hint", idx, gate_id))
            continue

        if re.match(r"^(?:[-*]\s*)?AG[0-9]+[A-Za-z][.:)]", stripped):
            errors.append(_issue("error", "nested_or_suffix_ag", "AG IDs must be AG1, AG2, ... with no suffixes", idx, last_gate))
            continue
        if re.match(r"^(?:[-*]\s*)?(?:[0-9]+[.)]|AG[0-9]+[.)])\s+", stripped):
            errors.append(_issue("error", "noncanonical_ag_numbering", "Use exact `AG<N>: <single-line assertion>` numbering", idx, last_gate))
            continue
        if stripped.startswith(("-", "*")) or line[:1].isspace():
            errors.append(_issue("error", "nested_ag_content", "Acceptance gates must be single-line assertions; nested bullets/continuations are not canonical", idx, last_gate))
            continue
        if gates:
            errors.append(_issue("error", "ag_continuation_line", "Acceptance gates must not use continuation prose after an AG line", idx, last_gate))

    if not in_section:
        errors.append(_issue("error", "missing_acceptance_gates_section", "Bead body must include an Acceptance gates section with canonical AG lines"))
    elif not gates:
        errors.append(_issue("error", "acceptance_gates_section_without_ag_lines", "Acceptance gates section contains no canonical AG lines"))
    for expected, gate in enumerate(gates, start=1):
        if gate["number"] != expected:
            errors.append(_issue("error", "ag_sequence_gap", f"Expected AG{expected}, found {gate['id']}", gate["line"], gate["id"]))
    if len(seen) != len(gates):
        errors.append(_issue("error", "duplicate_ag_id", "Duplicate AG IDs are not canonical"))

    status = "pass"
    if errors:
        status = "fail"
    elif warnings:
        status = "warn"
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "gate_count": len(gates),
        "gates": gates,
        "errors": errors,
        "warnings": warnings,
    }


def main(argv):
    parser = argparse.ArgumentParser(description="Validate canonical bead acceptance-gate format.")
    parser.add_argument("--description")
    parser.add_argument("--description-file")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--warn-only", action="store_true")
    args = parser.parse_args(argv)

    if args.description_file:
        description = Path(args.description_file).read_text()
    elif args.description is not None:
        description = args.description
    else:
        description = sys.stdin.read()

    result = validate_description(description)
    if args.json:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        for item in result["errors"] + result["warnings"]:
            location = f":{item['line']}" if "line" in item else ""
            print(f"{item['kind'].upper()}{location} {item['code']}: {item['message']}")
        print(f"status={result['status']} gate_count={result['gate_count']}")
    if result["errors"] and not args.warn_only:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
