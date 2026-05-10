# Journey entry — flywheel-j0xpa

**Bead**: P1 7axmt-followup (third of 7 Tier-1).
**Surface**: `.flywheel/scripts/security-precommit-installer.sh` — installs `githooks/pre-commit` dispatcher via `git config core.hooksPath` + timestamped backup.
**Sisters**: 8sx9w (whole-run global), 1o9fa (per-target). This bead establishes the **whole-run scoped per-repo** variant.
**Result**: 15/15 in-bead + 154 sister assertions clean; 1000/1000.

## Arc

1. **Read sister 8sx9w + 1o9fa**. Two pair-pattern variants in catalogue. Which fits this surface?
2. **Fix-spec said "git commit + push"** — wrong. Inspected the install_hook function: the mutation is `mkdir -p + chmod + cp $current $backup_path-$(date) + git config --local`. The non-idempotency is **timestamped-backup accumulation** — each apply creates a new backup, overwrites the chain config to point at the latest, orphans the older ones.
3. **Variant decision**: surface operates on ONE repo per invocation, gets called across MANY repos. Right scope: per-repo whole-run replay. Audit row carries `{idempotency_key, repo, ...}`, replay-check filters by both.
4. **Module vars** + argparse parser (mirror sister 1o9fa shape, both `--idempotency-key VALUE` and `--idempotency-key=VALUE` forms, explicit rc=2 on missing value).
5. **Refusal gate** inside `install_hook` AFTER the dry-run early-return (so dry-run doesn't require a key) and BEFORE any side-effect.
6. **`replay_prior_install()` + `audit_append_install()`** helpers — tolerant-parse via `jq -Rc 'fromjson?'` per sister 8sx9w discovery.
7. **Receipt envelope** carries `idempotency_key` in both dry-run and apply paths; replay path emits `{status:"replay", replay:true, replay_for_idempotency_key}`.
8. **Documentation**: usage, schema cli-schema, examples, quickstart, --info, completion — all updated.
9. **Live verification** with 2-repo fixture (a fresh `git init` repo + pre-committed `githooks/pre-commit`):
   - Without key → rc=3 ✓
   - With key, fresh repo → applies, audit row written ✓
   - Same key, same repo → replay (no-op exit 0) ✓
   - Same key, different repo → applies (per-repo scope works) ✓
   - Fresh key, same repo → applies (no replay) ✓
10. **AG12 failure surfaced pre-existing bug**: `--help` exits 2 because the bottom case dispatch was missing `-h|--help)`. Pre-existing bug in the surface, not caused by my edits. Added the case → AG12 passes.
11. **Tolerant-parse test**: seeded the audit log with a corrupt row, verified replay still fires correctly.

## Discoveries (2)

1. **`per-repo-scoped-whole-run-replay-pattern`** — third pair-pattern variant. For surfaces that operate on one target per invocation but get called across many targets, the right replay scope is `(idempotency_key, target-identifier)` not just `idempotency_key`. The audit row needs the scope identifier; the replay-check filters by both. Matrix now has 3 variants: whole-run-global (8sx9w), per-target-within-run (1o9fa), whole-run-scoped-per-target (this bead).

2. **`fix-spec-correction-via-evidence`** — when an audit's fix-spec misidentifies the mutation kind (here: "git commit + push" was actually timestamped-backup accumulation), the right place to record the correction is the implementing bead's EVIDENCE doc, not retroactive amendment of the audit's fix-spec.md. The audit captures a snapshot at audit-time; evidence captures truth-as-implemented. Future operators see both.

## 7axmt arc status

After this bead: **3/7 Tier-1 fixed**. Pair-pattern matrix complete enough to match remaining surfaces:

| Variant | Audit-row scope | Replay-check | Sister | Remaining candidates |
|---|---|---|---|---|
| Whole-run global | `{key, status:ok}` | Exit 0 if any row matches | 8sx9w | (none clear) |
| Per-target | `{key, target}` per ping/action | Filter work-list | 1o9fa | flywheel-mfy7u (hub-blocker-detect, per-bead), flywheel-y0ft6 (bcv-task-harness, per-task-id) |
| Whole-run scoped per-target | `{key, scope-id, status:applied}` | Exit 0 if (key, scope-id) matches | **j0xpa (this)** | flywheel-j99xb (regenerate-dicklesworthstone-sources, per-source-repo), flywheel-wdh08 (jeff-bead-285-divergence-capture, per-divergence-id) |

## Pre-existing bug discovered + fixed

`--help` and `-h` were not handled by the bottom case dispatch — the script's argparse expected `--help` AFTER a command, but `--help` alone (like `security-precommit-installer.sh --help`) was treated as an unknown command (exit 2). Added `-h|--help) usage ;;` case. Bonus fix.

## Behavior change

Callers must pass `--idempotency-key=VALUE` under `install --apply`. Recommended HEAD-sha-based key:

```bash
security-precommit-installer.sh install --apply --idempotency-key="install-v1-$(git -C $REPO rev-parse HEAD)" --repo "$REPO" --json
```

Same HEAD-sha replays no-op for the same repo. Different repos or different commits proceed.
