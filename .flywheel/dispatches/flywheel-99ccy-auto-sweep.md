# flywheel-99ccy — auto-push.sh implement auto_sweep_on_dirty_tree

## Context

Policy `.flywheel/auto-push-policy.yaml` gained `auto_sweep_on_dirty_tree: true` field today 2026-05-20T02:15Z. Allow-list expanded 2 → 16 globs. Doctrine `.flywheel/doctrine/auto-push-blocked-worker-discipline.md` describes the recovery protocol. But the auto-push.sh script DOESN'T actually act on the flag — workers must still manually sweep.

This is the second half of killing the auto-push-blocked-worker-abandonment trauma class (paired with the doctrine + policy expansion shipped earlier).

## Deliverables

### A. Edit .flywheel/scripts/auto-push.sh
When status=blocked + reason=dirty_tree + `auto_sweep_on_dirty_tree=true` in policy:
1. Compute `swept_paths` = dirty paths that match `known_dirty_paths_allow_list` globs
2. Compute `non_swept_paths` = dirty paths NOT in allow-list
3. If `non_swept_paths` is non-empty: keep blocked with NEW reason `non_allowlist_dirty` + list those paths. DO NOT auto-sweep.
4. If only `swept_paths` (all dirty are allow-listed):
   - `git add <swept_paths>` (explicit, not -A)
   - `git commit -m "${policy.auto_sweep_commit_message:-chore(state): auto-sweep accreting substrate paths [auto-push]}"`
   - Retry the push (same call chain — Tier 4 act-CI gate, Tier 4.5 GitGuardian, Tier 4.5.1 Supabase mirror, then push)
5. Emit envelope with `auto_swept: true`, `swept_paths: [...]`, `sweep_commit_sha: "..."`, plus original outcome fields

### B. Smoke fixture extension
`tests/auto-push-v0.1-adoption.sh` or new `tests/auto-push-auto-sweep-smoke.sh`:
1. Synthetic dirty tree with ALL allow-listed paths → auto-sweep + push succeeds + envelope has auto_swept=true
2. Synthetic dirty tree with one non-allow-listed path → status=blocked reason=non_allowlist_dirty (not original dirty_tree)
3. Mixed dirty: allow-listed + non-allow-listed → status=blocked, non_swept_paths populated correctly
4. auto_sweep_on_dirty_tree=false in policy → original blocked behavior preserved (back-compat)
5. Sweep commit message matches policy override OR canonical default
6. Sweep doesn't run when allow-list is empty (edge case)

### C. Backward compat
- Existing policy with auto_sweep_on_dirty_tree=false OR missing → original behavior (current production semantics)
- Workers/orchs still see status=blocked envelopes when sweep can't fully resolve
- No silent commits — every sweep emits a commit with the canonical message visible in git log

### D. Doctrine cross-link
Update `.flywheel/doctrine/auto-push-blocked-worker-discipline.md` "How to apply" section: when auto_sweep_on_dirty_tree=true is set in policy, workers DON'T need to manually sweep — the script handles it. The doctrine still applies for cases where sweep can't resolve (non-allow-listed paths).

## Acceptance

- auto-push.sh implements auto-sweep when flag set
- New trauma class `non_allowlist_dirty` emitted (distinct from old `dirty_tree`)
- Smoke 6+ assertions covering all branches PASS
- shellcheck PASS
- Live dry-run of auto-push on flywheel (with current accreting state files) shows it WOULD auto-sweep cleanly
- Doctrine doc updated
- Bead flywheel-99ccy closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits to auto-push.sh + smoke
- socraticode K>=10 with 2 phrasings on existing auto-push.sh structure + glob-matching in bash + policy YAML parsing
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (worker-abandonment class)
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + live dry-run

## FIRST ACTION

1. br show flywheel-99ccy.
2. Read .flywheel/scripts/auto-push.sh end-to-end.
3. Read .flywheel/auto-push-policy.yaml (current allow-list).
4. Read .flywheel/doctrine/auto-push-blocked-worker-discipline.md.
5. ACK row.
6. Implement auto-sweep branch.
7. Self-validate.
8. Commit + close bead + DIRECT pane-1 ntm send.
