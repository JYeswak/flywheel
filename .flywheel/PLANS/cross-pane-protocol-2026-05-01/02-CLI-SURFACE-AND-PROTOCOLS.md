# Cross-Pane Protocol Lane 2 - CLI Surface and Protocols

Date: 2026-05-01
Lane: 2 of 3
Scope: plan-space CLI specification only
Target binary: `flywheel-readme` (planned)
Canonical standard: `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md` v0.2.0

## Purpose

`flywheel-readme` is the planned operator CLI for cross-pane README review. It supports the worker -> orchestrator -> Joshua flow while following canonical CLI scoping: doctor, health, repair, validate, audit, why, self-documentation, universal JSON, universal exit codes, dry-run mutation discipline, metrics, logs, and trace.

This plan does not implement the binary, does not define L69 doctrine wording, and does not design the backfill engine.

## Console-Script Name Precheck

Before claiming the console script, implementation must run:

```bash
which flywheel-readme
```

Observed during this lane: `flywheel-readme not found`. The entrypoint name is clear today. This precheck is mandatory because the canonical CLI scoping skill calls out the B1.5/cm session-2026-05-01 trauma class: name collisions silently shadow upstream binaries.

## Verified Inputs

| Input | Verification |
|---|---|
| Socraticode survey | 2 searches against `/Users/josh/Developer/flywheel`, 20 results observed |
| Canonical CLI skill | Read `/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md` |
| Beads reject-and-revert | Read `/Users/josh/.claude/skills/beads-workflow/SKILL.md` |
| Hook patterns | Read `/Users/josh/.claude/skills/cc-hooks/SKILL.md` |
| L61/L65 doctrine | Read `/Users/josh/Developer/flywheel/AGENTS.md` |
| New queue path | `/Users/josh/.local/state/flywheel/docs-review-queue.jsonl` is clear |
| New lock path | `/Users/josh/.local/state/flywheel/docs-review.lock` is clear |
| Repo dispatch log | `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl` exists |
| Fleet-mail project | `/Users/josh/.local/state/flywheel/fleet-mail-project` is doctrine-required but absent on disk during this lane; doctor must classify this as `NOT_CONFIGURED` |

## State Machine

```text
0_untracked
  -> 1_drafted
  -> 2_orchestrator_reviewing
  -> 3_orchestrator_passed
  -> 4_joshua_signed

Reject transitions:
  2_orchestrator_reviewing -> 2_rejected_to_worker -> 1_drafted_vN
  3_orchestrator_passed -> 4_joshua_rejected -> 1_drafted_vN
```

## Universal Flags

Every command supports:

| Flag | Contract |
|---|---|
| `--json` | Machine-readable output for every command |
| `--no-color` | Disable ANSI color |
| `--no-emoji` | Disable symbols/emoji for logs and CI |
| `--width <n>` | Format human output to a fixed width |

Every mutating command also supports:

| Flag | Contract |
|---|---|
| `--dry-run` | Print planned actions, exit 0, mutate nothing |
| `--explain` | Print rationale before executing |
| `--idempotency-key <key>` | Return prior audit result on repeated key, never re-mutate |

Mutating commands in this CLI: `draft`, `submit`, `review <path>`, `reject`, `pass`, `signoff <path>`, `doctor --fix`, `repair`.

## Canonical Exit Codes

| Code | Meaning | `flywheel-readme` mapping |
|---:|---|---|
| 0 | Success | Passed check, listed queue, applied mutation, or dry-run succeeded |
| 1 | Domain-specific failure | Gate 2 checklist failed, validation failed, corrupt README found by doctor |
| 2 | Usage error | Bad args, missing required flag, invalid state-machine transition requested |
| 3 | Transient/upstream/network failure | NTM unavailable, agent-mail unavailable, fleet-mail project temporarily unreachable |
| 4 | Blocked by gate | Self-validation prevention, missing approval for apply, L61 transport incomplete |
| 5 | Lock conflict | Active non-stale lock prevents mutation |
| 6 | Frontmatter invalid | YAML/frontmatter parse or required key failure |
| 7 | Ledger integrity failure | Queue/audit ledger cannot reconcile with README state |
| 8 | Validation command failed | README `validation_command` returned non-zero |

The implementation must document this table in `flywheel-readme --help` and all relevant subcommand help pages.

## Shared Persistence

| Store | Path | Role |
|---|---|---|
| README frontmatter | Each README | Canonical per-item state |
| Queue ledger | `/Users/josh/.local/state/flywheel/docs-review-queue.jsonl` | Append-only state transitions |
| Audit log | `/Users/josh/.local/state/flywheel/docs-review-audit.jsonl` | Append-only mutation provenance |
| Operator log | `/Users/josh/.local/state/flywheel/docs-review.log.jsonl` | Structured logs for `logs` command |
| Lock file | `/Users/josh/.local/state/flywheel/docs-review.lock` | Cross-process mutation lock |
| Dispatch log | `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl` | Orchestrator durable dispatch record |
| Fleet mail project | `/Users/josh/.local/state/flywheel/fleet-mail-project` | L65 durable cross-orch mail project |

### README Frontmatter

