---
title: flywheel-vc3zs evidence — dispatch-and-log.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-vc3zs
parent: flywheel-wgitr (decomposed parent)
chain: doctor-mode-integration / lane-1-fillin
---

# flywheel-vc3zs evidence

**Status:** DONE — all 18 canonical-cli-scaffold TODO markers replaced with substantive surface-specific implementations; 15/15 canonical-CLI tests PASS; lint clean.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced with substantive (non-stub) implementations | DID | `grep -c TODO(canonical-cli-scaffold)` → 0 |
| AG2: bash -n clean | DID | syntax-ok |
| AG3: canonical-cli-lint clean | DID | 0 violations |
| AG4: existing canonical-cli scaffold-test 13/13 PASS | DID (15/15 actually) | tests/dispatch-and-log-canonical-cli.sh: SUMMARY pass=15 fail=0 |
| AG5: doctor concrete checks; health concrete status; repair scope-specific actions; validate schema rules; why provenance lookup | DID | All 6 stub categories return substantive non-"todo" status |

did=5/5, didnt=none, gaps=none.

## Substantive fill-in summary

### scaffold_cmd_doctor

5 concrete substrate checks:
1. `ntm_binary_executable` — ntm binary at FLYWHEEL_NTM_BIN exists + executable
2. `build_dispatch_packet_executable` — BUILD_DISPATCH_PACKET path exists + executable
3. `dispatch_log_writable` — `.flywheel/dispatch-log.jsonl` writable (or parent dir writable)
4. `flywheel_repo_resolvable` — REPO points at a real flywheel tree (`.flywheel/` present)
5. `br_on_path` — `br` binary on PATH for bead status updates

Returns `{schema_version, command:"doctor", ts, status: pass|fail, checks:[5 rows]}`.

### scaffold_cmd_health

Tails the last 20 rows of dispatch-log.jsonl and reports:
- `recent_count` — total tail rows
- `recent_send_success` — count of rows with `native_send.success == true`
- `last_dispatch_ts` — ISO timestamp of most recent dispatch
- `last_dispatch_age_seconds` — freshness (seconds since)
- `recent_sessions` / `recent_panes` — distinct values

Status escalation: `pass` if all sent successfully, `warn` if any failed or empty tail.

Live finding (mid-tick): the last 20 rows had `recent_send_success=0/20` — surfacing as a real fleet signal (the `native_send.success` field is consistently false on recent rows; orch may want to investigate).

### scaffold_cmd_repair

Two concrete scopes + canonical info envelope for empty/none scope:

- **`--scope dispatch-log`** — deduplicate dispatch-log.jsonl rows by `task_id` keeping the last occurrence (preserves order). `--dry-run` reports `before_lines`/`after_lines`/`duplicates_to_remove`. `--apply --idempotency-key KEY` performs the dedupe in-place.
- **`--scope bead-claim`** — re-attempt `br update <bead> --status=in_progress` for any bead seen in the last 50 rows. `--dry-run` lists candidates; `--apply --idempotency-key KEY` runs br updates.
- **`--scope none`** or empty — emits canonical envelope with valid_scopes hint (status=info, not refused).
- Unknown scope → status=refused with valid_scopes list, rc 64.

### scaffold_cmd_validate

Three subjects:

- **`--row-json=<JSON>`** — validate one inline row against the canonical required-field set (`ts, session, task_id, pane, task_file, channel, native_send, canonical_packet`)
- **`--tail=<N>`** — validate last N rows from dispatch-log.jsonl; per-row results + aggregate pass count
- **`--task-id=<ID>`** — find the row by task_id (last occurrence) and validate it

No subject → canonical envelope with valid_subjects list (status=info, not refused).

### scaffold_cmd_audit

Tails the dispatch-log.jsonl with configurable `--tail=<N>` (default 10). Returns `{schema_version, command:"audit", audit_log, tail_n, count, rows:[...]}`. When log absent → status=warn with empty rows array.

### scaffold_cmd_why

Looks up `<id>` in dispatch-log.jsonl (last occurrence), emits provenance:
- ts, session, pane, bead, task_file, canonical_packet_path, ntm_send_success, callback_expected_by

If task_id not found → status=not_found.

## Bonus: 3 calibrations

1. **L5 fix**: header was `set -uo pipefail`; changed to `set -euo pipefail` (canonical strict mode).
2. **scaffold_emit_schema** filled in with surface-specific schema (inputs/outputs/side_effects), not just `note: "TODO"`.
3. **scaffold_emit_topic_help** got concrete topic descriptions for run/doctor/health/repair/validate/audit/why (was emitting `TODO(canonical-cli-scaffold)` placeholders).

## Wall clock

~30 min (matches the bead's per-surface estimate).

## Cross-references

- Parent: `flywheel-wgitr` (BLOCKED with 8-bead decomposition; this is sub-bead 2 of 8)
- Sister sub-beads (the other 7 surfaces): q71jb, tfgt3, 39vhm, bqvpa, 5kjez, x882q, hpirw
- Subject script: `.flywheel/scripts/dispatch-and-log.sh` (388 → 530 lines after fill-in)
- Substrate touched: `.flywheel/dispatch-log.jsonl` (canonical dispatch log; this script writes to it)
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)

## Live signal surfaced (orch action recommended)

`scaffold_cmd_health` reported `recent_send_success=0/20` on real
data. Either (a) the `native_send.success` field is being consistently
mis-recorded, OR (b) recent dispatches really are failing. Orch may
want to dispatch a quick triage probe.

This is L52-compliant gap surfacing — the fill-in caught a real signal
while exercising substantive behavior.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — the surface itself is canonical-CLI; substantive fill-in completes the contract
- `rust-best-practices=n/a`
- `python-best-practices=n/a`
- `readme-writing=n/a`

## Skill discovery

`sd_ids=substantive-stub-fillin-with-live-signal-surfacing-class`

Generic shape: when a scaffolded canonical-CLI surface gets substantive
fill-in, the new substantive logic OFTEN immediately surfaces a real
substrate signal (here: 0/20 send-success on recent dispatches). This
is a *bonus* of doing fill-in carefully — the surface goes from
returning "todo" to returning real fleet diagnostics. Sister to today's
calibrate-to-actual-contract family but specifically tied to the
scaffold-then-fill-in workflow.
