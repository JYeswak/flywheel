## L87 — STALE-ERROR-TEXT-AUTO-PING-RECOVERY

---
id: L87
title: Stale error text auto-ping recovery
status: temporary
shipped: 2026-05-04
sunset_when:
  bead: flywheel-pp1g
review_due: 2026-06-04
trauma_class: ntm-classifier-stale-error-poisoning
---

Until upstream `ntm` resolves stale error text classification, flywheel may
use a bounded no-op ping recovery for panes whose live activity row is
`state=ERROR` only because stale `failed_text` or `api_error` remains in
scrollback above a current `codex_chevron_prompt`.

**How to apply:**
- Detect candidates with `.flywheel/scripts/stale-error-auto-ping.sh --json`.
  Default mode is dry-run and writes no pane input.
- Candidates must satisfy all four facts: `capture_provenance=="live"`,
  `state=="ERROR"`, detected patterns include `codex_chevron_prompt`, and
  detected patterns include `failed_text` or `api_error`.
- Only use `--apply` from a watcher or operator loop after the dry-run output
  lists the candidate pane. Apply sends a no-op ping with `--no-cass-check`,
  then rechecks activity and reports `post_recheck_candidate_count`.
- A true fresh error remains `ERROR` after recheck and must not be counted as
  recovered. Repeated failures should stay visible to idle-state and callback
  validation probes rather than being hidden by the recovery layer.

**Forbidden outputs:**
- Treating stale error auto-ping as an upstream fix. It is a temporary
  flywheel-side recovery layer.
- Sending pings to panes without live capture provenance.
- Sending pings to non-ERROR panes, unavailable captures, or panes missing the
  current Codex chevron prompt.
- Reporting idle watcher health without citing the auto-ping dry-run/apply
  receipt when this recovery was used.

**Evidence:** bead `flywheel-pp1g`; upstream `ntm` issue filed for stale
error-pattern priority; workaround script
`.flywheel/scripts/stale-error-auto-ping.sh`; tests
`tests/stale-error-auto-ping.sh`; receipt `/tmp/ntm-stale-error-evidence.md`.

**Companion rules:** L29 (NTM-only pane I/O), L50 (Socraticode survey), L60
(doctor signal shape), L67 (truth source must be live), L71
(validate-and-redispatch discipline), L80 (DID/DIDNT/GAPS callbacks), and L85
(idle state class canonical).