```yaml
---
schema_version: 1
target_artifact: /absolute/path/to/artifact
artifact_kind: binary|hook|plist|skill|doctrine-artifact|dispatch-flow
state: 1_drafted
version: 1
bead_id: flywheel-abc
task_id: docs_readme_<artifact>
drafted_by: flywheel-pane3-codex
drafted_at: 2026-05-01T21:00:00Z
reviewed_by:
reviewed_at:
validated_by:
validated_at:
validation_command: "..."
freshness_window_days: 30
mermaid_present: true
thread_id: docs-review-<sha256-readme-path>
---
```

### Queue Ledger Row

```json
{
  "ts": "2026-05-01T21:00:00Z",
  "event": "submitted",
  "readme_path": "/absolute/path/README.md",
  "target_artifact": "/absolute/path/artifact",
  "state_from": "0_untracked",
  "state_to": "1_drafted",
  "actor": "flywheel-pane3-codex",
  "actor_pane": "flywheel:3",
  "bead_id": "flywheel-i9o",
  "task_id": "docs_readme_autoloop",
  "version": 1,
  "thread_id": "docs-review-abc123",
  "idempotency_key": "docs_readme_autoloop:v1:submit",
  "audit_id": "audit-abc123"
}
```

### Dry-Run Output Contract

`--dry-run --json` output must use planned keys only:

```json
{
  "mode": "dry_run",
  "planned_actions": ["append_queue_row", "send_ntm", "send_agent_mail"],
  "would_write": ["/Users/josh/.local/state/flywheel/docs-review-queue.jsonl"],
  "would_delete": [],
  "would_call_external": ["ntm send", "agent-mail send_message"],
  "blocked_by": []
}
```

Applied runs must use actual keys only:

```json
{
  "mode": "applied",
  "actual_actions": ["append_queue_row", "send_ntm", "send_agent_mail"],
  "writes": ["/Users/josh/.local/state/flywheel/docs-review-queue.jsonl"],
  "deletes": [],
  "external_calls": ["ntm send", "agent-mail send_message"],
  "audit_ids": ["audit-abc123"]
}
```

## Cross-Pane Transport Contract

Any command crossing panes must use L61 dual-channel:

1. `ntm send` to recipient pane for immediate wake signal.
2. Agent-mail message in `/Users/josh/.local/state/flywheel/fleet-mail-project` for durable record.
3. Dispatch-log entry in `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl`.

Thread ID:

```text
docs-review-<sha256-readme-path>
```

Transport JSON:

```json
{
  "transport": {
    "recipient_session": "flywheel",
    "recipient_pane": 1,
    "ntm_sent": true,
    "ntm_message": "POKE docs-review msg id=17 project=/Users/josh/.local/state/flywheel/fleet-mail-project subject=\"README review\"",
    "agent_mail_sent": true,
    "agent_mail_message_id": 17,
    "agent_mail_project_key": "/Users/josh/.local/state/flywheel/fleet-mail-project",
    "dispatch_log_written": true,
    "dispatch_log_path": "/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
  }
}
```

If either cross-pane channel fails, the command must not advance frontmatter state. It exits 3 for transient transport failure, or 4 when policy blocks incomplete L61 pairing.

## Command Inventory

Domain review-flow commands: 8 modes.

Canonical commands and global surfaces: doctor, health, repair, validate, audit, why, info, examples, quickstart, help, completion, schema, metrics, logs, trace.

Large-surface discoverability commands, required because the combined surface exceeds 20 modes: palette, activity, triage.

Total planned command/mode surfaces: 26.

## Man-Page Contracts

All commands inherit universal flags. Mutating commands also inherit mutation flags.

### 1. `flywheel-readme draft`

Synopsis:

```bash
flywheel-readme draft <artifact-path> [--out <readme-path>] [--from-bead <bead-id>] [--drafted-by <name>] [--pane <session:pane>] [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: worker-side command that scaffolds a README with required frontmatter and skeleton senior-dev sections.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<artifact-path>` | Artifact being documented |
| `--out <readme-path>` | Output path; default derived from artifact |
| `--from-bead <bead-id>` | Bead requesting the doc |
| `--drafted-by <name>` | Worker identity |
| `--pane <session:pane>` | Worker pane address |

JSON output:

```json
{
  "status": "drafted",
  "readme_path": "/absolute/path/artifact.README.md",
  "target_artifact": "/absolute/path/artifact",
  "state": "1_drafted",
  "version": 1,
  "bead_id": "flywheel-i9o",
  "drafted_by": "flywheel-pane3-codex",
  "frontmatter_written": true
}
```

Exit codes: 0, 1, 2, 5, 6.

Side effects: writes README, appends audit log. No cross-pane transport.

Examples:

```bash
flywheel-readme draft /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop
flywheel-readme draft /Users/josh/.claude/hooks/my-hook.sh --out /Users/josh/.claude/hooks/my-hook.README.md --from-bead flywheel-abc
flywheel-readme draft /Users/josh/Library/LaunchAgents/ai.zeststream.example.plist --drafted-by flywheel-pane3-codex --json
```

### 2. `flywheel-readme submit`

Synopsis:

```bash
flywheel-readme submit <readme-path> [--bead <id>] [--drafted-by <name>] [--pane <session:pane>] [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: worker-side command that submits a drafted README for orchestrator Gate 2 review and performs L61 dual-channel notification.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<readme-path>` | README to submit |
| `--bead <id>` | Linked bead |
| `--drafted-by <name>` | Worker identity |
| `--pane <session:pane>` | Worker return address |

