## L121 — LAUNCHD-SERIALIZE-WRAPPERS-MUST-BE-KILL-RESILIENT

---
id: L121
title: Launchd serialize wrappers must be kill resilient
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: jsm-wrapper-killed-mid-sync-via-kickstart
---

Launchd-managed shell wrappers that supervise a subprocess capable of holding a
SQLite lock, WAL write channel, file lock, queue lease, or similar mutation
boundary MUST install TERM, INT, and EXIT cleanup before fleet use.

**How to apply:**
- Use `~/.claude/skills/.flywheel/scripts/sigterm-trap-helper.sh` or an
  equivalent wrapper contract before spawning the child.
- TERM/INT cleanup forwards termination to the child, waits up to a bounded
  timeout, performs WAL/state recovery, emits a structured JSONL event, and
  uses forced kill only as a last resort.
- EXIT cleanup removes stale state and catches orphaned child cleanup paths.
- `flywheel doctor` exposes the helper's launchd-managed script scan as the
  `sigterm_trap_missing_count` invariant.

**Forbidden outputs:**
- Calling a launchd serialize wrapper production-ready without TERM, INT, and
  EXIT cleanup.
- Restarting a wrapper with a hard kill path when a graceful restart path or
  trap-supervised wrapper exists.
- Treating WAL checkpoint recovery as JSM-specific; the invariant applies to
  any launchd wrapper supervising mutation-capable subprocesses.

**Evidence:** proposal
`~/.claude/skills/.flywheel/proposals/K-jsm-wrapper-killed-mid-sync-via-kickstart-2026-05-06.md`;
skillos artifacts `state/jsm-wrapper-sigterm-handler-2026-05-06.json` and
`tests/unit/test_jsm_wrapper_sigterm_handler.sh`; canonical helper
`~/.claude/skills/.flywheel/scripts/sigterm-trap-helper.sh`; test
`~/.claude/skills/.flywheel/tests/test_sigterm_trap_helper.sh`.

