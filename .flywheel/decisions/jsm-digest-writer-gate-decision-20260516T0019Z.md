# Decision: JSM digest writer gate

ts: 2026-05-16T00:19:11Z
source_cycle: goal-mode-worker-test cycle 614
status: active
related_act_receipt: /tmp/goal-mode-worker-test-cycle-613-jsm-digest-writer-repair/receipt.json
related_handoff: .flywheel/handoffs/20260516T001715Z-from-flywheel-to-skillos-jsm-digest-writer-repair.md

## Decision

`/Users/josh/.local/bin/claude-jsm-daily-sync.sh --diagnose` remains
diagnostic-only. It must capture marker and DB-integrity state without writing
`~/.local/state/jsm/digest.md`.

`/Users/josh/.local/bin/claude-jsm-daily-sync.sh --apply` is the digest writer
path, but it writes `digest.md` only after all of these gates pass:

- explicit `--idempotency-key`;
- guarded runner exists;
- no prior receipt with `raw_live_jsm_used == true`;
- sandbox marker is fresh;
- manifest path exists;
- SQLite pre/post integrity checks return `ok`.

If the marker is stale or expired, apply exits blocked and leaves the digest
mtime unchanged.

## Why

The `jsm-digest-freshness` handoff proved the stale digest was not a
SkillOS-side receipt-flow gap: diagnostics succeeded, receipt flow exists, and
the digest rollup stayed stale. The missing substrate was a real writer path
behind the same marker and integrity boundary that protects raw JSM surfaces.

## Verification From Cycle 613

- Fixture apply with a temporary SQLite DB and fresh marker fixture wrote a
  digest and returned `mutation_surface:"digest_writer"`.
- Production apply returned `blocked` with
  `reason:"invalid_sandbox_auth_marker"` and `marker.status:"stale"`.
- Production digest mtime stayed `2026-05-07T19:24:05Z` before and after the
  blocked production apply.
- `bin/skillos doctor --scope jsm-digest-freshness --json` remained `FAIL`,
  which is expected until SkillOS refreshes the guarded marker and the writer
  is re-run.

## Reuse

Use this boundary for future digest-style wrappers: diagnostic commands may
collect evidence, while writer commands must be explicitly named, idempotent,
marker-gated, integrity-checked, and mtime-verifiable.