JSON output:

```json
{
  "status": "submitted",
  "readme_path": "/absolute/path/README.md",
  "state": "1_drafted",
  "queue_row_written": true,
  "thread_id": "docs-review-abc123",
  "transport": {
    "ntm_sent": true,
    "agent_mail_sent": true,
    "agent_mail_message_id": 17,
    "dispatch_log_written": true
  }
}
```

Exit codes: 0, 2, 3, 4, 5, 6, 8.

Side effects: updates frontmatter, appends queue/audit logs, sends `ntm`, sends agent-mail, appends dispatch log.

Examples:

```bash
flywheel-readme submit /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md --bead flywheel-i9o
flywheel-readme submit /Users/josh/.claude/hooks/my-hook.README.md --drafted-by flywheel-pane3-codex --pane flywheel:3 --json
flywheel-readme submit ./README.md --bead flywheel-docs-123 --dry-run --json
```

### 3. `flywheel-readme review --queue`

Synopsis:

```bash
flywheel-readme review --queue [--limit <n>] [--older-than-hours <n>] [--json]
```

Description: orchestrator-side queue listing for READMEs currently in `1_drafted`.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `--queue` | Queue listing mode |
| `--limit <n>` | Maximum items |
| `--older-than-hours <n>` | Staleness filter |

JSON output:

```json
{
  "queue_size": 1,
  "items": [
    {
      "readme_path": "/absolute/path/README.md",
      "target_artifact": "/absolute/path/artifact",
      "drafted_at": "2026-05-01T21:00:00Z",
      "drafted_by": "flywheel-pane3-codex",
      "age_hours": 2,
      "bead_id": "flywheel-i9o"
    }
  ]
}
```

Exit codes: 0, 1, 2, 6, 7.

Side effects: read-only.

Examples:

```bash
flywheel-readme review --queue
flywheel-readme review --queue --json
flywheel-readme review --queue --older-than-hours 6 --limit 10 --no-color
```

### 4. `flywheel-readme review <readme-path>`

Synopsis:

```bash
flywheel-readme review <readme-path> [--reviewed-by <orch-name>] [--non-interactive] [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: orchestrator-side Gate 2 checklist. It opens the README, runs `validation_command`, checks frontmatter, mermaid, links, examples, and cold-read replicability. It mutates state to `2_orchestrator_reviewing` and appends ledger rows unless `--dry-run` is used.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<readme-path>` | README to review |
| `--reviewed-by <orch-name>` | Orchestrator identity |
| `--non-interactive` | Compute checks without prompts |

JSON output:

```json
{
  "readme_path": "/absolute/path/README.md",
  "checklist": {
    "frontmatter_complete": true,
    "validation_command_runs_green": true,
    "cold_read_replicable": true,
    "mermaid_required_present_parseable": true,
    "see_also_links_resolve": true,
    "examples_no_surprise_side_effects": true
  },
  "verdict": "pass",
  "fail_reasons": []
}
```

Exit codes: 0, 1, 2, 5, 6, 8.

Side effects: updates frontmatter to reviewing, appends queue/audit rows. No cross-pane transport.

Examples:

```bash
flywheel-readme review /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md
flywheel-readme review ./README.md --reviewed-by LavenderGlen --non-interactive --json
flywheel-readme review "$(flywheel-readme review --queue --json | jq -r '.items[0].readme_path')" --dry-run --json
```

### 5. `flywheel-readme reject`

Synopsis:

```bash
flywheel-readme reject <readme-path> --reasons <comma-list> [--detail-file <path>] [--reviewed-by <orch-name>] [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: orchestrator-side Gate 2 rejection. It sends worker callback-back via both L61 channels and records the rejection. Both transport legs are mandatory.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<readme-path>` | README being rejected |
| `--reasons <comma-list>` | Stable rejection reason codes |
| `--detail-file <path>` | Markdown detail body for agent-mail |
| `--reviewed-by <orch-name>` | Orchestrator identity |

JSON output:

```json
{
  "status": "rejected",
  "readme_path": "/absolute/path/README.md",
  "state_from": "2_orchestrator_reviewing",
  "state_to": "2_rejected_to_worker",
  "version": 1,
  "next_version": 2,
  "reasons": ["validation_failed", "see_also_broken"],
  "transport": {
    "ntm_sent": true,
    "agent_mail_sent": true,
    "agent_mail_message_id": 18,
    "dispatch_log_written": true
  }
}
```

Exit codes: 0, 2, 3, 4, 5, 6, 7.

Side effects: updates frontmatter, appends ledgers, sends `ntm`, sends agent-mail, writes dispatch-log row.

Examples:

```bash
flywheel-readme reject ./README.md --reasons validation_failed,missing_error_modes --reviewed-by LavenderGlen
flywheel-readme reject /tmp/doc.README.md --reasons see_also_broken --detail-file /tmp/review-details.md --json
flywheel-readme reject "$README" --reasons self_validation_risk,examples_mutate_state --dry-run --json
```

### 6. `flywheel-readme pass`

Synopsis:

