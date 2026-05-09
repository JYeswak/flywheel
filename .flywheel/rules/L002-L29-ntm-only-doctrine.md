## L29 — NTM-only doctrine

---
id: L29
title: NTM-only doctrine — never operational tmux for pane I/O
status: long_term
shipped: 2026-04-30
review_due: 2027-04-30
trauma_class: dispatch-substrate
---

**Rule:** All pane operations (send, capture, list, save, grep, health, spawn, kill) MUST route through `ntm` verbs. The underlying terminal multiplexer binary is forbidden in operational substrate. Positive-only instruction — never name the wrong tool in deny messages, examples, or cautionary guidance (negation amplifies salience).

**How to apply:**
- Send to a pane → `ntm send <session> --pane=<n> "..."`
- Capture pane → `ntm copy <session>:<pane> -l <N>`
- Search pane → `ntm grep <session> <pattern>`
- Health check → `ntm health <session>`
- Save snapshot → `ntm save <session>`
- All of the above also via `/flywheel:ntm <verb>` slash surface

**Why:** agents have huge pretraining bias toward the underlying multiplexer name and near-zero on `ntm`. Without active reinforcement (positive-only doctrine + ambient slash surface + intent-detection gate), every agent regresses to the wrong tool every session. The `flywheel-loop-dispatch-transport-gate.sh` denies direct underlying-multiplexer-binary dispatch invocations.

**Evidence:** 2026-04-30 audit found 7+ active `~/.claude/{commands,skills,hooks}/` paths still using direct multiplexer calls; pane 2 audit log at `/tmp/picoz-pane2-flywheel-install-audit.md` Section A.7. Cleanup is bd-cwfs2 substep 8 + ongoing.

