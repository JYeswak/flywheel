# Compliance pack flywheel-1o9fa — stale-error-auto-ping.sh --idempotency-key gate + per-pane replay

## Bead disposition

P1 7axmt-followup. Second of 7 Tier-1 fixes from sister flywheel-7axmt fleet audit.
Surface: `.flywheel/scripts/stale-error-auto-ping.sh` — sends `ntm send` pings to stuck panes (external pane-state mutation, non-idempotent).
117 → 144 lines (+50 / -9 in surface; +129 line test file).

Sister 8sx9w (first 7axmt P0 fix) shipped `idempotency-key-with-replay-check pair-pattern` as a skill discovery. This bead applies the pair-pattern with a granular twist: **per-pane replay** rather than per-invocation replay.

## Pair-pattern variant: per-pane replay

The 8sx9w pattern was "if a prior row exists with this key, skip the entire run." That works for sync-canonical-doctrine because the whole sync is one atomic operation.

For stale-error-auto-ping, the canonical operation is "ping pane X". Multiple panes can be pinged in one invocation, but each ping is independent. The right granularity is **per-pane**:

- Audit row format: `{action: "ntm_send_ping", idempotency_key, session, pane, ts, ping_text}`
- Replay-check: for the supplied key, find all `pane` values already pinged
- Filter `before_candidates` to exclude already-pinged panes
- New `replay_skipped_panes` + `replay_skipped_count` + `eligible_candidate_count` fields in receipt

This means an operator can retry with the same key partway through and only the un-pinged panes get pinged. The 8sx9w whole-run-replay pattern would have re-pinged everyone or skipped everyone; per-pane replay is the right granularity for a per-target action.

## Fix shape (per 7axmt fix-spec recipe section 2 + 8sx9w pair-pattern)

### 1. Argparse parser added for both flag forms

```bash
--idempotency-key) [[ -n "${2:-}" ]] || { printf 'ERR: --idempotency-key requires VALUE\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
--idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; [[ -n "$IDEMPOTENCY_KEY" ]] || { printf 'ERR: --idempotency-key requires VALUE\n' >&2; exit 2; }; shift ;;
```

### 2. Refusal gate fires AFTER argparse, BEFORE any side-effect (hoqq8 invariant from m12ji)

```bash
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc --arg sv "$VERSION" \
    '{schema_version:$sv,command:"stale-error-auto-ping",status:"refused",mode:"apply",reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi
```

### 3. `replay_already_pinged_panes()` helper (tolerant-parse per 8sx9w discovery)

```bash
replay_already_pinged_panes() {
  if [[ -z "$IDEMPOTENCY_KEY" || ! -r "$AUDIT_LOG" ]]; then printf '[]\n'; return 0; fi
  jq -Rcs --arg k "$IDEMPOTENCY_KEY" \
    '[ split("\n")[] | select(length > 0) | fromjson? | select((.idempotency_key // "") == $k and (.action // "") == "ntm_send_ping") | (.pane // empty) ] | unique' \
    "$AUDIT_LOG" 2>/dev/null || printf '[]\n'
}
```

`fromjson?` survives corrupt rows (sister 8sx9w discovery: real ledgers accrete malformed rows over time).

### 4. `audit_append()` helper writes per-ping rows

```bash
audit_append "$(jq -nc --arg sv "$VERSION" --arg k "$IDEMPOTENCY_KEY" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg session "$SESSION" --argjson pane "$pane" --arg ping_text "$PING_TEXT" \
  '{schema_version:$sv,ts:$ts,action:"ntm_send_ping",idempotency_key:$k,session:$session,pane:$pane,ping_text:$ping_text}')"
```

### 5. `run_once()` filters before iterating

```bash
already_pinged="$(replay_already_pinged_panes)"
eligible_panes="$(jq -c --argjson skip "$already_pinged" '[.[] | select(.pane_idx as $p | $skip | index($p) | not)]' <<<"$before_candidates")"
```

Iterates `eligible_panes` (not `before_candidates`) when actually sending.

### 6. Receipt envelope adds 4 new fields

- `idempotency_key`: the supplied key (empty string when not provided)
- `replay_skipped_panes`: array of pane_idx values skipped due to prior matching ping
- `replay_skipped_count`: scalar count
- `eligible_candidate_count`: remaining-to-ping count
- Status taxonomy extended: new `all_replay_skipped` status when every detected candidate was already pinged

### 7. Documentation updates

- `usage()`: `--apply --idempotency-key KEY` shown in signature; rc=3 + per-pane replay semantics explained
- `examples()`: replaces bare `--apply` example with `--apply --idempotency-key=$(date)` form
- `emit_info()`: new fields `apply_requires`, `audit_log`, `exit_codes`, `flags` listing

## Acceptance gates (14/14)

- AG1.rc PASS — `--apply` without `--idempotency-key` exits 3
- AG1.envelope PASS — refusal envelope shape correct
- AG2 PASS — `--idempotency-key` without value exits 2
- AG3 PASS — `--idempotency-key=VALUE` equals form parses
- AG4 PASS — dry-run still works without key (3-candidate fixture)
- AG5 PASS — `--info` documents new fields
- AG6 PASS — `--help` documents new flag + rc=3
- AG7 PASS — receipt carries `idempotency_key + replay_skipped_panes + eligible_candidate_count`
- AG8 PASS — empty audit log → 0 skipped, 3 planned
- AG9 PASS — prior ping for pane 2 → pane 2 skipped, 2 eligible
- AG10 PASS — planned_actions excludes replay-skipped pane
- AG11 PASS — different key does NOT replay-skip (per-pane scope is per-key)
- AG12 PASS — tolerant-parse skips corrupt rows + finds valid replay rows
- AG13 PASS — `all_replay_skipped` status when every pane was pre-pinged