```bash
flywheel-readme pass <readme-path> --reviewed-by <orch-name> [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: orchestrator-side command that advances a README from Gate 2 to Joshua signoff. Blocks if `drafted_by == reviewed_by`.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<readme-path>` | README passing Gate 2 |
| `--reviewed-by <orch-name>` | Orchestrator identity |

JSON output:

```json
{
  "status": "passed",
  "readme_path": "/absolute/path/README.md",
  "state_from": "2_orchestrator_reviewing",
  "state_to": "3_orchestrator_passed",
  "reviewed_by": "LavenderGlen",
  "reviewed_at": "2026-05-01T21:30:00Z",
  "self_validation_prevented": false
}
```

Exit codes: 0, 2, 4, 5, 6, 8.

Side effects: updates frontmatter, appends queue/audit rows.

Examples:

```bash
flywheel-readme pass ./README.md --reviewed-by LavenderGlen
flywheel-readme pass /Users/josh/.claude/hooks/example.README.md --reviewed-by flywheel-pane1-orch --json
flywheel-readme review "$README" --non-interactive && flywheel-readme pass "$README" --reviewed-by LavenderGlen --explain
```

### 7. `flywheel-readme signoff --queue`

Synopsis:

```bash
flywheel-readme signoff --queue [--limit <n>] [--older-than-hours <n>] [--json]
```

Description: Joshua-side queue listing for READMEs in `3_orchestrator_passed`.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `--queue` | Queue listing mode |
| `--limit <n>` | Maximum items |
| `--older-than-hours <n>` | Staleness filter |

JSON output:

```json
{
  "queue_size": 1,
  "items": [
    {
      "readme_path": "/absolute/path/README.md",
      "reviewed_by": "LavenderGlen",
      "reviewed_at": "2026-05-01T21:30:00Z",
      "age_hours": 1,
      "target_artifact": "/absolute/path/artifact",
      "bead_id": "flywheel-i9o"
    }
  ]
}
```

Exit codes: 0, 1, 2, 6, 7.

Side effects: read-only.

Examples:

```bash
flywheel-readme signoff --queue
flywheel-readme signoff --queue --json
flywheel-readme signoff --queue --older-than-hours 12 --limit 5
```

### 8. `flywheel-readme signoff <readme-path>`

Synopsis:

```bash
flywheel-readme signoff <readme-path> [--signed-by <identity>] [--reject-with-reason <text>] [--dry-run] [--explain] [--idempotency-key <key>] [--json]
```

Description: Joshua-side final signoff or rejection. Passing fills `validated_by`, `validated_at`, and state `4_joshua_signed`. Rejection sends L61 notice back to the orchestrator and requires a new worker version. Blocks if `reviewed_by == signed_by`.

Command-specific flags:

| Flag | Meaning |
|---|---|
| `<readme-path>` | README awaiting signoff |
| `--signed-by <identity>` | Signoff identity, default `joshua` |
| `--reject-with-reason <text>` | Reject instead of sign |

JSON output:

```json
{
  "status": "signed",
  "readme_path": "/absolute/path/README.md",
  "state_from": "3_orchestrator_passed",
  "state_to": "4_joshua_signed",
  "validated_by": "joshua",
  "validated_at": "2026-05-01T22:00:00Z"
}
```

Reject JSON:

```json
{
  "status": "rejected",
  "readme_path": "/absolute/path/README.md",
  "state_from": "3_orchestrator_passed",
  "state_to": "4_joshua_rejected",
  "reject_reason": "examples do not match actual command output",
  "next_version": 2,
  "transport": {
    "ntm_sent": true,
    "agent_mail_sent": true,
    "dispatch_log_written": true
  }
}
```

Exit codes: 0, 2, 3, 4, 5, 6, 7, 8.

Side effects: updates frontmatter and ledgers; reject path sends L61 dual-channel notice and writes dispatch-log row.

Examples:

```bash
flywheel-readme signoff ./README.md
flywheel-readme signoff /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md --signed-by joshua --json
flywheel-readme signoff "$README" --reject-with-reason "validation command does not prove the documented flags" --dry-run --json
```

## Canonical Triad

### 9. `flywheel-readme doctor`

Synopsis:

```bash
flywheel-readme doctor [--scope <queue|ledger|locks|frontmatter|validation_commands>] [--fix] [--apply] [--json]
```

Description: diagnose review queue, lock files, ledger integrity, frontmatter parseability, and validation commands. `--fix` is dry-run by default unless `--apply` is present. It must never crash when a subsystem is dead; classify as `OK`, `DEGRADED`, `DOWN`, `NOT_CONFIGURED`, or `UPSTREAM_BUG`.

JSON output:

```json
{
  "status": "DEGRADED",
  "subsystems": {
    "queue": {"status": "OK", "items": 3},
    "ledger": {"status": "OK", "rows": 42},
    "locks": {"status": "DEGRADED", "stale_locks": 1},
    "frontmatter": {"status": "OK", "parsed": 3, "failed": 0},
    "validation_commands": {"status": "DOWN", "failed": 1}
  },
  "fix": {
    "mode": "dry_run",
    "planned_actions": ["remove_stale_lock"]
  }
}
```

Exit codes: 0 all green, 1 at least one fail/degraded, 2 usage error, 3 upstream transient.

Examples:

```bash
flywheel-readme doctor
flywheel-readme doctor --scope locks --fix --json
flywheel-readme doctor --scope ledger --fix --apply --idempotency-key doctor-ledger-20260501
```

### 10. `flywheel-readme health`

Synopsis:

```bash
flywheel-readme health [--watch] [-i <seconds>] [--json]
```

Description: lightweight status for monitoring. Reports queue depth, overdue counts, lock-held count, transport substrate state, and latest audit timestamp. `--watch` emits NDJSON progress events.

JSON output:

```json
{
  "status": "green",
  "queue_depth": 3,
  "overdue": 0,
  "locks_held": 0,
  "fleet_mail_project": "NOT_CONFIGURED",
  "latest_audit_ts": "2026-05-01T22:00:00Z"
}
```

Exit codes: 0 green, 1 degraded, 3 critical or upstream unavailable, 2 usage error.

Examples:

```bash
flywheel-readme health
flywheel-readme health --json
flywheel-readme health --watch -i 10 --json
```

### 11. `flywheel-readme repair`

Synopsis:

```bash
flywheel-readme repair --scope <queue|ledger|locks|frontmatter|validation_commands> [--dry-run] [--apply] [--explain] [--idempotency-key <key>] [--json]
```

Description: idempotent repair for known failures. Default is dry-run unless `--apply` is present. Known repairs: remove stale locks older than 30 seconds, quarantine orphaned queue rows, rewrite frontmatter for known schema migrations, refresh broken state from ledger when unambiguous.

JSON output:

```json
{
  "mode": "dry_run",
  "scope": "locks",
  "planned_actions": ["remove_stale_lock"],
  "would_write": ["/Users/josh/.local/state/flywheel/docs-review.lock"],
  "would_delete": ["/Users/josh/.local/state/flywheel/docs-review.lock"],
  "would_call_external": [],
  "blocked_by": []
}
```

Exit codes: 0 no-op or success, 1 at least one repair failed, 2 usage error, 4 missing `--apply` for mutation.

Examples:

```bash
flywheel-readme repair --scope locks
flywheel-readme repair --scope queue --dry-run --json
flywheel-readme repair --scope frontmatter --apply --explain --idempotency-key repair-frontmatter-v1
```

## State Subsidiary Triad

### 12. `flywheel-readme validate`

Synopsis:

```bash
flywheel-readme validate <readme-path> [--gate <1|2>] [--json]
```

Description: pure-read validation. Gate 1 checks frontmatter, schema, target path, mermaid requirement, `See Also` paths, and validation command presence. It does not run the interactive Gate 2 flow and has no side effects.

JSON output:

```json
{
  "readme_path": "/absolute/path/README.md",
  "valid": true,
  "gate": 1,
  "checks": {
    "frontmatter": true,
    "target_artifact_exists": true,
    "validation_command_present": true,
    "see_also_paths_exist": true
  }
}
```

Exit codes: 0 valid, 1 invalid, 2 usage error, 6 invalid frontmatter, 8 validation command failure if `--gate 2` runs it.

Examples:

```bash
flywheel-readme validate ./README.md
flywheel-readme validate /Users/josh/.claude/hooks/example.README.md --json
flywheel-readme validate "$README" --gate 2 --no-color
```

### 13. `flywheel-readme audit`

Synopsis:

```bash
flywheel-readme audit [--since <duration>] [--readme <path>] [--actor <name>] [--json]
```

Description: show recent state mutations with provenance: who, when, state transition, idempotency key, readme sha, bead id, and pane.

JSON output:

```json
{
  "items": [
    {
      "audit_id": "audit-abc123",
      "ts": "2026-05-01T22:00:00Z",
      "readme_path": "/absolute/path/README.md",
      "actor": "LavenderGlen",
      "transition": "2_orchestrator_reviewing->3_orchestrator_passed",
      "sha256": "abc123"
    }
  ]
}
```

Exit codes: 0 success, 2 usage error, 7 ledger integrity failure.

Examples:

```bash
flywheel-readme audit
flywheel-readme audit --since 24h --json
flywheel-readme audit --readme /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md
```

### 14. `flywheel-readme why`

Synopsis:

```bash
flywheel-readme why <readme-path> [--json]
```

Description: full provenance trace for a README: dispatch source, bead id, drafter pane, reviewer pane, signoff, all transitions, audit IDs, queue rows, and transport records.

JSON output:

```json
{
  "readme_path": "/absolute/path/README.md",
  "bead_id": "flywheel-i9o",
  "thread_id": "docs-review-abc123",
  "transitions": [
    {"state_from": "1_drafted", "state_to": "2_orchestrator_reviewing", "actor": "LavenderGlen"}
  ],
  "transport": []
}
```

Exit codes: 0 success, 1 object not found, 2 usage error, 7 provenance inconsistency.

Examples:

```bash
flywheel-readme why ./README.md
flywheel-readme why /Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop.README.md --json
flywheel-readme why "$README" --width 120 --no-color
```

## Self-Documentation

### 15. `flywheel-readme --info`

Synopsis:

```bash
flywheel-readme --info [--json]
```

Description: version, config paths, environment variables, dependencies, runtime sha, console-script path, and current schema versions.

JSON output:

