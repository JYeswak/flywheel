## L83 — FILE-LENGTH-DISCIPLINE-FLEET-WIDE

---
id: L83
title: File length discipline fleet-wide
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: monolithic-file-debt-accumulating
---

Every flywheel-installed repo MUST surface file-length debt mechanically before
monoliths become operational risk. Canonical thresholds are owned by
`~/.claude/skills/canonical-cli-scoping/SKILL.md`: bash/shell 500 lines,
Python 400 lines, Rust 500 lines, and doctrine/docs Markdown 1500 lines.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `oversized_files_count`,
  `oversized_files`, and `file_length`.
- `.flywheel/scripts/file-length-probe.sh --repo <repo> --json` is the
  canonical probe for threshold checks.
- More than 3 oversized files triggers
  `doctor-signal-bead-promotion.sh` to create or match a
  `[auto-doctor:monolithic_file_debt]` bead.
- Legitimate exceptions require an in-file receipt:
  `canonical-cli-scoping-allow-large: <reason>`. Generated code, reviewed
  doctrine archives, and migration archives are acceptable reasons; silent
  exceptions are not.
- Shell files route to sourced libraries or thin dispatchers; Python files
  route to `python-best-practices`; Rust files route to `rust-best-practices`.

**Forbidden outputs:**
- Adding more behavior to an already oversized operational script without a
  split plan, explicit large-file receipt, or follow-up bead.
- Calling a CLI or loop substrate maintainable while its implementation file is
  over threshold and invisible to doctor.
- Treating docs as exempt when they are active operating doctrine rather than
  deliberate archives.

**Evidence:** bead `flywheel-useh`; probe
`.flywheel/scripts/file-length-probe.sh`; tests `tests/file-length-probe.sh`;
worst offender `~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Companion rules:** L61 (doctrine landing), L70 (same-tick chain-forward),
L71 (validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS callbacks), and
L82 (canonical CLI scoping).

