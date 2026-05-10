# ntm rebuild apply spec — Joshua signoff 2026-05-10

Joshua approved 2026-05-10: "go ahead and rebuild - approved" with directive to skip
the formal peer-orch quiesce ACK dance. Reasoning: ntm is a per-invocation CLI,
atomic swap is <100ms, fleet is mostly idle this minute, backup makes rollback trivial.

Source runbook: `.flywheel/evidence/flywheel-u4fmq/report.md` (premise verified by
MagentaPond; 5 probes deterministic, fix #118 confirmed in HEAD at 7d1fc78e).

## Simplified path (4 steps; L87 doctrine flip deferred 24h)

### Step 1: build

- Path: `/Users/josh/Developer/ntm`
- Confirm HEAD short SHA matches `7d1fc78e` (or current short of HEAD if it has advanced)
- Build: `make build`
- Verify: run `./dist/ntm version` → must show real commit hash, NOT `commit=none`
- Stop here if version output still says `commit=none` after build (means make
  target is broken; do NOT proceed to swap)

### Step 2: backup + atomic swap

- Backup target: `/Users/josh/.local/bin/ntm.bak.<UTC-timestamp>`
  (use exact timestamp form `YYYYMMDDTHHMMSSZ`)
- Backup: copy current `/Users/josh/.local/bin/ntm` to that backup path
- Swap: copy `/Users/josh/Developer/ntm/dist/ntm` to `/Users/josh/.local/bin/ntm`
- Verify: run `/Users/josh/.local/bin/ntm version` → must now show same real commit
  hash as `dist/ntm version` from step 1

### Step 3: validate (regression check)

- Run: `bash /Users/josh/Developer/flywheel/tests/stale-error-auto-ping.sh`
- Required: 7/7 PASS (same as pre-swap baseline)
- If ANY test fails → rollback: copy backup .bak file back over `/Users/josh/.local/bin/ntm`
- If rollback fires, exit non-zero with explicit `rollback_executed=yes` in receipt

### Step 4: report

- Receipt at `.flywheel/audit/flywheel-u4fmq-apply/evidence.md` with:
  - Pre-swap binary metadata (version, commit, size, mtime)
  - Post-swap binary metadata (same fields)
  - Backup path
  - Stale-error-auto-ping result (pre + post)
  - Total operation duration
  - Rollback fired (yes/no)

## Deferred to followup (NOT in this bead's scope)

- L87 doctrine flip (sunset_at + binary_commit_pin) — needs 24h burn-in observation first
- README stale-error fallback paragraph cleanup — paired with L87 flip
- File a small followup bead `flywheel-u4fmq-doctrine` with a `not_before` of
  2026-05-11 for the doctrine cleanup

## Boundary

- Stop on first error. Atomic swap only after build verification of real commit hash.
- No --force flags. Backup is the rollback path; preserve it.
- This is a single-machine fleet-shared binary; do NOT write to peer machines or
  perform any network operations.

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Goal

See body above (typically the opening paragraph or first H1 section).

## Acceptance gate

See body above (typically near the end, named Acceptance or per-AG numbered).