```json
{
  "name": "flywheel-readme",
  "version": "0.1.0",
  "runtime_sha256": "abc123",
  "paths": {
    "queue": "/Users/josh/.local/state/flywheel/docs-review-queue.jsonl",
    "audit": "/Users/josh/.local/state/flywheel/docs-review-audit.jsonl"
  },
  "deps": ["jq", "ntm", "agent-mail"]
}
```

Exit codes: 0 success, 2 usage error.

Examples:

```bash
flywheel-readme --info
flywheel-readme --info --json
flywheel-readme --info --no-color --width 100
```

### 16. `flywheel-readme examples`

Synopsis:

```bash
flywheel-readme examples [--json]
```

Description: five curated workflows: draft-submit, review-pass, review-reject, signoff, doctor-fix-stuck-lock.

JSON output:

```json
{
  "examples": [
    {"name": "draft-submit", "commands": ["flywheel-readme draft ...", "flywheel-readme submit ..."]}
  ]
}
```

Exit codes: 0 success.

Examples:

```bash
flywheel-readme examples
flywheel-readme examples --json
flywheel-readme --examples
```

### 17. `flywheel-readme quickstart`

Synopsis:

```bash
flywheel-readme quickstart [--json]
```

Description: operator onboarding guide as a command. It explains lifecycle, roles, queue commands, and the first safe dry-run workflow.

JSON output:

```json
{
  "title": "flywheel-readme quickstart",
  "steps": [
    "run flywheel-readme health",
    "run flywheel-readme review --queue",
    "run flywheel-readme review <path> --dry-run"
  ]
}
```

Exit codes: 0 success.

Examples:

```bash
flywheel-readme quickstart
flywheel-readme quickstart --json
flywheel-readme quickstart --width 120
```

### 18. `flywheel-readme help <topic>`

Synopsis:

```bash
flywheel-readme help <lifecycle|gate2|reject-and-revert|state-machine|ledger|locks> [--json]
```

Description: topic-based manual. Required topics: `lifecycle`, `gate2`, `reject-and-revert`, `state-machine`, `ledger`, `locks`.

JSON output:

```json
{
  "topic": "gate2",
  "sections": ["purpose", "checklist", "pass", "reject"]
}
```

Exit codes: 0 success, 2 unknown topic.

Examples:

```bash
flywheel-readme help lifecycle
flywheel-readme help gate2 --json
flywheel-readme help reject-and-revert --width 120
```

### 19. `flywheel-readme completion`

Synopsis:

```bash
flywheel-readme completion <bash|zsh|fish>
```

Description: generate shell completion script.

JSON output:

```json
{
  "shell": "zsh",
  "completion": "#compdef flywheel-readme\n..."
}
```

Exit codes: 0 success, 2 unsupported shell.

Examples:

```bash
flywheel-readme completion zsh > ~/.zfunc/_flywheel-readme
flywheel-readme completion bash
flywheel-readme completion fish --json
```

## Schema and Observability

### 20. `flywheel-readme schema`

Synopsis:

```bash
flywheel-readme schema <command|all> [--json]
```

Description: emit JSON Schema for command output.

JSON output:

```json
{
  "command": "review --queue",
  "schema_version": 1,
  "schema": {
    "type": "object",
    "required": ["queue_size", "items"]
  }
}
```

Exit codes: 0 success, 2 unknown command.

Examples:

```bash
flywheel-readme schema review-queue
flywheel-readme schema signoff --json
flywheel-readme schema all > /tmp/flywheel-readme-schemas.json
```

### 21. `flywheel-readme metrics`

Synopsis:

```bash
flywheel-readme metrics [--json] [--since <duration>] [--by-pane] [--by-day]
```

Description: counters for drafted, reviewed, passed, rejected, signed-off, timed-out, by pane and by day.

JSON output:

```json
{
  "drafted": 10,
  "reviewed": 8,
  "passed": 6,
  "rejected": 2,
  "signed_off": 4,
  "timed_out": 1,
  "by_pane": {"flywheel:3": 4}
}
```

Exit codes: 0 success, 2 bad flags, 7 ledger failure.

Examples:

```bash
flywheel-readme metrics
flywheel-readme metrics --since 7d --json
flywheel-readme metrics --by-pane --by-day --width 140
```

### 22. `flywheel-readme logs`

Synopsis:

```bash
flywheel-readme logs [--since <duration>] [--readme <path>] [--json] [--follow]
```

Description: structured operator log. `--follow --json` emits NDJSON progress events.

JSON output:

```json
{
  "items": [
    {"ts": "2026-05-01T22:00:00Z", "level": "info", "event": "submitted"}
  ]
}
```

Exit codes: 0 success, 2 bad flags, 7 log read failure.

Examples:

```bash
flywheel-readme logs
flywheel-readme logs --since 6h --json
flywheel-readme logs --readme "$README" --follow --json
```

### 23. `flywheel-readme trace`

Synopsis:

```bash
flywheel-readme trace <readme-path> [--json]
```

Description: span/provenance trace for one README's journey. Similar to `why`, but timing-oriented: spans, duration between gates, transport timings, and lock waits.

JSON output:

```json
{
  "readme_path": "/absolute/path/README.md",
  "spans": [
    {"name": "submit", "started_at": "2026-05-01T21:00:00Z", "duration_ms": 120}
  ]
}
```

Exit codes: 0 success, 1 not found, 2 usage error, 7 trace inconsistency.

