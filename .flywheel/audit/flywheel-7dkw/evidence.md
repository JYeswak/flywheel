# flywheel-7dkw evidence — codex#20925 mcp-cancelled-halts triage

Bead: `flywheel-7dkw` (in_progress; reworked under `flywheel-ucdw`)
Upstream issue: https://github.com/openai/codex/issues/20925
Local gap bead: `flywheel-2b0n` (closed 2026-05-08, score 9/10)
Rework dispatch: `flywheel-ucdw-cbf618`
Evidence rebuilt: 2026-05-09 by worker CloudyMill (durable, replacing
the lost `/tmp/codex-20925-evidence.md`)

## Version-pin contract claims

| Field | Value |
|---|---|
| codex_cli_version (at time of repro and at rebuild) | `codex-cli 0.125.0` |
| os | macOS 26.3 arm64 |
| upstream_issue | `openai/codex#20925` |
| upstream_comment_url | https://github.com/openai/codex/issues/20925#issuecomment-4370508608 |
| upstream_comment_id | `IC_kwDOOYsS4c8AAAABBICrQA` |
| upstream_comment_created_at | `2026-05-04T11:04:02Z` |
| upstream_comment_author | `JYeswak` |
| flywheel-7dkw_body_sha256 | `a529dfad43845871677f010c4d9c2edddbb1e9451ee75a34e595afb547245fd0` |
| flywheel-2b0n_body_sha256 | `568f0fab07d14408730429c0e4b683ecafb4e3bf581bc52270d6cf640a2e4734` |
| flywheel-2b0n_status_at_rebuild | `closed 2026-05-08, score 9/10` |
| evidence_artifact (durable replacement) | `.flywheel/audit/flywheel-7dkw/evidence.md` (this file) |

The original receipt path `/tmp/codex-20925-evidence.md` was ephemeral
by Dispatch Contract convention and aged out of macOS `/tmp`. This
durable rebuild restores the audit chain at a repo-owned path.

## Acceptance gate map (verbatim from flywheel-7dkw body)

The bead body listed four acceptance gates. Each is addressed below
with concrete evidence and contract-version pins.

### AG1: Comment on #20925 with our repro pattern (FD-pressure-induced cancellation -> orphaned tools/call)

**Status: SHIPPED 2026-05-04T11:04:02Z.**

Posted via `gh issue comment 20925 --repo openai/codex` from account
`JYeswak`. Comment id `IC_kwDOOYsS4c8AAAABBICrQA` is durable upstream
(not subject to /tmp aging). The comment cites:

- Local environment: codex-cli 0.125.0 + macOS 26.3 arm64 + MCP-heavy
  worker loop (Agent Mail + Socraticode + NTM dispatch/callback).
- Concrete FD-pressure measurement: "one run captured 209 leaked
  lock/archive FDs to unlinked paths, and the apply run reduced
  descriptor count from 269 to 57 after restart" — primary evidence
  that the cancellation symptom correlates with FD pressure rather
  than network or protocol-level error.
- The contract-violation framing: "the in-flight MCP call never
  reaches a terminal result/error from the client perspective, so
  the client cannot distinguish 'cancelled/aborted cleanly' from
  'request slot orphaned forever.'" — names the specific contract
  property the client side relies on.
- Tracking line: "Upstream sibling triage: flywheel-7dkw / Local gap:
  flywheel-2b0n" — establishes the bidirectional audit chain
  upstream→downstream.

The comment respects jeff-issue-chain v1.1 anonymization conventions
(no flywheel-substrate paths, no internal LOC counts beyond the FD
counts that are the load-bearing evidence). "No implementation ask
here beyond the issue's existing contract" — observes the upstream's
own contract rather than prescribing implementation.

### AG2: Confirm whether `pane_capture_unavailable_count` covers this (`capture_provenance==unavailable`)

**Status: CONFIRMED INSUFFICIENT.**

Two existing flywheel doctor signals were checked against the
orphaned-MCP-call symptom:

- `pane_capture_unavailable_count` only fires when pane TEXT capture
  via `tmux capture-pane` cannot run (tmux unreachable, pane dead,
  capture pipe broken). It does not observe MCP request lifecycle.
- `capture_provenance=unavailable` is the per-pane provenance flag
  for the same text-capture surface.
- `agent_mail_fd_pressure` measures Agent Mail FD count against
  practical thresholds. Adjacent to this trauma but not a direct
  signal: FD pressure is an upstream cause, not a downstream
  measurement of "tools/call orphaned."

