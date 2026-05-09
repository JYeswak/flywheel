## L123 — L29-RAW-TMUX-HISTORICAL-DEBT-MUST-BE-DOCTOR-VISIBLE

---
id: L123
title: L29 raw tmux historical debt must be doctor visible
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: dispatch-substrate
---

L29 gate installation is incomplete until existing raw pane-I/O debt is scanned
and surfaced through doctor. Forward gates block new raw operational tmux use;
they do not prove pre-gate scripts, hooks, commands, or repo-local helpers are
clean.

**How to apply:**
- Run `~/.claude/skills/.flywheel/scripts/raw-tmux-audit-doctor.sh --doctor
  --json` across hooks, commands, `scripts/`, and `.flywheel/scripts/`.
- Classify findings as `replace-with-ntm`, `ratchet-via-gate`,
  `accept-with-receipt`, or `test-fixture`.
- File migration beads for `replace-with-ntm`; add in-file receipts for
  legitimate `accept-with-receipt` read-only probes where no ntm verb exists.
- `flywheel doctor` exposes `l29_raw_tmux_operational_violations_count` and
  keeps historical debt visible while the fleet migrates.

**Forbidden outputs:**
- Treating the raw tmux gate as proof existing files are clean.
- Dispatching or documenting worker-pane operation through raw tmux verbs when
  an ntm equivalent exists.
- Hiding raw tmux debt in prose-only audit notes without a doctor-visible count.

**Evidence:** skillos artifact
`/Users/josh/Developer/skillos/state/skillos-L29-promotion-authoring-2026-05-06.md`;
audit receipt `state/skillos-33v8-l29-raw-tmux-audit-2026-05-06.json`;
canonical scanner `~/.claude/skills/.flywheel/scripts/raw-tmux-audit-doctor.sh`;
test `~/.claude/skills/.flywheel/tests/test_raw_tmux_audit_doctor.sh`.