Examples:

```bash
flywheel-readme trace ./README.md
flywheel-readme trace /Users/josh/.claude/hooks/example.README.md --json
flywheel-readme trace "$README" --no-color --width 120
```

### NDJSON Progress Events

Long-running commands: `health --watch`, `logs --follow`, `doctor --fix`, `repair --apply`, and any future batch command.

Event names:

```json
{"event": "started", "ts": "2026-05-01T22:00:00Z", "command": "repair"}
```

```json
{"event": "progress", "ts": "2026-05-01T22:00:01Z", "completed": 1, "total": 3}
```

```json
{"event": "warning", "ts": "2026-05-01T22:00:02Z", "class": "stale_lock"}
```

```json
{"event": "blocked", "ts": "2026-05-01T22:00:03Z", "blocked_by": ["missing_apply"]}
```

```json
{"event": "completed", "ts": "2026-05-01T22:00:04Z", "status": "ok"}
```

```json
{"event": "failed", "ts": "2026-05-01T22:00:05Z", "exit_code": 1}
```

## Large-Surface Discoverability

Because the final surface crosses 20 command/mode surfaces, Phase 1 must include the following discoverability commands.

### 24. `flywheel-readme palette`

Synopsis:

```bash
flywheel-readme palette [--json]
```

Description: command picker summary grouped by role: worker, orchestrator, Joshua, operator, repair.

JSON output:

```json
{
  "groups": {
    "worker": ["draft", "submit"],
    "orchestrator": ["review", "reject", "pass"],
    "joshua": ["signoff"],
    "operator": ["doctor", "health", "repair"]
  }
}
```

Exit codes: 0 success.

Examples:

```bash
flywheel-readme palette
flywheel-readme palette --json
flywheel-readme palette --no-color --width 100
```

### 25. `flywheel-readme activity`

Synopsis:

```bash
flywheel-readme activity [--json] [--since <duration>]
```

Description: what is happening right now: active locks, latest transitions, in-flight reviews, and pending signoffs.

JSON output:

```json
{
  "active_locks": 0,
  "in_flight_reviews": 1,
  "pending_signoffs": 2,
  "latest_transition": "submitted"
}
```

Exit codes: 0 success, 7 ledger failure.

Examples:

```bash
flywheel-readme activity
flywheel-readme activity --since 2h --json
flywheel-readme activity --width 120
```

### 26. `flywheel-readme triage`

Synopsis:

```bash
flywheel-readme triage [--json]
```

Description: advisory view: next recommended operator action based on queue depth, overdue items, stale locks, and failed validation commands.

JSON output:

```json
{
  "next_action": "review",
  "readme_path": "/absolute/path/README.md",
  "reason": "oldest drafted item"
}
```

Exit codes: 0 success, 1 no actionable item, 7 ledger failure.

Examples:

```bash
flywheel-readme triage
flywheel-readme triage --json
flywheel-readme triage --no-color --width 120
```

## Reject-and-Revert Protocol

The README flow applies `beads-workflow` reject-and-revert:

1. Detect: Gate 2 or signoff finds variance between README claims and artifact behavior.
2. Revert/reject: if committed, use history-preserving `git revert`; if still draft, mark rejected and require rewrite.
3. Reopen: linked bead returns to open or a documentation-fix bead is created.
4. File missing primitive: if the README failed because the artifact lacks the documented primitive, file the primitive as a new bead.
5. Codify: repeat failure classes become doctor checks or dispatch-template requirements.

Worker reject packet:

```text
Callback-back: task_id=docs_readme_<art>_REJECT v=2 reasons=<csv>
```

Agent-mail body includes checklist JSON, failed commands, stderr tail, exact README sections, and whether to rewrite README only or file a missing-primitive bead.

Anti-pattern: patching the draft cosmetically without resolving the false claim.

## Self-Validation Prevention

For `pass`:

```text
read frontmatter
actor = --reviewed-by
if drafted_by == actor:
  exit 4
run validation_command
if validation fails:
  exit 8
set reviewed_by, reviewed_at, state=3_orchestrator_passed
append queue ledger and audit log
exit 0
```

For `signoff`:

```text
read frontmatter
actor = --signed-by or "joshua"
if reviewed_by == actor:
  exit 4
if --reject-with-reason:
  run L61 reject transport
  set state=4_joshua_rejected
else:
  set validated_by, validated_at, state=4_joshua_signed
append queue ledger and audit log
exit 0
```

## Protocol Invariants

I1: State transitions are monotonic except explicit reject transitions.

Test predicate: `ordinal(state_to) >= ordinal(state_from) OR state_to in {2_rejected_to_worker,4_joshua_rejected}`.

I2: Every transition writes both README frontmatter and queue ledger.

Test predicate: `latest_ledger_state(readme_path) == frontmatter.state`.

I3: Timeouts are SOFT violations, not hard failures.

Test predicate: `age_hours(state=1_drafted) > threshold => emits docs_review_orchestrator_timeout and queue listing exits 0`.

I4: Lock file releases within 30 seconds or is auto-cleaned.

Test predicate: `lock.age_seconds > 30 and pid absent => next mutating command removes lock before acquiring new one`.

I5: Dispatch-log timestamp is less than or equal to frontmatter timestamp.