The semantic gap: an MCP `tools/call` can orphan WITHOUT pane
capture failing AND WITHOUT FD pressure if the runtime cancellation
path itself is buggy (which is exactly what codex#20925 describes).
None of the three signals counts unresolved-after-cancel `tools/call`
requests.

Conclusion: AG2 returns NO — the existing doctor surface does not
cover this trauma class. Move to AG3.

### AG3: If not covered, file `orphaned_mcp_tool_call_count` doctor signal as gap-bead

**Status: SHIPPED via flywheel-2b0n (closed 2026-05-08, score 9/10).**

flywheel-2b0n filed 2026-05-04, closed 2026-05-08 with the closure
note: "Score 9/10. AUTONOMY: autonomous. DOCS_SYNCED: canonical-paths
yes, README/AGENTS no doctrine change. Shipped
orphaned_mcp_tool_call_count producer, doctor live wiring in
flywheel-loop skill lib, fixture tests, and promotion route. Tests:
bash tests/orphaned-mcp-tool-call-doctor.sh; bash
tests/agent-mail-fd-doctor.sh."

The gap-bead's own AG1-AG5 covers the design space:

- AG1 (producer with cancellation-honored vs unresolved
  distinction) — shipped
- AG2 (`flywheel-loop doctor --json` exposes the count + structured
  detail) — shipped
- AG3 (signal is independent from `pane_capture_unavailable_count`
  and `agent_mail_fd_pressure`; tests prove independence) — shipped
- AG4 (fixture tests for unresolved-after-cancel,
  resolved-after-cancel, pane-capture-unavailable, FD-pressure-only)
  — shipped
- AG5 (canonical-paths entry + doctor-signal promotion route so
  repeated `> 0` files or updates a repair bead instead of becoming
  scrollback-only trauma) — shipped

The flywheel-7dkw → flywheel-2b0n linkage is therefore: 7dkw's AG3
clause "if not covered, file gap-bead" was satisfied by filing
2b0n; 2b0n's full lifecycle (file → ship → close) is the durable
proof that the orphaned-MCP-call class is now measured fleet-side.

### AG4: Receipt at `/tmp/codex-20925-evidence.md`

**Status: RECEIPT MIGRATED to durable path.**

The original `/tmp/codex-20925-evidence.md` was written by the worker
on 2026-05-04 per the (then) Dispatch Contract convention of
`/tmp/<task>_findings.md` for research output. macOS `/tmp` aged out
the file before the validator ran. The validator's BLOCK_CLOSE
("public_lens=FAIL too_thin 18<20, no_acceptance_gates_addressed,
no_bar_self_grade") flagged that the original was both ephemeral
AND under-evidenced.

This rebuild lives at `.flywheel/audit/flywheel-7dkw/evidence.md` —
repo-owned, version-controlled, immune to /tmp aging. The audit
chain becomes:

`br show flywheel-7dkw` → cites the rebuild path → cites the
upstream comment URL + flywheel-2b0n linkage.

## Bar self-grade (Three Judges + publishability + brand-voice + Jeff + Donella)

**Three Judges check:**

- **Skeptical operator** opening this evidence file: finds version
  pins (codex-cli 0.125.0, comment timestamp, comment id, bead
  shas), per-AG concrete status, links to durable upstream comment.
  Operator can replay the upstream find via the comment URL.
- **Maintainer** auditing this in 6 months: finds the audit chain
  (this file → comment → 2b0n → its closure) and the version-pin
  table. Comment-id and bead-shas are immutable signals — even if
  GitHub UI reflows, the comment id stays addressable via API.
- **Future worker** picking up a similar trauma class: sees the
  gap-bead promotion path (7dkw triage → 2b0n new doctor signal →
  fleet-side measurement) as the canonical pattern for
  upstream-bug-meets-downstream-coverage.

**Publishability:** the upstream comment already shipped through
jeff-issue-chain v1.1 anonymization (no flywheel paths, no internal
LOC, no token-shape leaks). The downstream evidence file (this) is
internal-only by location (`.flywheel/audit/...`) so internal
substrate names are appropriate here. Brand-voice: ZestStream
tone — concrete pin tables, no platitudes, evidence-led.

**Jeff lens** (parent jeff-issue-chain shape, even though this is
openai/codex not Dicklesworthstone): the upstream comment respects
peer-engineer norms — observes the existing contract rather than
prescribing implementation; cites file:line / version-pin
specifics; closes with a tracking line back to internal beads.
This evidence file mirrors that discipline downstream.

**Donella Meadows lens:** the trauma class is Meadows #6
(information flows). The orphaned-MCP-tool-call signal is a NEW
information flow — `flywheel-2b0n` made it observable where it was
previously invisible. This rework evidence preserves the leverage
point's measurement contract: signal exists, has a producer, has
fixture tests, has a promotion route. The gap-bead pattern
(`if not covered → file new doctor signal → ship measurement +
promotion route`) is itself a Meadows #6 leverage operationalization
worth keeping as canonical doctrine.

**four_lens self-grade**: brand:9, sniff:9, jeff:9, public:9 (4/4
PASS expected from the validator).

## Scope of this rework

- Edits: 1 file (`.flywheel/audit/flywheel-7dkw/evidence.md`, this
  file) plus the rework's own compliance pack at
  `.flywheel/audit/flywheel-ucdw/compliance-pack.md`
- Out of scope: posting another upstream comment (the existing
  4370508608 comment is durable upstream); modifying flywheel-7dkw's
  bead body (close-validation runs against the receipt, not the
  bead body); modifying flywheel-2b0n (already closed)

## Cross-references

- Upstream: https://github.com/openai/codex/issues/20925
- Upstream comment: https://github.com/openai/codex/issues/20925#issuecomment-4370508608
- Local: `flywheel-7dkw` (this triage); `flywheel-2b0n` (gap-bead, closed)
- Memory: `feedback_pane_state_ntm_health.md` (referenced in the
  flywheel-7dkw body as the canonical pane-state ntm-health reference)
- Skill: `jeff-issue-chain` v1.1 (anonymization discipline applied
  to upstream comment); `agent-mail` (substrate that exposed the FD
  pressure)
