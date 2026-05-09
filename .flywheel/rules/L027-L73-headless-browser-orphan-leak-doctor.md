## L73 — HEADLESS-BROWSER-ORPHAN-LEAK-DOCTOR

---
id: L73
title: Headless browser orphan leak doctor
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: headless-browser-orphan-leak
---

Headless `agent-browser-chrome` processes are a flywheel resource leak, not a
normal Chrome failure. Any browser-control surface that creates an
`agent-browser-chrome-*` user-data-dir MUST have a teardown path or be covered
by the shared doctor/reap contract.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `.agent_browser_leak` and
  `.headless_agent_browser_count`.
- Doctor status fails when `headless_agent_browser_count > 5` or
  `oldest_age_minutes > 60`.
- `.flywheel/scripts/headless-browser-reap.sh` defaults to dry-run and only
  targets processes whose command or user-data-dir contains
  `agent-browser-chrome`; the primary Chrome profile remains out of scope.
- Applied reaps append receipts to
  `~/.local/state/flywheel/headless-browser-reaps.jsonl`.
- `doctor-signal-bead-promotion.sh` promotes the doctor field to
  `[auto-doctor:headless_browser]` instead of leaving orphan browser leaks as
  manual cleanup work.

**Forbidden outputs:**
- Telling Joshua to restart Chrome before proving whether orphaned
  `agent-browser-chrome` processes hold the singleton lock.
- Killing broad `Google Chrome` process patterns without proving the target
  uses an `agent-browser-chrome-*` profile.
- Reporting the leak fixed without a before/after probe and a doctor field.

**Evidence:** bead `flywheel-3ck3`; scripts
`.flywheel/scripts/headless-browser-probe.sh` and
`.flywheel/scripts/headless-browser-reap.sh`; tests
`tests/headless-browser-probe.sh`.

**Companion rules:** L60 (doctor signal contract), L61 (wire docs and canonical
paths), L70 (chain repair instead of punting), L71 (validate/redispatch before
calling browser cleanup shipped), L72 (resource leak class sibling).


