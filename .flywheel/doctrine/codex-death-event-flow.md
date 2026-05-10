---
title: "Codex Death-Event Flow"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# Codex Death-Event Flow

Version: `codex-death-event-flow/v1`
Owner: fleet-death RCA monitor
Status: canonical, shipped 2026-05-10
Source bead: `flywheel-b2zpg` (parent: `flywheel-ukm9f` AG3-AG6)

## The Pipe

```
codex-deathtrap-launcher.sh
  │
  ▼  on codex exit (any cause)
~/.local/state/flywheel/codex-death-evidence/
  exit_evidence-<pid>-<ts>.json    (the receipt)
  stderr-<pid>-<ts>.log            (the captured stderr)
  args-<pid>-<ts>.txt              (the launch args)
  │
  ▼  every 5 min via launchd (ai.zeststream.codex-death-classifier)
codex-death-event-classifier.sh
  │   reads receipts, sha256-keys idempotency,
  │   classifies per H1/H2/H3/H4,
  │   appends a ledger row.
  ▼
~/.local/state/flywheel/codex-death-classifier-ledger.jsonl
  │
  ▼  on H2 / H3
br create  →  fleet-death-rca disposition bead (P1 / P2)
```

## Hypothesis Matrix

| ID | Rule | Files bead | Default priority | Meaning |
|---|---|---|---|---|
| H1_silent_clean_exit | `exit_code==0` AND `stderr_byte_count==0` | no | — | Codex returned cleanly with no error output. Non-event; ledger only. |
| H2_real_error_with_stderr | `exit_code!=0` AND `stderr_byte_count>0` | yes | P1 | Real error with diagnostic output. Triage upstream or local mitigation. |
| H3_tmux_misreport | `exit_code!=0` AND `stderr_byte_count==0` | yes | P2 | Failure with no diagnostic — strong tmux/runtime misreport signal. |
| H4_warn_but_successful | `exit_code==0` AND `stderr_byte_count>0` | no | — | Codex exited 0 but emitted stderr. Surface as informational only. |
| unclassifiable | malformed receipt | no | — | Receipt unreadable or invalid JSON. Counted in `errors`. |

The H1/H2/H3 split comes verbatim from `flywheel-ukm9f` AG5. H4 was added so
the classifier covers the full 2×2 truth table without dropping data.

## Decoupling

**The classifier never watches a running PID.** It is data-driven: it polls
the evidence dir every 5 minutes (launchd `StartInterval=300`, `KeepAlive=false`,
`RunAtLoad=false`). New receipts are processed once; the sha-256 of each
receipt is the idempotency key, not the path or filename.

This decoupling means the launcher (parent `flywheel-ukm9f`) and the
classifier (this bead) can ship and version independently. The launcher
emits `codex-deathtrap-launcher.v1` receipts; the classifier emits
`codex-death-event-classifier.v1` ledger rows.

## Operational Surfaces

```bash
# Process new receipts (default; launchd target).
.flywheel/scripts/codex-death-event-classifier.sh run --json

# Operator view + health.
.flywheel/scripts/codex-death-event-classifier.sh doctor --json
.flywheel/scripts/codex-death-event-classifier.sh health --json

# Re-classify one receipt without ledger write.
.flywheel/scripts/codex-death-event-classifier.sh validate <path> --json

# Last 10 ledger rows + summary by hypothesis.
.flywheel/scripts/codex-death-event-classifier.sh audit --json

# What would repair propose for un-bead-filed H2/H3 rows?
.flywheel/scripts/codex-death-event-classifier.sh repair --dry-run --json

# Classification matrix and surface metadata.
.flywheel/scripts/codex-death-event-classifier.sh info
.flywheel/scripts/codex-death-event-classifier.sh schema
```

## Anti-Patterns

| Do not | Why | Do this instead |
|---|---|---|
| Watch the launcher PID directly | Brittle, requires lifecycle coupling | Wait for the receipt — the launcher always emits one on EXIT. |
| Use filename as idempotency key | A receipt rewritten in place would silently re-process | Use `evidence_sha256` (content hash). |
| Run the classifier in `KeepAlive=true` | Wastes cycles, masks long-running scan bugs | Use `StartInterval=300` and let launchd schedule one-shots. |
| File a bead for H1 | Clean exits are not events worth surfacing | Record-only in ledger; let audit summarize. |
| Treat H4 as success | Stderr without exit-fail may still mask a real warning | Surface in audit, do not auto-bead. |

## Test Surface

`.flywheel/tests/test-codex-death-event-classifier.sh` covers:

- All four hypotheses (H1/H2/H3/H4) via synthetic fixtures.
- Idempotency: second `run` finds 0 new rows.
- `audit` emits group counts; `doctor` and `health` agree on `pending=0`.
- Malformed receipt produces `unclassifiable` row + `errors=1` + rc=4.
- Introspection trio (info / examples / schema / help) all valid.

## Sister Surfaces

- `.flywheel/scripts/codex-deathtrap-launcher.sh` — the producer of evidence.
- `.flywheel/handoffs/handoff-2026-05-01T1356Z-fleet-overnight-death.md` —
  prior fleet-death RCA context.
- `flywheel-ukm9f` close note — provides the H1/H2/H3 taxonomy this
  classifier consumes.
- `feedback_data_decides_not_human_meatpuppet` — the rationale for a
  data-driven classifier instead of a Joshua-gated decision step.

## Bead-Filing Policy

Default policy:

- H2 → `br create --type bug --priority P1` titled
  `[fleet-death-rca] codex worker death classified H2_real_error_with_stderr`.
- H3 → `br create --type bug --priority P2` titled the same with H3 suffix.
- H1, H4 → ledger-only.

Override with `--no-bead-filing` (classifier still writes ledger).
`--dry-run` prevents both ledger writes and bead-filing.

The body of each filed bead names the receipt path, sha-256, host, label,
exit code, stderr bytes, hypothesis, and reason — enough for any worker to
pick up the disposition without re-deriving classification.

## L61 Touch Points

This doctrine touches `doctrine/`. It does NOT touch `INCIDENTS.md`,
`AGENTS.md`, or any L-rule. The classifier is a new substrate scoped to its
own dir/ledger/launchd surface; existing canonical surfaces are unchanged.
