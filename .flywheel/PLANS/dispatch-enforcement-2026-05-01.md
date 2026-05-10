---
title: "Dispatch Enforcement Plan"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Dispatch Enforcement Plan

Task: `flywheel-8i5`
Status: plan-space design only
Date: 2026-05-01
Scope: make bypass of `/flywheel:dispatch`, topology lookup, callback contract, L50/L51 fields, and NTM-only transport mechanically harder.
Non-goals: implementation, commits, hook installation, Agent Mail reservations, Socraticode.

## 1. Trauma Class Inventory

Source bead body was read directly from `/Users/josh/Developer/flywheel/.beads/beads.db` because `br` was unavailable on PATH. Bead `flywheel-8i5` names these eight origin classes.

| Class | Evidence path | Cost | INCIDENTS promotion |
|---|---|---|---|
| `dispatch-bypasses-flywheel-dispatch-skill` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:112` | Raw `ntm send` skipped worker-tick prompt, callback contract, dispatch-log row, courtesy ping, and topology lookup. | Yes: `/Users/josh/Developer/flywheel/INCIDENTS.md:286-315` (`bypass-canonical-substrate-cluster`) |
| `callback-pane-wrong-no-topology-read` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:113` | DONE callback sent to picoz pane 0 instead of topology-declared pane 1, so active orchestrator did not process it. | Yes: `/Users/josh/Developer/flywheel/INCIDENTS.md:286-315` |
| `tmux-capture-bypasses-ntm-health` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:111` | Raw `tmux capture-pane` bypassed NTM telemetry and Joshua had to correct the transport. | Yes: `/Users/josh/Developer/flywheel/INCIDENTS.md:286-315` and related meat-puppet cluster |
| `dispatch-file-reservation-skipped` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:106` | Worker edited and committed a file with `files_reserved=NONE` despite L51 reservation requirement. | No; processed into bead `flywheel-8i5` |
| `dispatch-socraticode-unavailable` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:83` | Worker callback had `socraticode_queries=0` because the dispatch required L50 but tool availability was missing. | No; processed into bead `flywheel-8i5` |
| `dispatch-callback-indexed-chunks-unknown` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:108` | Callback reported `indexed_chunks_observed=unknown`, making L50 non-machine-checkable. | No; processed into bead `flywheel-8i5` |
| `convergence-audit-bypass-codex-workers` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:79` | Convergence review waves used background agents instead of codex workers, losing the expected worker substrate. | No; processed into bead `flywheel-8i5` |
| `orch-hardcoded-pane-zero-for-picoz` | `/Users/josh/.local/state/flywheel/fuckup-log.jsonl:76` | Orchestrator sent 4+ picoz messages to pane 0 after current topology declared pane 1. | No; processed into bead `flywheel-8i5` |

## 2. Current Dispatch Path

Read inputs:
- `/Users/josh/.claude/commands/flywheel/dispatch.md`
- `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`
- `/Users/josh/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`

Current shape:
- `dispatch.md` already says to read topology, use `ntm health`, wrap with `_shared/dispatch-template.md`, write `/tmp/dispatch_<id>.md`, send via `/Users/josh/.local/bin/ntm send`, log to `.flywheel/dispatch-log.jsonl`, and send Agent Mail courtesy ping.
- `_shared/dispatch-template.md` already tells workers to look up callback pane from topology and send callbacks through absolute `ntm`.
- The extant transport hook blocks `tmux send-keys` worker dispatches and retired `ntm assign --auto --watch`, but it explicitly does not block canonical `ntm send`.

```mermaid
flowchart TD
    A[Orchestrator decides work exists] --> B{Uses /flywheel:dispatch?}
    B -->|yes| C[Read session-topology.jsonl]
    B -->|no| X1[Bypass: dispatch-bypasses-flywheel-dispatch-skill]
    C --> D[Check pane state: ntm health primary]
    D --> E{Uses raw tmux capture?}
    E -->|yes| X2[Bypass: tmux-capture-bypasses-ntm-health]
    E -->|no| F[Resolve task body: file/bead/inline]
    F --> G[Wrap with _shared/dispatch-template.md]
    G --> H{Callback pane resolved from topology?}
    H -->|no| X3[Bypass: callback-pane-wrong-no-topology-read / orch-hardcoded-pane-zero-for-picoz]
    H -->|yes| I{L50/L51 fields included?}
    I -->|no| X4[Bypass: socraticode/reservation/indexed_chunks contract drift]
    I -->|yes| J[Write /tmp/dispatch_<id>.md]
    J --> K[/Users/josh/.local/bin/ntm send session --pane=N prompt]
    K --> L[Append dispatch-log.jsonl receipt]
    L --> M[Worker executes and sends callback]
    M --> N{Callback has numeric required fields?}
    N -->|no| X5[Bypass: callback contract not machine-checkable]
    N -->|yes| O[Orchestrator reaps callback]
