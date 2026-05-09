## L140 — DISPATCH-AND-VERIFY-MANDATORY

---
id: L140
title: Every worker-pane dispatch must verify a live work signal
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: codex-chevron-stuck-on-dispatch
---

Every worker-pane dispatch MUST go through
`.flywheel/scripts/dispatch-and-verify.sh` OR an equivalent post-send delivery
postcheck (per `/flywheel:dispatch` Step 5b). A successful `ntm send` exit
code is NOT proof of submission. Pane state showing `THINKING` immediately
after send is NOT proof by itself. Proof requires post-send pane-state probing
plus at least one live-work signal: positive activity velocity, an `ntm changes`
delta after the dispatch baseline, or, in permissive mode, a pane-content delta
after the post-send baseline while the pane reports a working state. `STUCK`
requires two consecutive stuck reads before the wrapper fires empty Enter.

**Forbidden orchestrator pattern:**

```bash
FLYWHEEL_DISPATCH_WRAPPER=1 /Users/josh/.local/bin/ntm send "$SESSION" --pane="$PANE" "$WORKER_PROMPT"
```

**Canonical orchestrator pattern:**

```bash
.flywheel/scripts/dispatch-and-verify.sh --probe-mode=permissive "$SESSION" "$PANE" "/tmp/dispatch_${TASK_ID}.md"
DISPATCH_VERIFIED_RC=$?
if [[ $DISPATCH_VERIFIED_RC -ne 0 ]]; then
  exit 4
fi
```

**Why:** A raw `ntm send` to a codex pane can land in the prepared chevron
buffer without submitting. The orchestrator records `dispatch_status=send_ok`
while the worker never starts. The wrapper waits up to 30s + 15s + 15s for
live evidence, accepts slow-start codex work that changes pane content or files
before velocity turns positive, fires empty Enter only after hysteresis, and
fails closed with diagnostics. Without it, the loop appears active but produces
no accretion.

**Evidence:** finding 2026-05-08T15:50Z — three flywheel:2/3/4 dispatches via
raw ntm send; two of three sat in chevron buffer requiring manual Enter from
Joshua. Doctrine: `.flywheel/doctrine/loop-non-accretive-trauma-class.md`.
Wrapper: `.flywheel/scripts/dispatch-and-verify.sh`. False-negative fix:
bead `flywheel-erkab`, test `tests/dispatch-and-verify.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L130, L70, L116, L120.