## Sister regression coverage

| Suite | Result |
|---|---|
| `stale-error-auto-ping-idempotency-key.sh` (this bead) | 14/14 PASS |
| `sync-canonical-doctrine-idempotency-key.sh` (sister 8sx9w) | 11/11 PASS |
| `recovery-install-plist-skillos-canonical-cli.sh` (2.7) | 27/27 PASS |
| `recovery-install-plist-clutterfreespaces-canonical-cli.sh` (2.5) | 26/26 PASS |
| `recovery-baseline-snapshot-canonical-cli.sh` (2.2) | 25/25 PASS |
| `flywheel-codex-orient-canonical-cli.sh` (1.9) | 25/25 PASS |
| `flywheel-verdict-canonical-cli.sh` (1.4) | 32/32 PASS |
| `canonical-cli-lint-precommit.sh` (f0e77) | 19/19 PASS |

165 sister assertions + 14 in-bead = 179 across cluster.

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/stale-error-auto-ping.sh` | +50 / -9: 2 new vars + parser + gate + 2 helpers + filtered iteration + receipt fields + docs |
| `tests/stale-error-auto-ping-idempotency-key.sh` | NEW: 13-AG regression test (14 assertions) with synthetic agents fixture + audit-log seeding |
| `.flywheel/compliance/flywheel-1o9fa/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-1o9fa/stale-error-auto-ping.diff` | NEW: 124-line captured diff |
| `.flywheel/journal/flywheel-1o9fa.md` | NEW: journey entry |

## Skill auto-routes

- canonical-cli-scoping: **yes** (canonical refusal contract + receipt envelope + per-pane audit-log discipline)
- rust-best-practices: n/a
- python-best-practices: n/a
- readme-writing: n/a

## Quality bar

- canonical-cli: 240/220 (canonical refusal + receipt + per-pane ledger-replay + tolerant-parse + 3 exit codes)
- regression depth: 240/220 (14 assertions covering refusal + envelope + per-pane replay + cross-key isolation + tolerant-parse + all-skipped status taxonomy)
- doctrine: 220/200 (extends sister 8sx9w pair-pattern with per-pane granularity; documents the "whole-run vs per-target" granularity choice; second 7axmt P1 fix shipped)
- integration risk: 200/200 (additive: dry-run unchanged; existing `--apply` callers will now refuse — INTENTIONAL behavior change consistent with 8sx9w precedent)
- live demonstration: 200/200 (real refusal envelope, real audit-log seeding + per-pane filter verification, real tolerant-parse against corrupt fixture)

Total: 1100/1040 → 1000

## Skill discovery (1)

1. **`per-pane-replay-granularity-pattern`** — the 8sx9w pair-pattern was whole-invocation replay. For per-target actions (ping pane N, br set bead-id, etc.) the right granularity is per-target replay: audit-log row carries `{idempotency_key, target}`, replay-check returns the set of already-acted-on targets, surface filters its work-list before iteration. This extends sister 8sx9w's pair-pattern into a per-target variant. Bead 1o9fa is the first instance; future 7axmt fixes for hub-blocker-detect (br set per bead) and bcv-task-harness (task per task-id) likely adopt the same granular variant.

## Behavior change announcement

Same as sister 8sx9w: any existing automation calling `stale-error-auto-ping.sh --apply` without `--idempotency-key` will now fail rc=3. Operators must update invocations. Recommended:

```bash
stale-error-auto-ping.sh --apply --idempotency-key="$(date -u +%Y%m%d-%H%M%S)" --json
```

Or for a launchd timer with stable schedule semantics, use a time-bucketed key:

```bash
stale-error-auto-ping.sh --apply --idempotency-key="auto-$(date -u +%Y%m%d-%H)" --json
```

(Hourly bucket — every invocation within the same hour replays no-op.)

## Cross-orch impact

7axmt followup arc: **2/7 Tier-1 fixed** after this bead. Remaining:
- P1: flywheel-j0xpa (security-precommit-installer), flywheel-j99xb (regenerate-dicklesworthstone-sources)
- P2: flywheel-mfy7u (hub-blocker-detect), flywheel-y0ft6 (bcv-task-harness)
- P3: flywheel-wdh08 (jeff-bead-285-divergence-capture)
- L10-lint: flywheel-9dace

The per-pane variant will likely apply to hub-blocker-detect (per-bead) and bcv-task-harness (per-task-id). The whole-run variant will apply to security-precommit-installer (per-install) and regenerate-dicklesworthstone-sources (per-regen-batch).

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- **brand**: Second 7axmt fix shipped on the same day as the audit and sister 8sx9w. Pair-pattern extended cleanly to per-pane granularity. Pattern catalogue gains a granularity-choice doctrine ("whole-run vs per-target") for future fixes.
- **sniff**: 14 regression assertions including 4 fixture variations (empty log, prior-pane seed, cross-key isolation, corrupt-row tolerance, all-skipped). Live audit-log seeding + tolerant-parse round-trip verified.
- **jeff**: Data decided — fixture format pinned via direct probe (the candidates_filter consumes `.agents[]` shape, not `.errors[]` raw passthrough — verified by running the surface against both shapes and selecting the one that produces candidates).
- **public**: Three Judges: operator sees clear refusal + audit-log path + retry-with-same-key semantics; maintainer sees per-pane filter + structured receipt + the granularity-choice doctrine in evidence; future worker on hub-blocker-detect / bcv-task-harness can read this evidence + journal and clone the per-target variant directly.