```

Observed bypass points are marked `X1`-`X5`.

## 3. Proposed Enforcement Points

### A. `dispatch-bypasses-flywheel-dispatch-skill`

Enforcement: PreToolUse hook gate `dispatch_skill_required`.

Design:
- Match Bash commands that contain `/Users/josh/.local/bin/ntm send` or `ntm send`, a `--pane` argument, and worker-dispatch language such as `Read /tmp/dispatch_`, `execute it as /flywheel:worker-tick`, `worker-tick parity`, or `Callback: task_id`.
- Allow only if one of these is true:
  - env `FLYWHEEL_DISPATCH_WRAPPER=1` is present;
  - the command writes a dispatch receipt with `dispatch_skill_version`;
  - `JOSHUA_OVERRIDE` passes the shared override check.
- Deny reason: "Use /flywheel:dispatch or set wrapper receipt; raw ntm send lacks topology and callback contract."

Patch target:
- Add gate to `/Users/josh/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh` after command extraction and before the existing canonical-transport allow comment.
- Add `/flywheel:dispatch` step that exports `FLYWHEEL_DISPATCH_WRAPPER=1` only around the one canonical `ntm send`.

### B. `callback-pane-wrong-no-topology-read`

Enforcement: PreToolUse hook gate `topology_lookup_required`.

Design:
- Match `ntm send <session> --pane=<N>` in dispatch or callback context.
- Read latest row for `<session>` from `/Users/josh/.local/state/flywheel/session-topology.jsonl`.
- If command appears to be a callback (`Callback:` or `DONE`/`BLOCKED` with task id), require `N == (.callback_pane // .orchestrator_pane)`.
- If command appears to be a worker dispatch, require `N` not equal to `human_pane`, `orchestrator_pane`, or `callback_pane`.
- Log both expected and actual pane to hook-blocks JSONL.

Patch target:
- Add helper `_topology_expected_pane session mode`.
- Add explicit `topology_resolved_pane` to dispatch-log row.

### C. `tmux-capture-bypasses-ntm-health`

Enforcement: PreToolUse hook gate `ntm_only_pane_state`.

Design:
- Match `tmux capture-pane` in cwd under a flywheel-initialized repo or when command includes known NTM sessions.
- Deny if used for pane state during dispatch/tick unless paired in the same command with prior `/Users/josh/.local/bin/ntm health <session>` and marked supplementary.
- For non-dispatch debugging, allow but log SOFT violation `pane_state_via_tmux_capture`.

Patch target:
- Extend the existing hook beyond `tmux send-keys` to `tmux capture-pane`.
- Add `/flywheel:tail` or `/flywheel:status` reminder in denial.

### D. `dispatch-file-reservation-skipped`

Enforcement: skill body change plus callback-contract doctor invariant.

Design:
- In `_shared/dispatch-template.md`, add required callback fields:
  - `files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS>`
  - `files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS>`
- In `/flywheel:dispatch`, require task author to declare `edits_expected=true|false|unknown`. If true or unknown, template includes L51 reservation block. If worker lacks Agent Mail tool, callback must be `BLOCKED` or `DONE files_reserved=NONE_TOOL_UNAVAILABLE no_source_edits=true`.
- Doctor invariant scans last N dispatch callbacks and flags source-edit tasks with `files_reserved=NONE`.

Patch target:
- `_shared/dispatch-template.md` callback contract.
- Future `flywheel-loop doctor` field: `dispatch_contract_violations.file_reservation[]`.

### E. `dispatch-socraticode-unavailable`

Enforcement: skill body change plus dispatch preflight.

Design:
- `/flywheel:dispatch` must classify tasks:
  - `socraticode_required=true` for non-trivial repo analysis/edits;
  - `socraticode_required=false` only when dispatch explicitly says no Socraticode due known incident/diagnostic.
- Template requires callback fields:
  - `socraticode_queries=N`
  - `indexed_chunks_observed=N`
  - `socraticode_unavailable_reason=<tool_missing|explicit_no_socraticode|none>`
- If required and tool unavailable, worker must callback `BLOCKED` unless the dispatch declares a no-Socraticode exception.

Patch target:
- `dispatch.md` task classification step.
- `_shared/dispatch-template.md` callback examples.

### F. `dispatch-callback-indexed-chunks-unknown`

Enforcement: callback-contract-required gate.

Design:
- A callback sent via `ntm send` containing `Callback:` or `DONE` must not include `indexed_chunks_observed=unknown`.
- If `socraticode_queries` is present, `indexed_chunks_observed` must be an integer.
- If Socraticode was explicitly disabled, require `socraticode_queries=0 indexed_chunks_observed=0 socraticode_unavailable_reason=explicit_no_socraticode`.

Patch target:
- New hook gate `callback_contract_required` for outgoing callbacks.
- Doctor invariant for dispatch-log callback rows missing numeric L50 fields.

### G. `convergence-audit-bypass-codex-workers`

Enforcement: skill body change.

Design:
- `/flywheel:dispatch` gets `worker_substrate=codex-pane|claude-pane|background-agent|local`.
- For convergence/adversarial review waves, require `worker_substrate=codex-pane` unless `JOSHUA_OVERRIDE`.
- Template should include `agent_type=codex` and log `agent_type` in dispatch receipt.
- A PreToolUse/UserPromptSubmit soft gate catches prompts mentioning convergence audit plus background agents and suggests codex pane dispatch.

Patch target:
- `dispatch.md` worker selection section.
- Dispatch-log schema adds `agent_type` and `worker_substrate`.

### H. `orch-hardcoded-pane-zero-for-picoz`

Enforcement: topology-lookup-required gate plus receipt schema.

Design:
- No command may send to `picoz --pane=0` in dispatch/callback context if latest topology says `callback_pane=1` or `orchestrator_pane=1`.
- Dispatch receipt must include:
  - `topology_row_effective_at`
  - `topology_resolved_pane`
  - `topology_role=worker|callback|orchestrator`
- Hook denies hard-coded pane mismatches and prints the current topology values.

Patch target:
- Same topology helper as B.
- `_shared/dispatch-template.md` line that says "Do not hardcode pane indexes" becomes a hard callback example using jq.

## 4. Receipt Schema

Canonical destination: `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl`.

Required fields for `event="dispatch_sent"`:

```json
{
  "schema_version": 2,
  "event": "dispatch_sent",
  "task_id": "string",
  "bead": "string|null",
  "ts": "iso8601",
  "from": "string",
  "to": "string",
  "pane": 4,
  "session": "flywheel",
  "task_summary": "string",
  "task_file": "/tmp/dispatch_<task_id>.md",
  "agent_type": "codex|claude|unknown",
  "worker_substrate": "codex-pane|claude-pane|background-agent|local",
  "pane_state_source": "ntm_health",
  "pane_state_secondary_source": "pane-state.sh|ntm_copy|none",
  "pane_state_disagreement": false,
  "topology_resolved_pane": 4,
  "topology_role": "worker",
  "topology_row_effective_at": "iso8601|null",
  "dispatch_skill_version": "flywheel-dispatch/v2",
  "callback_session": "flywheel",
  "callback_pane": 1,
  "callback_expected_by": "iso8601",
  "callback_received_at": null,
  "callback_status": null,
  "socraticode_required": true,
  "file_reservation_required": true,
  "task_sha256": "hex",
  "channel": "ntm"
}
```

Required callback update fields:
- `callback_received_at`
- `callback_status`
- `socraticode_queries`
- `indexed_chunks_observed`
- `files_reserved`
- `files_released`
- `beads_filed` or `beads_updated` or `no_bead_reason`
- `fuckups_logged` for BLOCKED or trauma-bearing DONE

## 5. Backwards Compatibility Audit

Command run:

```bash
tail -50 /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl | jq -s '{rows:length, ...}'
```

Last 50 row audit:

| Field | Missing rows |
|---|---:|
| `task_id` | 6 |
| `task_file` | 19 |
| `session` or `target_session` | 18 |
| `pane` or `target_pane` | 17 |
| `callback_pane` | 27 |
| `callback_expected_by` | 19 |
| `callback_received_at` key | 18 |
| `agent_type` | 47 |
| `pane_state_source` | 47 |
| `dispatch_skill_version` | 50 |
| `topology_resolved_pane` | 50 |

Implication: strict enforcement cannot apply retroactively. It must be versioned and only hard-block new `schema_version >= 2` dispatches after the wrapper ships.

Migration path:
1. Add schema v2 receipt fields to `/flywheel:dispatch`.
2. Add doctor warning, not error, for old rows missing v2 fields.
3. Add a one-time backfill command that annotates old rows where possible:
   - infer `session` from `target_session` or `dispatched_to`;
   - infer `pane` from `target_pane` or `dispatched_to`;
   - leave `dispatch_skill_version="legacy"` when unknown.
4. Start hooks in WARN mode for 24h: log would-block rows without denying.
5. Flip to DENY for raw dispatch/callback bypasses once false positives are reviewed.

## 6. Rollback Plan

Per-gate disable must not require code edits.

Recommended controls:

- Global disable: `FLYWHEEL_DISPATCH_ENFORCE=0`.
- Per-gate env disable: `FLYWHEEL_DISPATCH_GATE_DISABLE=dispatch_skill_required,topology_lookup_required,callback_contract_required,ntm_only_pane_state`.
- Sentinel directory: `/Users/josh/.local/state/flywheel/dispatch-gates-disabled/<gate-name>`.
- Repo-local temporary sentinel: `<repo>/.flywheel/no-enforce-dispatch` with one-line reason and expiry timestamp.
- Existing one-shot override: `JOSHUA_OVERRIDE='<reason>'`, logged by shared override hook.

Rollback procedure:
1. Set per-gate env disable for the failing gate in the hook launch context.
2. Re-run the blocked command with `FLYWHEEL_DISPATCH_ENFORCE=0` only if the per-gate disable is too broad to isolate.
3. Log a fuckup row with class `dispatch_gate_false_positive` and include the blocked command, expected behavior, gate name, and override path used.
4. Keep doctor invariant active even when PreToolUse blocking is disabled, so false-positive recovery does not blind the next tick.

## 7. Concrete Patch Plan

### `/Users/josh/.claude/commands/flywheel/dispatch.md`

Patch intent:
- Add `dispatch_skill_version=flywheel-dispatch/v2`.
- Require topology resolution before choosing worker and callback panes.
- Require `edits_expected` and `socraticode_required` classification.
- Export `FLYWHEEL_DISPATCH_WRAPPER=1` only for the canonical send.
- Log schema v2 receipt before send and update with send result.

### `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`

Patch intent:
- Replace prose callback examples with topology-resolving shell snippet.
- Require numeric L50 callback fields unless dispatch explicitly disables Socraticode.
- Require L51 file reservation fields.
- Require bead/no-bead and fuckup-log receipt fields per L52/L53.
- Include task SHA and dispatch schema version in packet header.

### `/Users/josh/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`

Patch intent:
- Keep existing `tmux send-keys` denial.
- Add `dispatch_skill_required`.
- Add `topology_lookup_required`.
- Add `callback_contract_required`.
- Add `ntm_only_pane_state`.
- Add per-gate env/sentinel disable and WARN/DENY mode.

### New hook specs

1. `topology-lookup-required`: validates `ntm send <session> --pane=N` against latest topology row and dispatch/callback role.
2. `callback-contract-required`: validates outgoing DONE/BLOCKED/Callback messages have required machine-readable fields.
3. `ntm-only-transport`: blocks raw multiplexer send/capture in dispatch state paths, allowing only explicitly supplementary captures.

## Validation Ladder

1. All 8 trauma classes from bead description cited with actual fuckup-log evidence: yes.
2. Current dispatch Mermaid produced and bypass points marked: yes.
3. Enforcement designs: 8 class-specific designs plus 3 named gate specs.
4. Receipt schema specified with all required fields named: yes.
5. Backwards-compat audit of last 50 dispatch-log rows: yes.
6. Rollback plan addresses per-gate disable without code edits: yes.
7. No code modifications: yes; this plan only.
8. No fabrication: yes; evidence came from `dispatch.md`, `_shared/dispatch-template.md`, extant hook, `.beads/beads.db`, fuckup-log, INCIDENTS.md, and last 50 dispatch-log rows.
9. `ladder_passed`: yes.
