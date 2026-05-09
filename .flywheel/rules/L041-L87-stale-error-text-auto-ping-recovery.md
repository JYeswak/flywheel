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

**Status update 2026-05-09 (flywheel-vkw88):** Upstream `ntm` issue
[#118](https://github.com/Dicklesworthstone/ntm/issues/118) is CLOSED. Jeffrey
Emanuel landed the fix in commit `4c176e92`
(`fix(robot/activity): debounce CategoryError to live-window when an idle
prompt is present (#118)`). Local `ntm` clone at `/Users/josh/Developer/ntm`
HEAD `7d1fc78e` contains `4c176e92` (`git merge-base --is-ancestor 4c176e92
HEAD` exits 0). Sunset gate `flywheel-pp1g` is CLOSED 2026-05-08 with
the fallback test (`tests/stale-error-auto-ping.sh`) passing 7/7.

This rule **remains live (`status: temporary`)** because the binary
installed at `/Users/josh/.local/bin/ntm` cannot prove it includes the
fix: `ntm version dev / commit: none / built: unknown / builder: unknown`.
Until a fresh build with `Makefile` ldflags (`make build` from the local
clone yields `commit=<sha>`) replaces the installed binary AND the
`tests/stale-error-auto-ping.sh` fixture re-runs against the rebuilt
binary, the recovery layer stays as fallback. Retirement is
Joshua-gated and routes through follow-up bead — see the
`flywheel-vkw88` audit pack for the gated checklist.