Test predicate: `dispatch_log.ts <= frontmatter.reviewed_at|validated_at|drafted_at`.

## Soft Violations

| Class | Trigger |
|---|---|
| `docs_review_orchestrator_timeout` | `1_drafted` item too old |
| `docs_review_joshua_timeout` | `3_orchestrator_passed` item too old |
| `docs_review_l61_transport_failed` | Either ntm or agent-mail leg failed |
| `docs_review_dispatch_log_missing` | Cross-pane transition lacks dispatch-log row |
| `docs_review_self_validation_attempt` | Exit 4 self-validation path hit |
| `docs_review_state_machine_violation` | Invalid transition attempted |
| `docs_review_lock_stale` | Lock older than 30 seconds |
| `docs_review_clock_sanity_violation` | Dispatch-log timestamp after frontmatter timestamp |

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Ship CLI without `doctor` | Operators can't diagnose; everything becomes "ssh in and grep" | Doctor is mandatory before v0.1 |
| `doctor` that crashes when subsystem is dead | Defeats the purpose because operator can't even see what's wrong | Wrap probes, classify as `DOWN`, never crash |
| `repair` without `--dry-run` | Operators can't preview; one bad invocation destroys state | `--dry-run` is mandatory; default to dry-run if `--apply` absent |
| Console_script name collision | Silent breakage when an env shadows global binary | Run `which flywheel-readme` before claiming entrypoint |
| Selective `--json` | Brittle automation, partial adoption | `--json` everywhere |
| Per-pane state hidden in aggregate | Cross-pane failures need pane attribution | Include pane/session in queue, audit, metrics, and why output |
| `repair` mutating without audit | No forensic trail when fix-the-fix breaks | Every repair appends audit log |
| Custom exit messages without exit codes | Scripting impossible | Use canonical exit code table |
| Help text without examples | Users do not know which flag combos work | Every help page has 3 to 5 real invocations |

## Validation Ladder

1. Doctor, health, repair triad present: pass.
2. Validate, audit, why subsidiary triad present: pass.
3. Self-documentation present: `--info`, `examples`, `quickstart`, `help <topic>`, `completion`: pass.
4. Canonical exit code map replaces custom map: pass.
5. Mutation discipline includes `--dry-run`, `--explain`, `--idempotency-key`: pass.
6. Observability includes `metrics`, `logs`, `trace`, NDJSON events: pass.
7. Anti-patterns section present: pass.
8. Canonical implementation checklist appended verbatim below: pass.
9. Console-script name collision precheck documented: pass.
10. Existing 8 review-flow commands remain: pass.
11. JSON examples parse as valid JSON where fenced as `json`: pass target for implementation validation.
12. State paths checked: queue and lock paths are clear; dispatch log exists; fleet-mail project is absent and must be doctor-classified `NOT_CONFIGURED`.
13. L61 dual-channel transport explicitly named: pass.
14. Reject-and-revert protocol matches `beads-workflow`: pass.
15. Five invariants stated as testable predicates: pass.
16. Every command has at least three examples: pass.
17. `ladder_passed`: yes.

## Callback Summary

File path written: `/Users/josh/Developer/flywheel/.flywheel/plans/cross-pane-protocol-2026-05-01/02-CLI-SURFACE-AND-PROTOCOLS.md`

Commands/modes specified: 26

JSON schemas/examples:
- README frontmatter
- queue ledger row
- dry-run output
- applied output
- cross-pane transport
- each command's JSON output
- NDJSON progress events

Exit codes: 9

Invariants: 5

ladder_passed: yes

## Implementation checklist (use as bead acceptance gate)

Copy this to any new CLI/adapter bead:

```
DOCTOR/HEALTH/REPAIR TRIAD:
  [ ] <cli> doctor exits 0/1, --json works, never crashes
  [ ] <cli> doctor --fix idempotent, dry-run default if --apply absent
  [ ] <cli> health single-shot, --watch -i N, --json
  [ ] <cli> repair --scope <subsystem> --dry-run mandatory

VALIDATE/AUDIT/WHY:
  [ ] <cli> validate <thing> pure-read, no side effects
  [ ] <cli> audit emits structured log of mutations with provenance
  [ ] <cli> why <id> shows full provenance trace

SELF-DOC:
  [ ] <cli> --info dumps version + paths + env + deps
  [ ] <cli> --examples (or examples cmd) has 5+ curated workflows
  [ ] <cli> quickstart written for new operators
  [ ] <cli> help <topic> for each major topic
  [ ] <cli> completion <shell> generates valid completions

ADAPTER SCOPE (if aggregator):
  [ ] doctor/health/repair scoped per-adapter
  [ ] adapter status taxonomy: OK|DEGRADED|DOWN|NOT_CONFIGURED|UPSTREAM_BUG
  [ ] <cli> upstream-report <adapter> generates draft, --apply gated

OUTPUT:
  [ ] --json on every command
  [ ] --no-color, --no-emoji, --width
  [ ] schema emission for every JSON output
  [ ] standard exit code table documented in --help

MUTATION:
  [ ] --dry-run + --explain on every state-changing command
  [ ] idempotent re-run
  [ ] audit log emission

DISCOVERABILITY (if >20 subcommands):
  [ ] palette/dashboard
  [ ] activity/changes view
  [ ] triage/assign advisory
```
